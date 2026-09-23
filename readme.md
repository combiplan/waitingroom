# Waiting Room L8

Web app that hands out waiting numbers for the card exchange.
Numbers are only issued on Thursdays from 12:00, at most 200 per day.

Hosted on GitHub Pages from the `main` branch:
https://combiplan.github.io/waitingroom/
A push to `main` is live after about a minute.

## Pages

| Page | URL | Purpose |
|------|-----|---------|
| `index.html` | https://combiplan.github.io/waitingroom/ | Visitors draw a waiting number (one per device per day). |
| `enter.html` | https://combiplan.github.io/waitingroom/enter.html | Shows the visitor's own number drawn today (German). |
| `monitor.html` | https://combiplan.github.io/waitingroom/monitor.html | Display for the monitor in the room: numbers issued today and the last number drawn with its time. Refreshes every 5 seconds; read-only. |

### monitor.html

Open it in a browser on the room's monitor and switch to full screen
(F11 on Windows/Linux, Ctrl+Cmd+F on macOS).

Outside Thursday 12:00 onwards it shows a notice instead of the figures.

For testing on other days, append `?date=YYYY-MM-DD` to the URL. The page then
shows that day's figures and skips the Thursday check, e.g.
`monitor.html?date=2026-09-17`.

## Data

All pages use the Supabase table `queue`
(project `anjuypoheypwalafesgl`) with the columns
`number`, `date` (UTC date, `YYYY-MM-DD`), `created_at`, `device_id`.
The pages access it with the public (anon) key embedded in the HTML.

## Branches

- `main` – live version.
- `Stabalize` – open pull request #1, diverged from `main`.
- `cursor/restrict-waiting-number-retrieval-to-thursdays-after-12-2039` – older feature branch.
