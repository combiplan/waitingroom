# Waiting Room L8

Web app that hands out waiting numbers for the card exchange.
Numbers are only issued on Thursdays from 12:00. The team sets two limits
in `admin.html`:

- **Weekly limit** – numbers above it are still issued, but the visitor sees a
  blinking warning: "Your number can not be considered. This week we change
  for N persons (adults). Please do not travel to L8."
- **Absolute maximum** – no numbers at all are issued above it.

Before distribution starts (outside Thursday 12:00+), `index.html` and
`monitor.html` announce "This week we can only change for N persons (adults)." – but only
if the weekly limit is lower than the absolute maximum.

If the limits cannot be read, both default to 200 (`limits.js`).

Hosted on GitHub Pages from the `main` branch:
https://combiplan.github.io/waitingroom/
A push to `main` is live after about a minute.

## Pages

| Page | URL | Purpose |
|------|-----|---------|
| `index.html` | https://combiplan.github.io/waitingroom/ | Visitors draw a waiting number (one per device per day). Shows the limit warning when the number is above the weekly limit. |
| `enter.html` | https://combiplan.github.io/waitingroom/enter.html | Shows the visitor's own number drawn today (German), with the limit warning if applicable. |
| `monitor.html` | https://combiplan.github.io/waitingroom/monitor.html | Display for the monitor in the room: weekly limit, numbers issued today and the last number drawn with its time. Refreshes every 5 seconds; read-only. |
| `admin.html` | https://combiplan.github.io/waitingroom/admin.html | Team page: set the weekly limit and the absolute maximum (requires the team PIN). |

Shared code: `limits.js` reads the limits and holds the warning text.

### monitor.html

Open it in a browser on the room's monitor and switch to full screen
(F11 on Windows/Linux, Ctrl+Cmd+F on macOS).

Outside Thursday 12:00 onwards it shows a notice instead of the figures.

For testing on other days, append `?date=YYYY-MM-DD` to the URL. The page then
shows that day's figures and skips the Thursday check, e.g.
`monitor.html?date=2026-09-17`.

### admin.html – one-time setup (in the Supabase dashboard)

1. **Create tables and function:** SQL Editor -> New query -> paste the
   contents of `supabase/settings.sql` -> Run. Both limits start at 200.
2. **Set the team PIN:** SQL Editor -> New query -> paste the statement below,
   replace `123456` with the real PIN -> Run. Do not save the query with the
   real PIN, and never write the PIN into this repository.

   ```sql
   insert into public.admin_pin (id, pin_hash)
   values (1, extensions.crypt('123456', extensions.gen_salt('bf')))
   on conflict (id) do update
     set pin_hash = excluded.pin_hash, failed_attempts = 0, locked_until = null;
   ```

   To **change the PIN** (e.g. when someone leaves the team), run the same
   statement with the new PIN. It also lifts a lockout.

Saving in `admin.html` needs the PIN. After 5 wrong PINs, saving is blocked
for 15 minutes. The PIN is stored in Supabase only as a hash.

## Data

All pages use the Supabase table `queue`
(project `anjuypoheypwalafesgl`) with the columns
`number`, `date` (UTC date, `YYYY-MM-DD`), `created_at`, `device_id`.
The pages access it with the public (anon) key embedded in the HTML.

Limits are in the table `settings` (one row, `id = 1`) with the columns
`weekly_limit`, `absolute_max`, `updated_at`. Everyone may read it; it can
only be changed through the database function `set_limits`, which checks the
team PIN (table `admin_pin`, not readable through the API).
See `supabase/settings.sql`.

## Branches

- `main` – live version.
- `Stabalize` – open pull request #1, diverged from `main`.
- `cursor/restrict-waiting-number-retrieval-to-thursdays-after-12-2039` – older feature branch.
