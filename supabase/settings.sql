-- settings.sql – one-time setup for the team-editable limits.
--
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Then set the team PIN with the separate statement in readme.md
-- (the PIN itself must never be written into this repository).
--
-- Creates:
--   settings    one row (id = 1) with the two limits
--                 weekly_limit  numbers above this are still issued, but with a
--                               warning ("Your number can not be considered ...")
--                 absolute_max  no numbers at all are issued above this
--   admin_pin   one row with the hashed team PIN and the lockout counter;
--               not readable through the API
--   set_limits  function called by admin.html; checks the PIN, then saves
--
-- Access:
--   everyone (public key used by the pages) may READ settings
--   nobody may change settings directly; only via set_limits with the right PIN
--   after 5 wrong PINs, set_limits refuses for 15 minutes

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------- settings

create table if not exists public.settings (
  id            integer primary key default 1 check (id = 1),
  weekly_limit  integer not null default 200 check (weekly_limit >= 0),
  absolute_max  integer not null default 200 check (absolute_max >= 1),
  updated_at    timestamptz not null default now(),
  check (weekly_limit <= absolute_max)
);

insert into public.settings (id) values (1)
  on conflict (id) do nothing;

alter table public.settings enable row level security;

drop policy if exists "settings readable by everyone" on public.settings;
create policy "settings readable by everyone"
  on public.settings for select
  to anon, authenticated
  using (true);

revoke all on public.settings from anon, authenticated;
grant select on public.settings to anon, authenticated;

-- ---------------------------------------------------------------- admin_pin

create table if not exists public.admin_pin (
  id               integer primary key default 1 check (id = 1),
  pin_hash         text not null,
  failed_attempts  integer not null default 0,
  locked_until     timestamptz
);

-- Row level security without any policy: no access at all through the API
alter table public.admin_pin enable row level security;
revoke all on public.admin_pin from anon, authenticated;

-- ---------------------------------------------------------------- set_limits

-- Returns one of:
--   'ok'         limits saved
--   'wrong_pin'  PIN wrong (counts towards the lockout)
--   'locked'     too many wrong PINs; try again later
--   'invalid'    limits not whole numbers >= 0/1, or weekly limit > absolute max
--   'no_pin'     no PIN set yet (see readme.md)
create or replace function public.set_limits(
  p_pin           text,
  p_weekly_limit  integer,
  p_absolute_max  integer
) returns text
language plpgsql
security definer          -- runs with the owner's rights, so it can read admin_pin
set search_path = ''
as $$
declare
  r public.admin_pin%rowtype;
begin
  select * into r from public.admin_pin where id = 1 for update;
  if not found then
    return 'no_pin';
  end if;

  if r.locked_until is not null and r.locked_until > now() then
    return 'locked';
  end if;

  if p_pin is null or extensions.crypt(p_pin, r.pin_hash) <> r.pin_hash then
    -- 5th wrong attempt (and every further one) locks for 15 minutes
    update public.admin_pin
       set failed_attempts = failed_attempts + 1,
           locked_until = case when failed_attempts + 1 >= 5
                               then now() + interval '15 minutes'
                               else null end
     where id = 1;
    return 'wrong_pin';
  end if;

  update public.admin_pin
     set failed_attempts = 0, locked_until = null
   where id = 1;

  if p_weekly_limit is null or p_absolute_max is null
     or p_weekly_limit < 0 or p_absolute_max < 1
     or p_weekly_limit > p_absolute_max then
    return 'invalid';
  end if;

  update public.settings
     set weekly_limit = p_weekly_limit,
         absolute_max = p_absolute_max,
         updated_at   = now()
   where id = 1;
  return 'ok';
end;
$$;

revoke execute on function public.set_limits(text, integer, integer) from public;
grant execute on function public.set_limits(text, integer, integer) to anon, authenticated;
