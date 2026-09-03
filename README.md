<h1 align="center">lib_app_version</h1>

<p align="center">
  <strong>Know when your Flutter app is out of date — and whether it's running from TestFlight.</strong><br/>
  App Store & Google Play version check, install-source detection and a ready-made update dialog.<br/>
  <em>Zero dependencies. Zero native setup. Never throws.</em>
</p>

<p align="center">
  <a href="https://github.com/winterzxzz/lib_app_version/actions/workflows/ci.yml"><img src="https://github.com/winterzxzz/lib_app_version/actions/workflows/ci.yml/badge.svg" alt="CI status" /></a>
  <a href="https://github.com/winterzxzz/lib_app_version/releases"><img src="https://img.shields.io/github/v/tag/winterzxzz/lib_app_version?label=version&color=0175C2&logo=dart" alt="Latest version" /></a>
  <a href="https://github.com/winterzxzz/lib_app_version/blob/main/LICENSE"><img src="https://img.shields.io/github/license/winterzxzz/lib_app_version?color=success" alt="MIT license" /></a>
  <img src="https://img.shields.io/badge/platform-iOS%2013%2B%20%C2%B7%20Android%207%2B-000000?logo=apple&logoColor=white" alt="Platform: iOS 13+, Android 7+" />
  <img src="https://img.shields.io/badge/Flutter-3.22%2B-02569B?logo=flutter&logoColor=white" alt="Flutter 3.22+" />
  <img src="https://img.shields.io/badge/dependencies-none-brightgreen" alt="Zero dependencies" />
  <!-- Once published to pub.dev:
  <a href="https://pub.dev/packages/lib_app_version"><img src="https://img.shields.io/pub/v/lib_app_version.svg?label=pub.dev&color=0175C2&logo=dart" alt="pub.dev version" /></a>
  <a href="https://pub.dev/packages/lib_app_version/score"><img src="https://img.shields.io/pub/points/lib_app_version?label=pub%20points&color=blue" alt="pub points" /></a>
  <a href="https://pub.dev/packages/lib_app_version"><img src="https://img.shields.io/pub/likes/lib_app_version?label=likes&color=blue" alt="pub likes" /></a>
  -->
</p>

<p align="center">
  <a href="#-quick-start">Quick start</a> ·
  <a href="#-what-you-get-back">Status object</a> ·
  <a href="#️-testflight--install-source">TestFlight</a> ·
  <a href="#-forced-updates">Forced updates</a> ·
  <a href="#-customizing-the-dialog">Dialog</a> ·
  <a href="#-version-sources">Sources</a> ·
  <a href="#️-configuration-reference">Configuration</a> ·
  <a href="#-faq">FAQ</a>
</p>

---

**lib_app_version** answers the three questions every production app eventually asks: *Is there a newer build in the store?* *Should I force the user to update?* and *Is this build running from TestFlight?* It talks to the iTunes Lookup API and the Google Play listing directly, reads the install receipt natively, and ships an adaptive update dialog — without pulling `package_info_plus`, `url_launcher`, `http` or any other package into your dependency tree.

```dart
await AppVersion.showUpdateDialogIfNeeded(context);   // check + dialog, one line
final bool testFlight = await AppVersion.isTestFlight(); // native, no network
```

## ✨ Why lib_app_version?

- **📦 Zero dependencies.** The only dependency is `flutter`. Nothing to conflict with the versions of `package_info_plus`, `url_launcher` or `http` your app already uses.
- **🔧 Zero native setup.** No `AppDelegate` edits, no manifest changes — the plugin registers itself and the `INTERNET` permission is merged automatically.
- **✈️ TestFlight & install-source detection.** Sandbox receipt and provisioning-profile heuristics on iOS, installer package on Android. `isTestBuild` gives you one answer on both platforms.
- **⛔ Optional *or* forced updates.** Pass a `minimumVersion` (from Remote Config, your API, anywhere) and the dialog becomes blocking; or use `force: true` to make every update mandatory.
- **💬 Adaptive dialog in one call.** Material on Android, Cupertino on iOS, localizable texts, release notes, or bring your own widget.
- **🛡️ Never throws.** Offline? Store markup changed? You get `status.error` and `isUpdateAvailable == false`; your app keeps running.
- **⚡ Cached and de-duplicated.** One store request per 30 minutes; concurrent callers share the same in-flight request.
- **🔌 Pluggable sources.** App Store, Play Store, your own backend, Firebase Remote Config, or a static value for tests.
- **🧪 Built for testing.** Swap `AppVersion.instance`, inject a fake platform bridge or HTTP function — no method-channel mocking required.

## 🚀 Quick start

### 1. Install

```yaml
dependencies:
  lib_app_version:
    git:
      url: https://github.com/winterzxzz/lib_app_version.git
      ref: v1.0.0
```

Or, inside a monorepo, as a path dependency:

```yaml
dependencies:
  lib_app_version:
    path: ../lib_app_version
```

### 2. Requirements

| Requirement | Value |
| --- | --- |
| Flutter | `>= 3.22.0` |
| Dart | `^3.8.0` |
| iOS | 13.0+ (Swift, CocoaPods **and** Swift Package Manager) |
| Android | minSdk 24 (Android 7.0), Kotlin |
| Third-party packages | none |

### 3. Use it

```dart
import 'package:lib_app_version/lib_app_version.dart';

void main() {
  // Optional. Without it, your bundle id / applicationId is used.
  // A numeric iosId gives you a store link even when the lookup fails.
  AppVersion.init(
    iosId: '6762586391',
    androidId: 'com.example.app',
  );
  runApp(const MyApp());
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Shows the dialog only when the store has a newer version.
      AppVersion.showUpdateDialogIfNeeded(context);
    });
  }
  // ...
}
```

Need more control? Every building block is one call away:

```dart
final AppVersionStatus status = await AppVersion.check();
if (status.isUpdateAvailable) {
  debugPrint('${status.localVersion} → ${status.storeVersion}');
}

final bool testFlight = await AppVersion.isTestFlight();   // iOS, no network
final AppInstallSource source = await AppVersion.getInstallSource();
await AppVersion.openStore();                              // Play / App Store app
```

That's it — no Swift, no Kotlin, no extra packages.

## 📦 What you get back

`AppVersion.check()` returns an `AppVersionStatus`:

| Member | Type | Meaning |
| --- | --- | --- |
| `localVersion` / `buildNumber` | `String` | The running build (`1.1.4`, `12`). |
| `storeVersion` | `String?` | Version published in the store, `null` if the lookup failed. |
| `isUpdateAvailable` | `bool` | `storeVersion > localVersion`. |
| `isUpdateRequired` | `bool` | `localVersion < minimumVersion` — a **forced** update. |
| `updateType` | `AppUpdateType` | `none` · `optional` · `required`. |
| `shouldUpdate` | `bool` | `updateType != none`. |
| `isUpToDate` | `bool` | Store reachable and nothing newer. |
| `isAheadOfStore` | `bool` | Running a build **newer** than the store (testing tracks, debug builds). |
| `isTestFlight` | `bool` | iOS build installed through TestFlight. |
| `isTestBuild` | `bool` | `isTestFlight \|\| isAheadOfStore` — works on Android too. |
| `installSource` | `AppInstallSource` | `appStore` · `testFlight` · `playStore` · `sideload` · `development` · `simulator` · `unknown`. |
| `storeUrl` | `String?` | Link to the store listing. |
| `releaseNotes` | `String?` | "What's new" text when the store provides it. |
| `error` | `Object?` | Why the store lookup failed, if it did. Nothing is thrown. |

Version strings are compared numerically (`1.10.0 > 1.9.9`, `1.2 == 1.2.0`); pre-release and build metadata are ignored.

## ✈️ TestFlight & install source

```dart
// iOS only, no network involved:
final bool testFlight = await AppVersion.isTestFlight();

// Cross-platform "is this a test build?" (TestFlight, Play internal testing, debug):
final bool testBuild = (await AppVersion.check()).isTestBuild;
```

A common pattern is serving a different remote configuration to testers:

```dart
final bool tester = (await AppVersion.check()).isTestBuild;
final String key = tester ? 'APP_CONFIG_TESTFLIGHT' : 'APP_CONFIG';
final String config = remoteConfig.getString(key);
```

How the install source is determined:

| Platform | Signal | `installSource` |
| --- | --- | --- |
| iOS | Compiled for the simulator | `simulator` |
| iOS | Bundle contains `embedded.mobileprovision` (Xcode, Ad Hoc, Enterprise) | `development` |
| iOS | Receipt file is `sandboxReceipt` | `testFlight` |
| iOS | Receipt file is `receipt` | `appStore` |
| Android | Installer is `com.android.vending` (every Play track) | `playStore` |
| Android | No installer at all (`adb install`, IDE run) | `development` |
| Android | Any other installer (system package installer, third-party store) | `sideload` |

Google Play does not distinguish testing tracks from production, which is why `isAheadOfStore` / `isTestBuild` exist.

## ⛔ Forced updates

An update is **required** when the installed version is below `minimumVersion`. The dialog then has no "Later" button and cannot be dismissed with the back gesture or by tapping outside; it stays open even after the store is opened.

```dart
// 1. Per call — e.g. read from Firebase Remote Config
final String minVersion = remoteConfig.getString('MIN_SUPPORTED_VERSION'); // "1.2.0"
await AppVersion.showUpdateDialogIfNeeded(context, minimumVersion: minVersion);

// 2. Once, at startup
AppVersion.init(minimumVersion: '1.2.0');

// 3. From your own version source (see below)
AppVersion.init(
  source: VersionSource.fromCallback((local) async => StoreVersionInfo(
    version: remoteConfig.getString('LATEST_VERSION'),
    minimumVersion: remoteConfig.getString('MIN_SUPPORTED_VERSION'),
  )),
);

// Or simply make every update mandatory
await AppVersion.showUpdateDialogIfNeeded(context, force: true);
```

## 🎨 Customizing the dialog

```dart
// Localized texts and release notes
await AppVersion.showUpdateDialogIfNeeded(
  context,
  texts: AppUpdateDialogTexts(
    title: l10n.updateTitle,
    message: l10n.updateMessage,
    updateButton: l10n.update,
    laterButton: l10n.later,
  ),
  showReleaseNotes: true,
);

// Your own widget — `mandatory` tells you whether it must be blocking,
// `openStore` opens the listing.
await AppVersion.showUpdateDialogIfNeeded(
  context,
  builder: (context, status, mandatory, openStore) => PopScope(
    canPop: !mandatory,
    child: MyUpdateSheet(
      version: status.storeVersion,
      notes: status.releaseNotes,
      onUpdate: openStore,
    ),
  ),
);

// Or use the default dialog widget directly
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => AppUpdateDialog(
    status: status,
    mandatory: true,
    onUpdate: AppVersion.openStore,
  ),
);
```

The default dialog is `AlertDialog.adaptive`: Material on Android, Cupertino on iOS. `showUpdateDialogIfNeeded` never opens a second dialog while one is visible, so it is safe to call from several places.

## 🔌 Version sources

| Source | Where the version comes from |
| --- | --- |
| `StoreVersionSource` *(default)* | App Store on iOS, Play Store on Android. |
| `AppStoreVersionSource` | iTunes Lookup API, by numeric id or bundle id, optional storefront `country`. |
| `PlayStoreVersionSource` | Google Play listing page, optional `locale`. |
| `CallbackVersionSource` / `VersionSource.fromCallback` | Any async function — Remote Config, your backend, feature flags. |
| `StaticVersionSource` | A fixed value, ideal for tests and demos. |

Implement `VersionSource` for anything else:

```dart
class MyApiVersionSource extends VersionSource {
  const MyApiVersionSource();

  @override
  Future<StoreVersionInfo?> fetch(LocalAppInfo local) async {
    final json = await api.get('/app-version?platform=${local.packageName}');
    return StoreVersionInfo(
      version: json['latest'],
      minimumVersion: json['minimum'],
      storeUrl: json['storeUrl'],
      releaseNotes: json['notes'],
    );
  }
}

AppVersion.init(source: const MyApiVersionSource());
```

## ⚙️ Configuration reference

All parameters are shared by `AppVersion.init(...)` and `AppVersionChecker(...)`.

| Parameter | Default | Description |
| --- | --- | --- |
| `androidId` | applicationId | Play Store package id. |
| `iosId` | bundle id | Numeric App Store id (recommended) or bundle id. |
| `iosCountry` | `null` (US) | Two-letter storefront (`vn`, `jp`, …) if the app is not on the US store. |
| `androidLocale` | `en_US` | `hl` parameter for the Play Store page. |
| `minimumVersion` | `null` | Versions below it are reported as `required`. |
| `forceStoreVersion` | `null` | Pretend the store has this version — development only. |
| `cacheDuration` | 30 min | How long a store answer is reused. |
| `timeout` | 10 s | Network timeout per request. |
| `source` | store lookup | Custom `VersionSource`. |
| `platform` | method channel | `LibAppVersionPlatform` bridge, replaceable in tests. |
| `httpGet` | `dart:io` | `HttpGet` function, replaceable in tests. |

## 🧪 Testing

Try the update flow before anything is published:

```dart
AppVersion.init(forceStoreVersion: '99.0.0'); // dev builds only
```

Unit-test your own code without touching the network or a method channel:

```dart
AppVersion.instance = AppVersionChecker(
  platform: FakeAppPlatform(),                         // implements LibAppVersionPlatform
  source: const StaticVersionSource(version: '9.9.9'), // or minimumVersion: ...
);
```

`AppVersionChecker` is a plain class — create several instances if you need different configurations.

## 🔬 How it works

```text
AppVersion.check()
 ├─ LibAppVersionPlatform.getAppInfo()          MethodChannel "lib_app_version"
 │    version · build · packageName · installSource      (Swift / Kotlin, cached)
 └─ VersionSource.fetch(local)                  cached 30 min, de-duplicated
      ├─ iOS      → https://itunes.apple.com/lookup?id=…            (JSON)
      ├─ Android  → https://play.google.com/store/apps/details?id=…  (HTML)
      └─ custom   → your API / Remote Config
 → AppVersionStatus  →  showUpdateDialogIfNeeded()  →  openStore()
                                                        market:// → https (Android)
                                                        itms-apps:// → https (iOS)
```

- **iOS** reads `CFBundleShortVersionString` / `CFBundleVersion`, checks for an embedded provisioning profile and inspects `appStoreReceiptURL` (the same heuristic used by most production apps).
- **Android** reads `PackageInfo` and the installing package (`getInstallSourceInfo` on API 30+, `getInstallerPackageName` below).
- Opening the store tries the store app first and falls back to the browser. No `LSApplicationQueriesSchemes` or `<queries>` entries are needed.

## 📱 Platform behavior

| Platform | Store lookup | `isTestFlight` | `installSource` | Open store |
| --- | --- | --- | --- | --- |
| **iOS 13+** | iTunes Lookup API | ✅ native | ✅ | App Store app → Safari |
| **Android 7+** | Play Store listing | always `false` | ✅ | Play Store app → browser |
| **Web · desktop** | `status.error` is set | `false` | `unknown` | `false` |

The package never crashes on unsupported platforms; every call degrades to "no update".

## 🧪 Example app

The `example/` app shows the local build info, the install source, the store status, and lets you trigger the optional and forced dialogs. Flip *Simulate a newer store version* to see the dialog without publishing anything.

```sh
cd example
flutter run
```

## ❓ FAQ

<details>
<summary><strong>Why not <code>new_version_plus</code> / <code>upgrader</code>?</strong></summary>
Those packages bring their own transitive dependencies (<code>package_info_plus</code>, <code>http</code>, <code>url_launcher</code>, …) that regularly conflict with the versions an app already pins. <code>lib_app_version</code> has none, adds TestFlight / install-source detection, first-class forced updates, caching and a test-friendly API.
</details>

<details>
<summary><strong>Is reading the Play Store page reliable?</strong></summary>
Google offers no public API for the listed version, so the page is scanned for the version string — the same approach the community has relied on for years. If Google changes the markup, <code>check()</code> reports the failure through <code>status.error</code> and your app keeps working. For guaranteed results, serve the version yourself with <code>VersionSource.fromCallback</code>.
</details>

<details>
<summary><strong>The App Store lookup returns nothing for my new app.</strong></summary>
The iTunes Lookup API can lag a few hours behind a first release. Pass a numeric <code>iosId</code> so the store link works regardless, and set <code>iosCountry</code> if the app is not available on the US storefront.
</details>

<details>
<summary><strong>Does TestFlight detection need network access?</strong></summary>
No. <code>AppVersion.isTestFlight()</code> only inspects the app bundle and returns instantly. Only the store comparison goes online.
</details>

<details>
<summary><strong>Does it work on the iOS simulator or in debug builds?</strong></summary>
Yes. The simulator reports <code>installSource == simulator</code>, Xcode / Ad Hoc / Enterprise builds report <code>development</code>; neither is mistaken for TestFlight.
</details>

<details>
<summary><strong>What about Google Play In-App Updates?</strong></summary>
Play's in-app update flow is a different feature (it downloads the update inside your app and needs the Play Core library). This package is store-agnostic and dependency-free; use it to detect and prompt, and add Play In-App Updates on top if you want the in-app download experience.
</details>

<details>
<summary><strong>Do I need permissions or plist entries?</strong></summary>
No. The Android <code>INTERNET</code> permission is merged from the plugin manifest, and the store is opened without <code>LSApplicationQueriesSchemes</code> / <code>&lt;queries&gt;</code> declarations.
</details>

<details>
<summary><strong>How are versions compared?</strong></summary>
Only the leading numeric components count: <code>1.2.3</code>, <code>1.2</code>, <code>1.2.3.4</code> and <code>v1.2.3-beta+7</code> all parse, missing parts are <code>0</code> (<code>1.2 == 1.2.0</code>) and comparison is numeric (<code>1.10 &gt; 1.9</code>). The parser is exposed as <code>VersionNumber</code>.
</details>

## 🤝 Contributing

Issues and pull requests are welcome! If this package saved you time, a ⭐ on [GitHub](https://github.com/winterzxzz/lib_app_version) helps others discover it.

- 🐛 [Report a bug](https://github.com/winterzxzz/lib_app_version/issues)
- 📝 [Changelog](https://github.com/winterzxzz/lib_app_version/blob/main/CHANGELOG.md)

```sh
flutter pub get && flutter analyze && flutter test   # 66 tests, runs in ~2 s
```

## 📄 License

MIT © [winterzxzz](https://github.com/winterzxzz). See [LICENSE](https://github.com/winterzxzz/lib_app_version/blob/main/LICENSE).

---

<sub>Keywords: flutter app version check, flutter update dialog, force update flutter, flutter testflight detection, flutter new version, app store version flutter, play store version flutter, flutter in app update prompt, flutter minimum version, flutter version checker plugin, new_version_plus alternative, upgrader alternative.</sub>
