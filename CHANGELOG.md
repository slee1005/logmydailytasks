# Changelog

## 0.2.3 — 2026-11-19

- Use Add entry / 기록 추가 and a compact daily worklog. Show notes and categories only when expanded, and display completed task times without dates, weekdays, or time zones on iOS and macOS.
- Improve day navigation, recent activity suggestions, reminder scheduling, CSV export, app icons, and the iOS launch screen.
- Add local category renaming and archiving while preserving historical entries.
- Open the connected Google Sheet directly from the connection page. Store native spreadsheet date/time values and numeric elapsed minutes.
- Close the same device's previous unfinished task when a new task is saved. Keep imported records read-only.
- Choose an available versioned spreadsheet filename instead of overwriting an existing file.
- Fix native macOS Google sign-in with the app-specific Keychain group. Preserve and migrate existing database encryption keys without replacing inaccessible keys.
- Fix version 5 database upgrades when the category archive column already exists, restoring task loading, task saving, device-name saving, and Google sync.
- Keep standalone macOS installers compatible with the file-based Keychain and preserve existing GitHub release notes and other assets when uploading the DMG.

Release targets: iOS 0.2.3 (10), Android 0.2.3 (10), and standalone macOS 0.2.3 (10). The equivalent Store macOS fixes are available in 1.0.1 (9), submitted separately to App Review. Google Sheets sign-in on macOS requires the Store/TestFlight build; the public DMG is not notarized and does not include Google sign-in.
