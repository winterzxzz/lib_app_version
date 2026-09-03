## 1.0.0

- Store version lookup: iTunes Lookup API (iOS) and Play Store listing page (Android).
- TestFlight / install-source detection (`appStore`, `testFlight`, `playStore`, `sideload`, `development`, `simulator`).
- `AppUpdate` static facade over `AppUpdateChecker`; results cached and concurrent lookups de-duplicated.
- Optional / required (`minimumVersion`) updates, custom `VersionSource` (remote config, own API).
- Adaptive update dialog with localizable texts, force mode and custom builder.
- Open the store listing natively (`market://` / `itms-apps://` with web fallback).
- No third-party Dart dependencies; no host-app native changes needed.
