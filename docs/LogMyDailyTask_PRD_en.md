# LogMyDailyTask Product Requirements Document (PRD)

2026-11-13 · John S Lee

## 1. Overview

LogMyDailyTask is a free personal app for remote and work-from-home workers. At a set interval it shows a short popup asking what they are doing, merges the answers with calendar meetings, and produces a weekly worklog table. There is no account and no server: all data stays on the user's devices.

**Problem:** Remote workers rely on memory when they write weekly reports or timesheets. Logging is easy to skip, and meetings have to be dug out of the calendar separately.

**Goals**

- Each entry takes under 5 seconds: pick a previous item or type one line
- Check-in response rate of 80% or more during working hours
- One click to view and export the weekly worklog as a table
- Runs on Windows, macOS, iOS, Android (Galaxy), and the web

**Product principles (decided)**

- Starts as a personal app (no team or admin features)
- Free, no ads, no sign-up
- Data is stored locally only and never sent to a company server

## 2. Target users and scenarios

The primary users are remote workers and freelancers who need to report their work by the hour.

| User | Need | Main devices |
| --- | --- | --- |
| Remote employee | Weekly status reports, sharing progress with a manager | Windows / macOS + phone |
| Freelancer or consultant | Evidence for billable hours per client | macOS / Windows |
| Field or mobile worker | Quick logging on the go | iOS / Android |
| User on a locked-down company PC | Logging without installing software | Web browser |

**Typical scenario**

1. Work starts at 9:00 → the app starts the check-in timer automatically
2. 9:30 popup: "What are you working on right now?" → one tap on the recent item "Fix ServiceNow notifications"
3. The 10:00–11:00 "Weekly team meeting" in the calendar is logged automatically, with no popup
4. Friday afternoon: open the weekly table, fill the gaps, export to PDF or Excel

## 3. Supported platforms

Phase 1 supports five platforms, including the web. Each device writes to its own local store, and notifications follow each OS's and browser's limits.

| Platform | Minimum version (proposed) | How the check-in appears | Local store | Notes |
| --- | --- | --- | --- | --- |
| Windows | Windows 10 or later | Small input window at bottom right + system tray icon | SQLite | Option to launch at startup |
| macOS | macOS 13 or later | Menu bar icon + floating input window | SQLite | Notification permission, login item |
| iOS | iOS 16 or later | Local notification → reply inline (Quick Reply) or open the app | SQLite | Scheduled notifications because of background limits |
| Android (incl. Galaxy) | Android 10 or later | Notification + inline reply, optional home widget | SQLite | Guide users to exempt the app from Samsung battery optimization |
| Web (PWA) | Latest Chrome, Edge, Safari, Firefox | Browser notification + in-tab input window | SQLite WASM (OPFS; IndexedDB where unsupported) | Notifications only while the tab or installed PWA is open; warn that clearing browser data loses records |

## 4. FR-1 — Check-in reminders

At the interval the user sets, a popup asks "What are you working on right now?" The answer becomes the record for the slot since the last check-in (for example 9:30–10:00).

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1.1 | Interval: 15 / 30 / 60 minutes (default 30) + custom interval (5–120 minutes, in 5-minute steps) | Must |
| FR-1.2 | Working hours and days (e.g., Mon–Fri 9:00–18:00); no popups outside them | Must |
| FR-1.3 | Popup text "Briefly describe what you're working on" + input field + recent/category pick list | Must |
| FR-1.4 | Align to the clock (9:00, 9:30…) or to the start of work | Must |
| FR-1.5 | Snooze (5 / 10 minutes), Skip, and "On a break" buttons | Must |
| FR-1.6 | Pause: 30 minutes / 1 hour / rest of the day | Must |
| FR-1.7 | Pause popups while a calendar meeting is in progress and log that slot as the meeting; resume at the next interval after it ends (exception: FR-1.14) | Must |
| FR-1.8 | Slots that pass without an answer are marked "Not logged"; the next popup offers "Same as before for the missed slots?" | Must |
| FR-1.9 | Per-device notification on/off for users with several devices (auto-dismiss across devices comes with sync in phase 2) | Must |
| FR-1.10 | Detect computer idle time (e.g., no input for 10+ minutes), hold the popup, and ask "What did you do while away?" on return | Should |
| FR-1.11 | Show notifications quietly during Do Not Disturb, screen sharing, or full-screen presentations | Should |
| FR-1.12 | Global shortcut for a manual entry at any time (e.g., Ctrl+Shift+L / Cmd+Shift+L) | Should |
| FR-1.13 | Companion timer: start/stop "working on this now"; popups are skipped while it runs and stopping saves one record | Should |
| FR-1.14 | Option: show check-in popups during meetings of 1 hour or longer (off by default; the threshold is adjustable in Settings). When on, the meeting record stays and check-in answers are saved as detail records inside that meeting, for long workshops, trainings, and working sessions | Should |

## 5. FR-2 — Entry and categories

Anything typed once is saved under a category, so next time the user only picks it from a list.

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-2.1 | Free text (one line, up to 200 characters) + optional note | Must |
| FR-2.2 | Autocomplete from existing items while typing | Must |
| FR-2.3 | One "Same as last" button at the top of the popup + the 5 most recent items | Must |
| FR-2.4 | Pick from a list grouped by category (e.g., Development / Meetings / Support / Docs / Admin) | Must |
| FR-2.5 | When saving a new item, assign a category or create a new one | Must |
| FR-2.6 | Category management: rename, color, merge, archive (hide) | Must |
| FR-2.7 | Optional field: tags | Should |
| FR-2.8 | Pin frequently used items (favorites) | Should |
| FR-2.9 | Suggest a category from the typed text (rule-based, later AI) | Phase 2 |
| FR-2.10 | Korean and English input; no premature Enter while the Korean IME is composing | Must |
| FR-2.11 | Projects: name, client, color, status (In progress / Awaiting feedback / Completed); completed projects hidden from pick lists; items and records can link to a project (optional) | Must |
| FR-2.12 | Optional hourly rate and currency per project, as evidence for freelance billing | Should |

**Terms:** an *Activity* is a reusable work item; an *Entry* is an Activity attached to a specific time slot.

## 6. FR-3 — Calendar integration (Outlook / Google)

In Settings the user connects Outlook (Microsoft 365) or Google Calendar. The app reads the calendar directly, with no server, and adds accepted meetings to the worklog.

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-3.1 | Choose: None / Outlook / Google Calendar (both allowed) | Must |
| FR-3.2 | OAuth 2.0 (PKCE) sign-in from the app, read-only scopes only (Microsoft Graph `Calendars.Read`, Google `calendar.readonly`) | Must |
| FR-3.3 | Meeting fields logged: title, start and end time, attendee count, online or not (Teams/Meet/Zoom link), location | Must |
| FR-3.4 | Filters: accepted only / include tentative / exclude all-day / exclude private events | Must |
| FR-3.5 | Meetings auto-categorized as "Meetings", editable by the user | Must |
| FR-3.6 | Short note popup after a meeting: "Any outcome or notes from this meeting?" (optional) | Should |
| FR-3.7 | Reflect changes and cancellations: query changes every 15 minutes while the app runs and right before each check-in (Graph delta query / Google sync token) | Must |
| FR-3.8 | Meeting description (body) not stored by default; stored only if the user turns it on | Must |
| FR-3.9 | Popups pause during meetings (FR-1.7), so no overlap occurs (in long meetings with FR-1.14 on, check-in answers show as detail records inside the meeting cell); if a manual entry overlaps, the meeting wins and the manual text is kept as a note | Must |
| FR-3.10 | On disconnect, revoke tokens immediately; user chooses to keep or delete meetings already logged | Must |
| FR-3.11 | Tokens kept in the OS secure store (on the web, only for the browser session; sign in again afterward) | Must |

**Microsoft 365 admin consent guidance (decided)**

Company IT often blocks approval of outside apps, so the app guides the user in this order.

1. When sign-in returns "Admin approval required", show a dedicated help screen.
2. Offer a draft email to IT: app name, the permission requested (`Calendars.Read`, read-only), a note that data never leaves the device, and the admin consent link.
3. If the tenant has the Microsoft 365 "admin consent request" feature turned on, tell the user they can send the request from inside the app.
4. While waiting for approval, offer a fallback: paste an ICS calendar link published from Outlook (if the organization allows publishing).
5. If neither works, use check-ins without a calendar and log meetings manually under the "Meetings" category.

Google Workspace uses the same flow; Google's OAuth app verification (sensitive scope) must be complete before launch.

## 7. FR-4 — Weekly worklog table

The weekly view is a table with time slots as rows and weekdays as columns, showing check-ins and meetings together.

**Example (30-minute interval)**

| Time | Mon | Tue | Wed | Thu | Fri |
| --- | --- | --- | --- | --- | --- |
| 9:00–9:30 | [Dev] API integration | [Support] Tickets | [Dev] API integration | [Docs] Manual | [Admin] Email |
| 9:30–10:00 | [Dev] API integration | [Meeting] Team standup | [Dev] Testing | [Docs] Manual | [Dev] Deploy |
| 10:00–11:00 | [Meeting] Weekly team meeting (6 people, Teams) | [Support] Tickets | (Not logged) | [Meeting] Client meeting | [Dev] Deploy |
| Total | Dev 4.5h · Meetings 2h … | … | … | … | … |

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-4.1 | Weekly table view (Mon–Fri by default, weekend optional), previous/next week | Must |
| FR-4.2 | Merge consecutive identical items into one cell | Must |
| FR-4.3 | Category colors; meetings marked with an icon | Must |
| FR-4.4 | Click a cell to edit, add, or delete; fill unlogged cells in bulk | Must |
| FR-4.5 | Daily and weekly totals: hours by category and by project, share of meeting time | Must |
| FR-4.6 | Alternative list view: date · time · category · project · description · source (check-in/calendar/timer) | Must |
| FR-4.7 | Export: Excel (.xlsx), CSV, PDF | Must |
| FR-4.8 | Weekly summary email / read-only share link | Should |
| FR-4.9 | On mobile: one day as a vertical list, swipe left/right to change day | Must |
| FR-4.10 | AI-generated weekly summary ("This week's top 3 items") | Phase 2 |
| FR-4.11 | Amount column in totals and exports for projects with a rate (hours × rate, computed, not stored) | Should |
| FR-4.12 | Log filters: fixed range (from–to) or relative range (last N days/weeks/months/years), category, project, source | Must |
| FR-4.13 | Save frequently used filters (e.g., "Last month · Client A") | Phase 2 |

## 8. FR-5 — Settings, local storage, backup

The app works right after install with no sign-up. Records, categories, and settings are stored only on each device; moving between devices uses a backup file.

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-5.1 | No account or login; on first run ask only for name, time zone, and working hours | Must |
| FR-5.2 | All data stored in a local database on the device; nothing sent to an outside server | Must |
| FR-5.3 | Settings: check-in interval (incl. custom), working hours, time zone, calendar connection, notification sound, language (Korean/English) | Must |
| FR-5.4 | Backup export/import (single file, optional password encryption), used to move to another device | Must |
| FR-5.5 | Backup reminder once a week: "Save a backup file" (especially on the web) | Should |
| FR-5.6 | Delete all data | Must |
| FR-5.7 | Dark mode, follow system theme | Should |
| FR-5.8 | Detect time zone changes automatically (travel) | Should |
| FR-5.9 | Keep the backup file in the user's own cloud folder (OneDrive / Google Drive / iCloud) and merge across devices automatically | Phase 2 |
| FR-5.10 | Delete old data: choose "Older than 3 months" / "Older than 6 months" / a custom date → preview the number of records and the period → suggest exporting a backup → delete after confirmation | Must |
| FR-5.11 | Auto-cleanup option: Off (default) / 3 months / 6 months; records older than that are deleted once a day (at app start), with a notice the day before | Should |
| FR-5.12 | Deletion covers Entries and CalendarEvents before the cutoff date. Categories, activities, and projects are kept (option: also remove items with no remaining records). Permanent delete followed by database compaction (VACUUM) to reclaim space | Must |
| FR-5.13 | Store the cutoff date so that importing an older backup file does not bring back records before it (the import screen lets the user choose to include them) | Must |

## 9. Non-functional requirements

The popup must be light and on time, and work records must be handled as sensitive data.

| Area | Requirement |
| --- | --- |
| Performance | Popup shown within 1 second, desktop resident memory 150 MB or less, under 1% CPU when idle |
| Accuracy | Notification timing within ±1 minute (±5 minutes allowed on mobile due to OS policy; web only while the tab is open) |
| Offline | Everything except calendar queries works without a network |
| Security | Local database encryption (desktop and mobile); OAuth tokens in the OS secure store (Keychain / Windows Credential Manager / Android Keystore); optional password encryption of backup files |
| Privacy | No server or account; no screen capture, keystroke, or app-usage tracking; anonymous usage statistics only if the user opts in |
| Data ownership | Data lives only on the user's devices and can be exported or deleted at any time |
| Accessibility | Popup fully operable by keyboard, screen reader labels, larger text support |
| Languages | Korean and English UI (phase 1), localized date and time formats |
| Cost | Free app, so target zero server running cost (web uses static hosting only) |

## 10. Data model

There are 9 core entities. Every record has `updated_at` and a soft delete (`deleted_at`) so backups can be merged.

| Entity | Key fields | Description |
| --- | --- | --- |
| Profile | id, name, timezone, locale | User info on the device (not an account) |
| Settings | interval_min (15/30/60 or custom), work_days, work_start, work_end, pause_during_meetings, checkin_in_long_meetings, long_meeting_min (default 60), auto_purge_months (none / 3 / 6), purged_before (last deletion cutoff), idle_threshold_min | Check-in and working-hours settings |
| Category | id, name, color, sort_order, archived | Work categories |
| Project | id, name, client, color, status (active / awaiting_feedback / completed), hourly_rate (nullable), currency | Projects, clients, and rates (the reference project's Project + Rate merged for personal use) |
| Activity | id, category_id, project_id (nullable), title, tags, last_used_at, use_count, pinned | Reusable work items |
| Entry | id, activity_id (nullable), project_id (nullable), start_at (UTC), end_at (UTC, nullable = running timer), tz_name, note, source (checkin / manual / calendar / timer), status (logged / missed / break), parent_entry_id (nullable, check-in inside a long meeting), device_id | Time-slot records; duration and amount are computed, not stored |
| SavedFilter | id, name, kind (fixed / relative), date_from, date_to, amount, unit (day / week / month / year), category_id, project_id, source | Saved log filters (the reference project's Static / Relative filters) |
| CalendarConnection | id, provider (outlook / google / ics), account_email, secure_storage_key, sync_cursor, filters | Calendar connection (the token itself lives in the OS secure store) |
| CalendarEvent | id, connection_id, external_id, title, start_at, end_at, attendee_count, online_link_type, response_status | Imported meetings (linked to Entry) |

A running timer is one Entry with an empty `end_at`; only one may run at a time. The amount is computed for display as `(end_at − start_at) × hourly_rate`. The weekly table groups Entries by time slot and is not stored separately.

## 11. Technical architecture

One cross-platform codebase serves five platforms, and every record is stored in the device's local database with no backend server. The app reads calendars directly with the user's token, so there is no server running cost.

```
┌───────────── LogMyDailyTask app (single codebase, no server) ─────────────┐
│  Windows       macOS            iOS            Android        Web (PWA)   │
│  Tray·popup    Menu bar·popup   Local alerts   Inline reply   Browser alerts│
│  ───────────────────────────────────────────────────────────────────────  │
│  Local DB (SQLite · SQLite WASM on web) · on-device only · auto-cleanup    │
│  ───────────────────────────────────────────────────────────────────────  │
│  Check-in scheduler                     Calendar client                    │
│  Work hours·interval·pause in meetings  OAuth (PKCE)·periodic change polling│
└───────────────┬────────────────────────────────┬──────────────────────────┘
                │ Backup file export·import      │ Read-only
                ▼                                ▼
   My files · my cloud folder          Microsoft Graph     Google Calendar API
   (auto-merge comes in phase 2)       (Outlook events)    (Google events)
```

| Layer | Recommended | Alternatives | Why |
| --- | --- | --- | --- |
| App (5 platforms) | Flutter (Windows · macOS · iOS · Android · Web, one codebase) | React Native + Tauri, or web (PWA) wrapped in Tauri | One person can maintain five platforms; desktop tray and popup support |
| Local storage | drift + SQLite (desktop and mobile: SQLCipher-encrypted DB file / web: SQLite WASM stored in the browser's OPFS) | Isar, Realm | Offline logging, weekly aggregate queries |
| Secure storage | Keychain, Windows Credential Manager, Android Keystore | — | Holds OAuth tokens and the DB encryption key |
| Calendar | Microsoft Graph (MSAL), Google Calendar API, ICS link | — | Read-only, client-side auth with PKCE |
| Notifications | OS local notifications, browser Notification API | — | No push server needed |
| Export | xlsx · CSV · PDF generated in the app | — | Data never leaves the device |
| Web hosting | Static hosting (e.g., Cloudflare Pages) | GitHub Pages | No server code, near-zero cost |

Phase 1 needs no API server such as Laravel. Phase 2 auto-sync can also stay serverless by using the user's own cloud folder.

## 12. Similar products and differentiation

There are many time trackers, but few that lightly combine "ask at a regular interval + merge calendar meetings automatically + weekly table".

| Type | Examples | How it works | Difference from this app |
| --- | --- | --- | --- |
| Timer | Toggl Track, Clockify | User presses start/stop | Forget to start it and the record is lost |
| Automatic tracking | RescueTime, Timing (macOS) | Collects app and web usage automatically | Records which app, not what work; feels like monitoring |
| Random ping | TagTime-style apps | Asks at random times | No fixed interval or weekly report table |

**Differentiators**

- Short check-ins at a fixed interval mean fewer gaps, and it is not a monitoring tool
- One-tap reuse of previous items keeps input effort minimal
- Outlook and Google meetings merge into the same table automatically, and popups pause during meetings
- A weekly table ready to submit + Excel/PDF export
- Completely free, no account, data stays on your devices

The product features above reflect a general understanding at the time of writing; recheck their current features before launch.

### Comparison with the open-source LogMyWork (holgus103)

The open-source LogMyWork is a team time-tracking web app built with ASP.NET MVC. We take its project, rate, and filter ideas scaled down for personal use, and leave out team roles and issue tracking. ([GitHub repository](https://github.com/holgus103/LogMyWork), last commit February 2022)

| Item | holgus103/LogMyWork | LogMyDailyTask (this document) | Adopted |
| --- | --- | --- | --- |
| Form | Web app with a server DB, open source | Local app on 5 platforms | — |
| Logging method | Real-time start/stop timer | Periodic check-in popup | Companion timer added (FR-1.13) |
| Projects | Create and edit projects, status (In progress / Awaiting feedback / Completed) | Text field on Activity | Project entity + status added (FR-2.11) |
| Hourly rate | Per-user rate per project, amount computed per entry | None | Project rate and amount column added (FR-2.12, FR-4.11) |
| Log filters | Filter by period, project, task, user; save fixed or relative period filters | Week navigation only | Filters + saved filters (FR-4.12, FR-4.13) |
| Time zone | Time zone adjustment on all entries | One profile time zone | UTC + time zone stored on every entry |
| Roles and permissions | Owner / Manager / Worker / Client | Personal | Excluded |
| Task assignment and deadlines, issues, attachments | Yes | No | Excluded (outside a worklog's scope) |
| Calendar integration and reminders | No | Core feature | — |

**What we took from its DB design:** a record (`TimeEntry`) represents a running timer by leaving its end time empty, and duration and amount are computed as rate × time rather than stored. Filters are saved in two kinds: a fixed period (From/To) and a relative period (last N days, weeks, months, or years).

## 13. Release scope and success metrics

The MVP goal is a free personal release on five platforms, including the web, covering check-ins, categories, calendar integration, the weekly table, export, and backup.

| Phase | Scope |
| --- | --- |
| MVP (phase 1) | Windows · macOS · iOS · Android · Web; FR-1 check-ins (custom interval, pause during meetings, companion timer); FR-2 entry, categories, projects (status, rate); FR-3 Outlook + Google + ICS read access with admin consent guidance; FR-4 weekly table + filters + amount column + Excel/CSV export; FR-5 local storage and backup; Korean/English UI |
| Phase 2 | Automatic merge across devices via the user's cloud folder, auto-dismiss across devices, idle detection, PDF export, saved filters, post-meeting note popup |
| Phase 3 | On-device category suggestions and weekly summaries, timesheet export templates |

Team and admin features and paid plans are out of scope.

**Success metrics (3 months after launch)**

- Check-in response rate of 80% or more during working hours
- Average time per entry of 5 seconds or less
- 60% or more of entries picked from previous items (not typed fresh)
- App store rating of 4.5 or higher, cumulative installs

With no server, the first three metrics are measured only through anonymous statistics the user opts into.

## 14. Decisions

| Question | Decision | Where it applies |
| --- | --- | --- |
| Personal or team | Start as a personal app | Sections 1, 2, 13 |
| Business model | Free | Sections 1, 9, 13 |
| Data storage | Local storage, no server or account | Sections 8, 9, 10, 11 |
| Popups during meetings | Paused for the meeting, logged as the meeting automatically; optional popups allowed in meetings of 1 hour or longer | FR-1.7, FR-1.14, FR-3.9 |
| Check-in interval | 15/30/60 minutes + custom (5–120 minutes) option | FR-1.1 |
| Web version | Included in phase 1 (PWA) | Sections 3, 11, 13 |
| M365 admin consent | Detect error → draft request email to IT → ICS fallback → use without a calendar | Section 6 |
| App name | LogMyDailyTask (changed from LogMyWork) | Throughout |
| Local database | SQLite with the same schema on every platform (drift); SQLCipher encryption on desktop and mobile, SQLite WASM on the web | Sections 3, 10, 11 |
| Old data | Manual deletion of data older than 3 or 6 months + auto-cleanup option | FR-5.10–5.13 |

**Remaining checks**

- [ ] Confirm trademark, app store name, and domain availability for "LogMyDailyTask" (the name clash with the open-source [holgus103/LogMyWork](https://github.com/holgus103/LogMyWork) is resolved by the rename)
- [x] Google OAuth app verification schedule (affects launch timing)
