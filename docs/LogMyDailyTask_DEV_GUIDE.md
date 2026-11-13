# LogMyDailyTask — Developer Guide (Coding Phase)

Version 0.1 · 2026-11-13 · Companion to `LogMyDailyTask_PRD_en.md` / `LogMyDailyTask_PRD_ko.md`

This guide turns the PRD into something you can build from. Put it in the repo root as `CLAUDE.md` (or `docs/DEV_GUIDE.md`) so coding agents and people read the same rules. Requirement IDs (FR-x.y) refer to the PRD.

---

## 0. Ground rules (read first)

1. **No server, no account.** Nothing in phase 1 may call a backend we own. The only network calls are Microsoft Graph, Google Calendar API, Google Sheets API (user's own sheet, opt-in), an ICS URL, and OAuth endpoints.
2. **Local-first.** Every write goes to the local SQLite DB first. UI reads from the DB (reactive streams), never from in-memory caches that can drift.
3. **Store UTC, display local.** All timestamps are stored as UTC epoch milliseconds plus `tz_name` (IANA, e.g. `America/Denver`) on each Entry.
4. **Never store derived values.** Duration, amount, weekly totals and merged cells are computed at read time.
5. **Soft delete for user actions, hard delete for retention purge.** User "delete" sets `deleted_at`; the retention job (FR-5.10–5.13) removes rows permanently and runs `VACUUM`.
6. **One schema everywhere.** Desktop, mobile and web use the same drift schema and migrations.
7. **Two languages.** Every user-visible string goes through l10n (`ko`, `en`). No hard-coded UI text.
8. **Verify package versions at setup.** Package names below are the plan; pin current stable versions when you create the project and record them in `pubspec.lock`.

---

## 1. Tech stack

| Concern | Choice | Notes |
| --- | --- | --- |
| Framework | Flutter (stable channel), Dart 3 | Targets: windows, macos, ios, android, web |
| State management | `flutter_riverpod` | Providers wrap repositories; UI watches streams |
| Routing | `go_router` | Separate routes for popup window vs main window on desktop |
| Local DB | `drift` + `drift_flutter` | SQLite; reactive queries |
| DB encryption | `sqlcipher_flutter_libs` (desktop + mobile) | Key generated on first run, stored in secure storage |
| Web DB | drift WASM (`sqlite3.wasm` + drift worker) | OPFS where available, IndexedDB fallback |
| Secure storage | `flutter_secure_storage` | Keychain / Credential Manager / Keystore; web: session only |
| Local notifications | `flutter_local_notifications` | iOS, Android, macOS; actions + text input |
| Desktop notifications | `local_notifier` (Windows) | Plus custom popup window (below) |
| Desktop window | `window_manager` | Small always-on-top check-in window |
| Tray / menu bar | `tray_manager` | Tray (Windows), menu bar (macOS) |
| Global hotkey | `hotkey_manager` | FR-1.12 |
| Launch at login | `launch_at_startup` | Windows / macOS |
| OAuth (mobile) | `flutter_appauth` | PKCE, system browser |
| OAuth (desktop) | Loopback redirect (`http://127.0.0.1:<port>`) + `url_launcher` | PKCE |
| OAuth (web) | Redirect flow with PKCE | Tokens kept in memory/session only |
| HTTP | `http` or `dio` | Pick one, wrap in `CalendarHttpClient` |
| ICS parsing | `icalendar_parser` or a small in-house parser | Only VEVENT, DTSTART/DTEND, SUMMARY, STATUS |
| Time zones | `timezone` + `flutter_timezone` | IANA names |
| Export | `excel` (xlsx), `csv`, `pdf` (phase 2) | Generated on device |
| Files | `file_picker`, `share_plus` | Backup export/import; mobile CSV share sheet (FR-6.11) |
| Google Sheets | `googleapis` (Sheets v4) + `google_sign_in` (mobile/web) / loopback OAuth (desktop) | Scope `https://www.googleapis.com/auth/drive.file` only |
| Device info | `device_info_plus` | Default device name and platform (FR-6.6) |
| l10n | `flutter_localizations` + ARB files | `lib/l10n/app_ko.arb`, `app_en.arb` |
| Tests | `flutter_test`, `mocktail`, `clock` | Fake clock for scheduler tests |

Web hosting: static files on Cloudflare Pages. Add a `_headers` file with `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` so the drift WASM build can use its fastest OPFS mode; it falls back automatically if not available.

---

## 2. Repository layout

```
logmydailytask/
├─ CLAUDE.md                     # this guide (or link to docs/DEV_GUIDE.md)
├─ docs/
│  ├─ PRD_en.md
│  ├─ PRD_ko.md
│  └─ design/                    # screenshots / exports from the design canvas
├─ lib/
│  ├─ main.dart                  # bootstraps DB, settings, scheduler, platform shell
│  ├─ app/                       # router, theme, l10n setup
│  ├─ core/
│  │  ├─ clock.dart              # injectable clock (never call DateTime.now() directly)
│  │  ├─ time_slots.dart         # slot math (pure functions)
│  │  └─ result.dart
│  ├─ data/
│  │  ├─ db/
│  │  │  ├─ database.dart        # drift database + migrations
│  │  │  ├─ tables.dart          # table definitions
│  │  │  └─ connection/          # native.dart, web.dart (conditional imports)
│  │  └─ repositories/           # entries, activities, categories, projects, settings, filters, calendar
│  ├─ domain/
│  │  ├─ scheduler/              # check-in scheduler (FR-1)
│  │  ├─ weekly/                 # weekly grid builder + totals (FR-4)
│  │  ├─ retention/              # purge job (FR-5.10–5.13)
│  │  ├─ backup/                 # export/import + merge (FR-5.4, 5.13)
│  │  └─ export/                 # xlsx/csv (FR-4.7), mobile CSV share (FR-6.11)
│  ├─ integrations/
│  │  ├─ calendar/
│  │  │  ├─ calendar_provider.dart   # interface
│  │  │  ├─ graph_provider.dart      # Outlook / Microsoft 365
│  │  │  ├─ google_provider.dart
│  │  │  ├─ ics_provider.dart
│  │  │  └─ admin_consent.dart       # FR-3 admin-consent help flow
│  │  ├─ sheets/                 # Google Sheets sync (FR-6): auth check, upsert queue, pull
│  │  └─ notifications/          # platform notification adapters
│  ├─ platform/
│  │  ├─ desktop/                # tray, popup window, hotkey, idle detection
│  │  ├─ mobile/                 # notification actions, background rescheduling
│  │  └─ web/                    # Notification API, PWA install, storage warnings
│  ├─ features/                  # UI by screen
│  │  ├─ checkin_popup/
│  │  ├─ weekly/
│  │  ├─ day_view/               # mobile
│  │  ├─ log_list/               # list view + filters
│  │  ├─ projects/
│  │  ├─ categories/
│  │  ├─ settings/
│  │  ├─ calendar_connect/
│  │  ├─ data_cleanup/
│  │  └─ onboarding/
│  └─ l10n/
├─ test/                         # unit + widget tests mirroring lib/
├─ integration_test/
└─ web/_headers
```

Rule: `domain/` and `core/` are pure Dart (no Flutter imports) so they are fast to unit test.

---

## 3. Database schema (SQLite, via drift)

All tables have `id TEXT PRIMARY KEY` (UUID v7, sortable), `created_at INTEGER`, `updated_at INTEGER`, `deleted_at INTEGER NULL` (epoch ms, UTC). Shown here as SQL for clarity; implement as drift tables in `tables.dart`.

```sql
CREATE TABLE profile (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  timezone TEXT NOT NULL,              -- IANA
  locale TEXT NOT NULL DEFAULT 'ko',   -- 'ko' | 'en'
  device_id TEXT NOT NULL,             -- UUID created on first run
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE settings (
  id TEXT PRIMARY KEY,                 -- single row 'default'
  interval_min INTEGER NOT NULL DEFAULT 30,        -- 15|30|60 or custom 5..120 step 5
  align_mode TEXT NOT NULL DEFAULT 'clock',        -- 'clock' | 'work_start'  (FR-1.4)
  work_days TEXT NOT NULL DEFAULT '1,2,3,4,5',     -- ISO weekdays
  work_start TEXT NOT NULL DEFAULT '09:00',        -- local HH:mm
  work_end TEXT NOT NULL DEFAULT '18:00',
  pause_during_meetings INTEGER NOT NULL DEFAULT 1,       -- FR-1.7
  checkin_in_long_meetings INTEGER NOT NULL DEFAULT 0,    -- FR-1.14
  long_meeting_min INTEGER NOT NULL DEFAULT 60,           -- FR-1.14
  idle_threshold_min INTEGER NOT NULL DEFAULT 10,         -- FR-1.10 (phase 2)
  notifications_enabled_on_device INTEGER NOT NULL DEFAULT 1, -- FR-1.9 (per device; not merged by backup)
  auto_purge_months INTEGER,                              -- NULL | 3 | 6  (FR-5.11)
  purged_before INTEGER,                                  -- epoch ms cutoff of last purge (FR-5.13)
  store_meeting_body INTEGER NOT NULL DEFAULT 0,          -- FR-3.8
  theme TEXT NOT NULL DEFAULT 'system',
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE category (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL,                 -- '#RRGGBB'
  sort_order INTEGER NOT NULL DEFAULT 0,
  archived INTEGER NOT NULL DEFAULT 0,
  is_meeting INTEGER NOT NULL DEFAULT 0,   -- the built-in "Meetings"/"회의" category
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE project (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  client TEXT,
  color TEXT,
  status TEXT NOT NULL DEFAULT 'active',   -- active | awaiting_feedback | completed
  hourly_rate_minor INTEGER,               -- rate in minor units (cents/won) per hour; NULL = none
  currency TEXT,                           -- ISO 4217, e.g. 'USD', 'KRW'
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE activity (
  id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL REFERENCES category(id),
  project_id TEXT REFERENCES project(id),
  title TEXT NOT NULL,                     -- max 200 chars (FR-2.1)
  title_norm TEXT NOT NULL,                -- lowercased/trimmed, for dedupe + autocomplete
  tags TEXT,                               -- comma-separated
  last_used_at INTEGER,
  use_count INTEGER NOT NULL DEFAULT 0,
  pinned INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE UNIQUE INDEX ux_activity_title ON activity(title_norm, category_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_activity_recent ON activity(last_used_at DESC);

CREATE TABLE entry (
  id TEXT PRIMARY KEY,
  activity_id TEXT REFERENCES activity(id),
  project_id TEXT REFERENCES project(id),  -- copied from activity at write time, editable
  calendar_event_id TEXT REFERENCES calendar_event(id),
  parent_entry_id TEXT REFERENCES entry(id),  -- check-in inside a long meeting (FR-1.14)
  start_at INTEGER NOT NULL,               -- UTC ms
  end_at INTEGER,                          -- UTC ms; NULL = running timer (FR-1.13)
  tz_name TEXT NOT NULL,
  note TEXT,
  source TEXT NOT NULL,                    -- checkin | manual | calendar | timer
  status TEXT NOT NULL DEFAULT 'logged',   -- logged | missed | break
  device_id TEXT NOT NULL REFERENCES device(id),
  sheet_sync_state TEXT NOT NULL DEFAULT 'none',  -- none | pending | synced | failed  (FR-6.7)
  sheet_synced_at INTEGER,
  sheet_error TEXT,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE INDEX ix_entry_start ON entry(start_at);
CREATE INDEX ix_entry_sheet_pending ON entry(sheet_sync_state) WHERE sheet_sync_state IN ('pending','failed');
CREATE INDEX ix_entry_parent ON entry(parent_entry_id);
-- Only one running timer at a time (FR-1.13):
CREATE UNIQUE INDEX ux_entry_running ON entry(source) WHERE end_at IS NULL AND source = 'timer' AND deleted_at IS NULL;

CREATE TABLE saved_filter (                -- phase 2 (FR-4.13); create table in v1 to avoid a migration
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  kind TEXT NOT NULL,                      -- fixed | relative
  date_from INTEGER, date_to INTEGER,      -- fixed
  amount INTEGER, unit TEXT,               -- relative: unit = day|week|month|year
  category_id TEXT, project_id TEXT, source TEXT,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE device (                    -- FR-6.6
  id TEXT PRIMARY KEY,                     -- same value as profile.device_id for this device
  name TEXT NOT NULL,                      -- user-editable, e.g. "John's MacBook"
  platform TEXT NOT NULL,                  -- windows | macos | ios | android | web
  is_this_device INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE sheet_connection (           -- FR-6.1 to 6.10; single row
  id TEXT PRIMARY KEY,
  account_email TEXT NOT NULL,
  spreadsheet_id TEXT NOT NULL,
  sheet_name TEXT NOT NULL DEFAULT 'Log',
  secure_storage_key TEXT NOT NULL,        -- token lives in secure storage, never here
  enabled INTEGER NOT NULL DEFAULT 1,
  import_others INTEGER NOT NULL DEFAULT 1,      -- FR-6.9
  delete_rows_on_purge INTEGER NOT NULL DEFAULT 0,  -- FR-6.10 option
  last_synced_at INTEGER,
  last_error TEXT,                         -- e.g. auth_expired | permission_revoked | sheet_missing
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE calendar_connection (
  id TEXT PRIMARY KEY,
  provider TEXT NOT NULL,                  -- outlook | google | ics
  account_email TEXT,
  ics_url TEXT,                            -- provider = ics only
  secure_storage_key TEXT,                 -- key name in flutter_secure_storage (token never in DB)
  sync_cursor TEXT,                        -- Graph deltaLink / Google syncToken
  filters TEXT NOT NULL,                   -- JSON: {acceptedOnly, includeTentative, excludeAllDay, excludePrivate}
  last_synced_at INTEGER,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);

CREATE TABLE calendar_event (
  id TEXT PRIMARY KEY,
  connection_id TEXT NOT NULL REFERENCES calendar_connection(id),
  external_id TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,                               -- only if settings.store_meeting_body = 1
  start_at INTEGER NOT NULL, end_at INTEGER NOT NULL,
  is_all_day INTEGER NOT NULL DEFAULT 0,
  attendee_count INTEGER,
  online_link_type TEXT,                   -- teams | meet | zoom | other | NULL
  location TEXT,
  response_status TEXT,                    -- accepted | tentative | declined | none | organizer
  is_cancelled INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE UNIQUE INDEX ux_cal_event ON calendar_event(connection_id, external_id);
CREATE INDEX ix_cal_event_start ON calendar_event(start_at);
```

Seed data on first run: this device's `device` row (name from `device_info_plus`, editable later), categories 개발/Development, 회의/Meetings (`is_meeting = 1`), 지원/Support, 문서/Docs, 행정/Admin; one `settings` row; one `profile` row.

Migrations: schema version starts at 1. Every change is a numbered drift migration with a test in `test/data/migrations_test.dart` that opens a v(n-1) DB and migrates it.

---

## 4. Core logic

### 4.1 Time slots (`core/time_slots.dart`, pure functions)

- `slotsForDay(date, settings, tz)` → list of `[start, end)` intervals inside working hours, length `interval_min`.
- Alignment (FR-1.4): `clock` = slot boundaries on multiples of the interval from local midnight (9:00, 9:30…); `work_start` = boundaries from `work_start`.
- Custom intervals (5–120) that do not divide 60 still align from midnight in `clock` mode.
- DST: compute in local time with the `timezone` package, convert to UTC; a slot crossing a DST shift keeps its local labels.

### 4.2 Check-in scheduler (`domain/scheduler/`) — FR-1.1 to FR-1.14

At each slot end `T`, decide what to do for slot `[T − interval, T)`:

```
if not within working hours/days → do nothing
if notifications disabled on this device → do nothing
if paused (until X) and T < X → do nothing
if a timer entry is running → do nothing (FR-1.13)
meeting = calendar event overlapping the slot (accepted, passes filters)
if meeting != null and settings.pause_during_meetings:
    ensure a calendar Entry exists for the meeting (source=calendar)
    long = meeting.duration >= settings.long_meeting_min
    if long and settings.checkin_in_long_meetings:
        show popup; save answer as Entry(parent_entry_id = meetingEntry.id)   (FR-1.14)
    else:
        do nothing                                                           (FR-1.7)
else:
    show popup for the slot
```

- Missed slots (FR-1.8): when a popup times out or is dismissed, write `Entry(status = 'missed', source = 'checkin')`. The next popup shows "Same as before for N missed slots?" which converts them to `logged` with the chosen activity.
- Snooze (FR-1.5): reschedule this slot's popup +5/+10 min; the answer still applies to the original slot.
- "On a break" → `status = 'break'`, no activity.
- Before showing any popup, refresh calendar changes if the last sync is older than 15 min (FR-3.7), so a just-added meeting suppresses the popup.
- Desktop: an in-process timer drives the scheduler. Mobile: precompute and schedule local notifications for the next 24–48 h; reschedule on app open, settings change, calendar sync, and boot. iOS allows only a limited number of pending local notifications (64), so schedule a rolling window. Web: an in-page timer; notify only while the tab/PWA is open.

### 4.3 Saving an answer (FR-2)

1. Normalize title → find or create `activity` (unique on `title_norm + category_id`).
2. Update `activity.last_used_at`, `use_count += 1`.
3. Insert `entry` for the slot; copy `project_id` from the activity.
4. Merge rule: do not merge rows in the DB. Consecutive identical activities are merged only in the weekly view (FR-4.2).

Pick list order in the popup (FR-2.3): "Same as last" button, then pinned, then 5 most recent, then grouped by category. Korean IME (FR-2.10): ignore Enter while `TextEditingValue.composing` is non-empty.

### 4.3.1 Autocomplete from the last 7 days (FR-2.2)

- **Source set:** when the popup/sheet opens, load once into memory the activities used in entries with `start_at >= now − 7 days` (status `logged`, not deleted), with `uses7d = COUNT(*)` and `lastUsed = MAX(start_at)`:

```sql
SELECT a.id, a.title, a.title_norm, a.category_id, a.project_id,
       COUNT(e.id) AS uses7d, MAX(e.start_at) AS last_used
FROM entry e JOIN activity a ON a.id = e.activity_id
WHERE e.start_at >= :since AND e.deleted_at IS NULL AND e.status = 'logged' AND a.deleted_at IS NULL
GROUP BY a.id;
```

  Also precompute `chosung` (Korean initial consonants, e.g. "사용자 매뉴얼" → "ㅅㅇㅈ ㅁㄴㅇ") per title. Include records pulled from other devices (FR-6.9).
- **Trigger:** on every text change starting with the first character, including while the Korean IME is composing (use the composing text too, so "ㅁ" already suggests). No debounce; filtering is in memory.
- **Ranking:** tier 1 prefix match on `title_norm` (or on any word start), tier 2 contains, tier 3 initial-consonant match when the query is all jamo consonants; within a tier sort by `uses7d` desc, then `last_used` desc. Show at most 6.
- **Display:** title with the matched part bold, category color dot + category, project (if any). Picking fills title, category and project. Keyboard: ↑/↓ move, Enter/Tab accept (Enter while composing does nothing), Esc closes the list.
- **No match:** show one row "Search older records" that queries all activities (same ranking, `use_count`/`last_used_at` from the activity table).
- **Performance:** suggestions render within 50 ms of a keystroke (NFR). Unit-test the ranker as a pure function with a fixed clock: prefix vs contains order, initial-consonant match, 8-day-old activity excluded, older search fallback.

### 4.4 Weekly grid (`domain/weekly/`) — FR-4

- Input: week start (Monday, local), settings, entries + calendar events in range.
- Output: rows = slots, columns = days; each cell = list of segments `{label, category, color, source, isMeeting, children}`.
- Merge vertically when consecutive slots have the same `activity_id` (or the same `calendar_event_id`) and no gap.
- Meeting cells show child check-ins (FR-1.14 / FR-3.9).
- Totals: per day and per week, minutes by category and by project, meeting share = meeting minutes / logged minutes.
- Amount (FR-4.11): `round((end − start) / 3_600_000 × hourly_rate_minor)`, shown only for projects with a rate; never stored. Sum per currency; never add different currencies.

### 4.5 Filters (FR-4.12, FR-4.13)

`LogFilter { kind: fixed|relative, from, to, amount, unit, categoryId?, projectId?, source? }`. Relative ranges resolve at query time from the injected clock (e.g. last 1 month = now − 1 calendar month → now). Saved filters persist the definition, not the resolved dates.

### 4.6 Retention / old-data cleanup (`domain/retention/`) — FR-5.10 to FR-5.13

```
purge(cutoff):
  preview = count entries/calendar_events with start_at < cutoff   -- shown before confirming
  BEGIN
    DELETE FROM entry WHERE start_at < cutoff            -- hard delete, including soft-deleted rows
    DELETE FROM calendar_event WHERE end_at < cutoff
    if option "remove unused items":
       DELETE FROM activity WHERE id NOT IN (SELECT activity_id FROM entry WHERE activity_id IS NOT NULL)
         AND pinned = 0
    UPDATE settings SET purged_before = max(coalesce(purged_before, 0), cutoff)
  COMMIT
  VACUUM   -- outside the transaction; on web run when idle
```

- Manual: cutoff = start of local day 3 or 6 calendar months ago, or a chosen date.
- Auto (FR-5.11): on app start, once per day, if `auto_purge_months` is set. Show a notice the day before records are removed ("N records from before <date> will be deleted tomorrow").
- Always offer "Export backup first" before a manual purge.

### 4.7 Backup export/import (`domain/backup/`) — FR-5.4, FR-5.13

File: `logmydailytask-backup-YYYYMMDD.ldt` = JSON (optionally encrypted with a user password: AES-GCM, key from PBKDF2/Argon2).

```json
{
  "format": "logmydailytask-backup",
  "schemaVersion": 1,
  "exportedAt": 1762992000000,
  "deviceId": "…",
  "purgedBefore": 1755000000000,
  "tables": { "category": [...], "project": [...], "activity": [...], "entry": [...],
              "saved_filter": [...], "calendar_event": [...], "settings": [...] }
}
```

Import merge rules:
- Match rows by `id`. Newer `updated_at` wins; a row with `deleted_at` set wins over an older live row (tombstone).
- Skip rows with `start_at < settings.purged_before` unless the user ticks "Include older records" (FR-5.13).
- Never import device-only settings (`notifications_enabled_on_device`) or calendar tokens. Calendar connections are re-authorized on the new device.
- Run in one transaction; show a summary (added / updated / skipped).

### 4.8 Mobile CSV export (FR-6.11, FR-6.12)

- Screen: period (this week / last week / this month / custom) + filters (category, project, device) → "Export CSV" → `share_plus` share sheet.
- Encoding: UTF-8 with BOM (`\uFEFF`) so Excel opens Korean correctly; CRLF line endings; RFC 4180 quoting.
- Columns: `entry_id, date, start, end, minutes, category, project, description, note, source, status, device_name, device_platform, sheet_status, sheet_synced_at`.
- `sheet_status` values match the UI: `synced` / `pending` / `failed` / `not_linked` (localized header labels, stable English values).
- File name: `logmydailytask_YYYYMMDD-YYYYMMDD.csv`. Write to the app's temp directory, share, then delete.
- Desktop and web keep FR-4.7 export (save dialog / download) with the same columns.

---

## 5. Calendar integration (`integrations/calendar/`) — FR-3

Common interface:

```dart
abstract class CalendarProvider {
  Future<void> connect();                       // OAuth or ICS URL
  Future<SyncResult> sync({String? cursor});    // returns upserts, deletions, nextCursor
  Future<void> disconnect({required bool keepEvents});
}
```

**Microsoft 365 / Outlook (Graph)**
- Scope: `Calendars.Read` (+ `offline_access`, `User.Read` for the email). Public client, PKCE, no secret.
- Sync: `GET /me/calendarView/delta?startDateTime=…&endDateTime=…`; store the `@odata.deltaLink` as `sync_cursor`.
- Window: from `max(purged_before, today − 30 days)` to `today + 14 days`.
- Admin consent (section 6 of the PRD): when the token request fails with an admin-consent error (e.g. `AADSTS65001` / `AADSTS90094` — confirm exact codes during testing), open `AdminConsentHelpScreen`: draft email to IT, the admin consent URL (`https://login.microsoftonline.com/{tenant}/adminconsent?client_id=…`), ICS fallback, "continue without calendar".

**Google Calendar**
- Scope: `https://www.googleapis.com/auth/calendar.readonly`. Requires Google OAuth app verification before public launch.
- Sync: `events.list` on `primary` with `singleEvents=true`; first call with `timeMin/timeMax`, then `syncToken`. On HTTP 410, drop the token and do a full sync.

**ICS**
- User pastes a published calendar URL. Fetch every 15 min while running; parse VEVENT; treat all as `accepted`.

Filters (FR-3.4) are applied when converting events to meeting entries, not when storing events, so changing a filter takes effect without re-syncing.

Online link detection: look for `teams.microsoft.com`, `meet.google.com`, `zoom.us` in location/body/online meeting fields.

### 5.1 Google Sheets sync (`integrations/sheets/`) — FR-6

**Turning it on (sign-in check, FR-6.1):**
1. Google sign-in with scope `drive.file` only (separate from the calendar consent so users can link one without the other; if both are used, request incrementally).
2. Show the signed-in email and ask the user to confirm the account.
3. Create the spreadsheet "LogMyDailyTask Log" (`spreadsheets.create`) with a `Log` tab and the header row, or let the user pick one this app created earlier (with `drive.file` the app can only see its own files; use the Drive file list filtered to spreadsheets).
4. Write test: append and then clear a test row. Only when this succeeds, save `sheet_connection` and set `enabled = 1`.
5. Mark all existing entries `pending` and start the first upload.

**Upload (app → sheet), FR-6.4/6.5:**
- Any insert/update/soft-delete of an entry sets `sheet_sync_state = 'pending'`.
- Queue worker runs right after a save, every 5 minutes while the app runs, and on app start; batches up to 200 rows per run.
- Row lookup: read column A (`Log!A:A`) once per run into a map `entry_id → row number`; existing rows → `values.batchUpdate`; new rows → one `values.append`. Never rely on stored row numbers (users can sort the sheet).
- Soft-deleted entries: update the row and set column O (`deleted`) to `TRUE`; never delete rows from sync.
- On success: `sheet_sync_state = 'synced'`, `sheet_synced_at = now`. On error: `failed` + `sheet_error`, retry with exponential backoff; on HTTP 429/5xx back off and keep `pending`.
- Auth problems (401, revoked grant, 403 permission, 404 spreadsheet): stop the worker, set `sheet_connection.last_error`, show the "Sign in again" banner (FR-6.8). Nothing is lost; entries stay `pending`.

**Pull (sheet → app), FR-6.9, optional per device:**
- On each run, read rows whose device (column L/M) is not this device and whose `updated` (column N) is newer than the last pull.
- Upsert them locally as read-only records (`device_id` = that device; create a `device` row for unknown devices). They appear in the weekly table with the device label and can be filtered by device.
- Sheet edits made by hand are not imported for this device's own rows (one-way for own rows).

**Retention interaction (FR-6.10):** the purge job removes local rows only. If `delete_rows_on_purge = 1`, it also deletes matching sheet rows (batched `deleteDimension`), after the same confirmation dialog.

**Limits:** keep each sheet to one header row + data; if a year tab is needed later, split by `Log_YYYY`. Respect Sheets API per-minute quotas by batching and backing off.

**Verification:** `drive.file` is classified by Google as a non-sensitive scope at the time of writing (confirm during OAuth app setup); `calendar.readonly` still needs verification.

---

## 6. Platform specifics

| Platform | Popup / reminder | Must-do items |
| --- | --- | --- |
| Windows | Small frameless always-on-top window (≈ 380×420) at bottom-right via `window_manager`; tray icon with "Log now", "Start timer", "Pause", "Open weekly", "Quit" | Launch at startup option; single-instance lock; global hotkey Ctrl+Shift+L |
| macOS | Menu bar icon + floating panel; local notification as fallback | Notification permission prompt; login item; Cmd+Shift+L; app sandbox entitlements for network |
| iOS | Local notification with text input action (Quick Reply) and "Same as last" action; tap opens the check-in sheet | Rolling 64-notification window; reschedule on open; Sign in with Apple is NOT required (no account) |
| Android | Notification with RemoteInput reply + "Same as last" action | `POST_NOTIFICATIONS` (13+), exact alarms (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`, 12+), reschedule on boot; Samsung battery-optimization guidance screen |
| Web (PWA) | Notification API + in-page modal | Request permission on a user gesture; banner "Notifications only while this tab is open"; weekly backup reminder; `_headers` for COOP/COEP |

Idle detection (FR-1.10, phase 2) is desktop-only.

---

## 7. Screens (see the design canvas)

Design canvas: https://claude.ai/artifact/SawoUzPGp8Z7UTDK6oS4H4 (weekly table, settings with meeting and data-cleanup options, desktop check-in popup, mobile check-in sheet, mobile day view).

| Screen | Route | Key FRs |
| --- | --- | --- |
| Onboarding (name, time zone, working hours, interval, calendar optional) | `/onboarding` | FR-5.1, FR-1.1, FR-1.2 |
| Check-in popup (desktop) / sheet (mobile, web) | `/checkin?slot=…` | FR-1.3, 1.5, 1.8, 2.1–2.5 |
| Weekly table | `/week?start=…` | FR-4.1–4.5, 4.11 |
| Day view (mobile) | `/day?date=…` | FR-4.9 |
| Log list + filters | `/log` | FR-4.6, 4.12 |
| Projects | `/projects` | FR-2.11, 2.12 |
| Categories | `/categories` | FR-2.6 |
| Settings | `/settings` | FR-5.3, 1.6, 1.7, 1.14 |
| Calendar connect + admin consent help | `/settings/calendar` | FR-3.1, 3.2, PRD §6 |
| Data & backup (export, import, delete old data, auto-cleanup) | `/settings/data` | FR-5.4, 5.6, 5.10–5.13 |
| Google Sheets link (sign-in check, account, status, device name) | `/settings/sheets` | FR-6.1–6.8 |
| CSV export (mobile share) | `/export` | FR-6.11, 6.12 |

Design tokens (from the design canvas): primary `#2F5BEA`, meeting `#E8833A`, surface `#FFFFFF` / dark `#16181D`, text `#1B1D22`, radius 12 (cards) / 8 (cells), base spacing 8, font Inter (Latin) + Noto Sans KR (Korean), both bundled with the app (no runtime font downloads). Category colors come from a fixed palette of 10 accessible colors (contrast ≥ 4.5:1 for labels).

---

## 8. Build order (milestones)

Each milestone ends with tests passing and a short demo on at least one desktop and one mobile target.

| # | Milestone | Done when |
| --- | --- | --- |
| M0 | Project setup: Flutter app for 5 targets, riverpod, go_router, l10n (ko/en), CI running tests | `flutter test` green in CI; app launches on Windows, macOS, iOS sim, Android emulator, Chrome |
| M1 | Database: drift schema v1, encryption (native), WASM (web), seed data, repositories | Repository tests for CRUD, soft delete, unique activity, single running timer |
| M2 | Slot math + scheduler (pure Dart) with fake clock | Tests: alignment modes, custom interval, work hours, pause, timer running, missed slots, DST day |
| M3 | Check-in popup UI + saving answers + pick list + autocomplete + IME guard | Answer in ≤ 5 s by keyboard only; widget tests for "Same as last" and missed-slot fill |
| M4 | Platform reminders: desktop popup window + tray + hotkey; mobile local notifications with reply; web notifications | Manual test checklist per platform signed off |
| M5 | Weekly table + day view + totals + list view + filters | Golden tests for weekly grid; totals match a fixture |
| M6 | Projects + rates + amount column + companion timer | Amount math tests (rounding, per-currency sums) |
| M7 | Calendar: Graph, Google, ICS, filters, meeting pause, long-meeting option, admin-consent help | Integration tests with recorded HTTP fixtures; manual test with a real M365 and Google account |
| M8 | Export xlsx/CSV; backup export/import with merge + purged_before | Round-trip test: export → wipe → import → identical data |
| M9 | Data cleanup: manual 3/6 months/custom, auto-cleanup, preview, VACUUM | Tests: rows before cutoff gone, after cutoff kept, settings.purged_before set, import skips old rows |
| M9.5 | Google Sheets sync (sign-in check, create/link sheet, upsert queue, status badges, device labels, pull other devices) + mobile CSV share | Tests with a fake Sheets client: upsert by entry_id after the sheet is re-sorted, soft-delete marks row, auth error → pending + banner; CSV has BOM, device and sheet_status columns |
| M10 | Polish: dark mode, accessibility pass, store assets, privacy policy page (static) | Accessibility checklist; app store submission builds |

---

## 9. Testing

- **Unit (pure Dart):** `time_slots`, scheduler decisions, weekly grid, amount math, filter resolution, retention, backup merge. Always inject `Clock`.
- **Repository:** in-memory drift DB (`NativeDatabase.memory()`).
- **Migrations:** one test per schema version step.
- **Widget/golden:** popup, weekly table (light/dark, ko/en).
- **Integration:** calendar providers and the Sheets client against recorded JSON fixtures; never hit real APIs in CI.
- **Manual platform checklist:** notification permission flows, reboot rescheduling (Android), 64-notification window (iOS), tab-closed behavior (web), hotkey conflicts (desktop).

Key fixture: one week with a 30-min interval, a 60-min team meeting Monday 10:00, a 2-hour workshop Thursday 13:00 with FR-1.14 on, two missed slots Wednesday, a running timer Friday.

---

## 10. Conventions

- Dart: `dart format`, `flutter_lints` (strict), no `print` (use a logger that never logs entry text or tokens).
- IDs: UUID v7. Times: `int` UTC ms in the DB; `TZDateTime` in the domain layer.
- Date display: one helper `formatDate(d)` = `DateFormat('EEE, M/d/yyyy', 'en_US')` → `Fri, 11/13/2026`, used in both the Korean and English UI (week headers, day view, filters, cleanup preview). Ranges: `Mon, 11/9/2026 – Fri, 11/13/2026`. Times follow the device's 12/24-hour setting. Machine formats (sheet column B, CSV, backup) stay `yyyy-MM-dd`.
- Errors: domain functions return `Result<T, AppError>`; UI shows localized messages.
- Privacy: never log activity titles, notes, meeting titles, emails or tokens. Analytics are opt-in and count events only.
- Commits: Conventional Commits (`feat(scheduler): …`), referencing FR IDs in the body.
- Each PR: tests for new logic, both `app_ko.arb` and `app_en.arb` updated, screenshots for UI changes.

---

## 11. Prompts that work well with a coding agent

Use one milestone at a time and point at this file:

- "Read CLAUDE.md and docs/PRD_en.md. Implement M1: the drift schema in section 3 with repositories and tests. Do not add any network code."
- "Implement `domain/scheduler` per section 4.2 as pure Dart with an injected Clock. Write the tests listed in M2 first, then the code."
- "Build the weekly grid builder in section 4.4. Use the fixture week from section 9 and add a golden test for the weekly table widget."
- "Implement the retention purge in section 4.6 and the backup import rule for purged_before in section 4.7, with tests."

---

## 12. Open items for the coding phase

- Confirm exact Microsoft identity error codes that mean "admin approval required" on test tenants.
- Register app IDs: Azure AD (multi-tenant, public client, redirect URIs per platform) and Google Cloud OAuth client (verification for `calendar.readonly`; enable the Sheets and Drive APIs for `drive.file`).
- Choose the final category color palette and verify contrast in both themes.
- Confirm "LogMyDailyTask" trademark, store names and domain before submitting builds.
