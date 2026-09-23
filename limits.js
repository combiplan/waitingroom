// limits.js – shared by index.html, enter.html and monitor.html.
//
// Reads the team-editable limits from the Supabase table "settings"
// (see supabase/settings.sql; edited by the team in admin.html).
//
//   weeklyLimit  numbers above this are still issued, but with a warning
//   absoluteMax  no numbers at all are issued above this
//
// If the table cannot be read (not set up yet, network problem), the
// defaults below are used so that handing out numbers never stops.

const DEFAULT_LIMITS = { weeklyLimit: 200, absoluteMax: 200 };

// Returns { weeklyLimit, absoluteMax, ok }. ok = false means defaults were used.
async function loadLimits(client) {
  try {
    const { data, error } = await client
      .from('settings')
      .select('weekly_limit, absolute_max')
      .eq('id', 1)
      .limit(1);
    if (error || !data || data.length === 0) {
      return { ...DEFAULT_LIMITS, ok: false };
    }
    return {
      weeklyLimit: data[0].weekly_limit,
      absoluteMax: data[0].absolute_max,
      ok: true
    };
  } catch (e) {
    return { ...DEFAULT_LIMITS, ok: false };
  }
}

// Announcement shown before distribution starts (outside Thursday 12:00+).
// Returns null when the team has not set a weekly limit below the absolute
// maximum, i.e. there is nothing to announce.
function limitAnnouncementText(limits) {
  if (limits.weeklyLimit >= limits.absoluteMax) {
    return null;
  }
  return "This week we change for " + limits.weeklyLimit + " persons.";
}

// Warning shown to people whose number is above the weekly limit.
function limitWarningText(weeklyLimit) {
  return "Your number can not be considered. This week we change only for "
    + weeklyLimit + " persons. Please do not travel to L8.";
}
