# lib_app_version

Flutter plugin kiểm tra app đã là **version mới nhất trên App Store / Google Play** chưa, nhận biết build đang chạy từ **TestFlight**, và hiển thị **dialog cập nhật** (thường / bắt buộc).

- **Không thêm dependency nào** (không `new_version_plus`, `package_info_plus`, `url_launcher`, `http`, `version`...) nên không bao giờ xung đột version với app.
- **Không phải sửa native**: không cần thêm Swift vào `AppDelegate`, không cần sửa `AndroidManifest` (quyền INTERNET tự merge).
- **Không bao giờ throw**: mất mạng, store đổi layout... thì kết quả chỉ là "không có update" kèm `status.error`.

Được viết lại từ `CheckVersionUtils` + `AppDistributionChannel.swift` của dự án plant-id, gom thành một package dùng chung.

## Cài đặt

```yaml
dependencies:
  lib_app_version:
    path: ../lib_app_version   # hoặc git: { url: ..., path: lib_app_version }
```

Yêu cầu: Flutter ≥ 3.22, Dart ≥ 3.8, iOS 13+, Android minSdk 24.

## Dùng nhanh (3 dòng)

```dart
import 'package:lib_app_version/lib_app_version.dart';

// 1. main.dart – tuỳ chọn. Bỏ qua thì lib tự dùng bundle id / applicationId của app.
//    iosId dạng số giúp có link store ngay cả khi lookup lỗi (khuyên dùng).
AppVersion.init(
  androidId: 'com.plant.identification.care',
  iosId: '6762586391',
);

// 2. Ở trang chính – check và hiện dialog nếu có bản mới.
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppVersion.showUpdateDialogIfNeeded(context, force: true); // force: không cho bỏ qua
  });
}

// 3. Đang chạy TestFlight? (iOS, native, không cần mạng)
final bool isTf = await AppVersion.isTestFlight();
```

## Lấy thông tin chi tiết

```dart
final AppVersionStatus status = await AppVersion.check();

status.localVersion;       // "1.1.4"  – version đang cài
status.buildNumber;        // "12"
status.storeVersion;       // "1.2.0"  – version trên store (null nếu lookup lỗi)
status.isUpdateAvailable;  // store > local
status.isUpToDate;         // store reachable và local >= store
status.isAheadOfStore;     // local > store (internal testing / TestFlight / debug)
status.isTestFlight;       // iOS: cài từ TestFlight (sandbox receipt)
status.isTestBuild;        // isTestFlight || isAheadOfStore – dùng chung 2 nền tảng
status.installSource;      // appStore, testFlight, playStore, sideload, development, simulator, unknown
status.updateType;         // none | optional | required
status.storeUrl;           // link store
status.releaseNotes;       // "What's new" từ store (nếu có)
status.error;              // lỗi lookup (nếu có), app vẫn chạy bình thường

// Shortcut
await AppVersion.isUpdateAvailable();
await AppVersion.getLocalInfo();      // LocalAppInfo(version, buildNumber, packageName, installSource)
await AppVersion.getInstallSource();
await AppVersion.openStore();         // mở app Play Store / App Store, fallback trình duyệt
```

Kết quả store được **cache 30 phút** (gọi `check()` ở splash rồi ở main page chỉ tốn 1 request). Muốn lấy mới: `check(refresh: true)` hoặc `AppVersion.clearCache()`. Nhiều chỗ gọi cùng lúc cũng chỉ tạo 1 request.

## Check TestFlight ("tf")

```dart
// Giống CheckVersionUtils.checkIsTestflight() của plant-id:
//   iOS     -> native: Bundle.main.appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
//   Android -> local version > store version (internal/closed testing)
final AppVersionStatus status = await AppVersion.check();
final bool useTestConfig = status.isTestBuild;

// Chỉ cần iOS, không cần mạng:
final bool isTf = await AppVersion.isTestFlight();
```

Cách nhận biết trên iOS (`installSource`):

| Build | Dấu hiệu | `installSource` |
|---|---|---|
| Simulator | compile-time | `simulator` |
| Xcode / Ad Hoc / Enterprise | có `embedded.mobileprovision` | `development` |
| TestFlight | receipt là `sandboxReceipt` | `testFlight` |
| App Store | receipt là `receipt` | `appStore` |

Trên Android: `com.android.vending` → `playStore` (mọi track, kể cả internal testing), không có installer (`adb install`) → `development`, còn lại → `sideload`. Vì Play không phân biệt track, nên dùng `isAheadOfStore` / `isTestBuild` cho build test trên Android.

Ví dụ chọn remote config cho tester (như `SplashFirebaseRemoteConfigLoader` của plant-id):

```dart
final bool isTestBuild = (await AppVersion.check()).isTestBuild;
final String key = isTestBuild
    ? FirebaseConstants.FBASE_APP_PREMIUM_CONFIG_TESTFLIGHT
    : FirebaseConstants.FBASE_APP_PREMIUM_CONFIG;
```

## Force update theo version tối thiểu (Remote Config)

Update **bắt buộc** khi version đang cài **thấp hơn** `minimumVersion`; dialog sẽ không có nút "Later", không đóng được bằng back / chạm ngoài.

```dart
// Cách 1: truyền khi gọi (ví dụ đọc từ Firebase Remote Config)
final String minVersion = remoteConfig.getString('MIN_SUPPORTED_VERSION'); // "1.2.0"
await AppVersion.showUpdateDialogIfNeeded(context, minimumVersion: minVersion);

// Cách 2: đặt sẵn khi init
AppVersion.init(minimumVersion: '1.2.0');

// Cách 3: tự cung cấp version từ backend / remote config thay vì store
AppVersion.init(
  source: VersionSource.fromCallback((local) async => StoreVersionInfo(
    version: remoteConfig.getString('LATEST_VERSION'),
    minimumVersion: remoteConfig.getString('MIN_SUPPORTED_VERSION'),
  )),
);
```

`force: true` thì đơn giản hơn: *mọi* bản mới đều bắt buộc (cách plant-id đang làm).

## Tuỳ biến dialog

```dart
// Đổi text (đa ngôn ngữ)
await AppVersion.showUpdateDialogIfNeeded(
  context,
  texts: AppUpdateDialogTexts(
    title: S.of(context).app_update_title,
    message: S.of(context).app_update_des,
    updateButton: S.of(context).app_update_button,
    laterButton: S.of(context).later,
  ),
  showReleaseNotes: true,
);

// Hoặc thay hẳn UI bằng widget của bạn
await AppVersion.showUpdateDialogIfNeeded(
  context,
  force: true,
  builder: (context, status, mandatory, openStore) => PopScope(
    canPop: !mandatory,
    child: MyForceUpdateDialog(
      storeVersion: status.storeVersion,
      onUpdate: openStore,          // mở store
    ),
  ),
);

// Hoặc tự gọi showDialog với widget mặc định
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => AppUpdateDialog(status: status, mandatory: true, onUpdate: AppVersion.openStore),
);
```

Dialog mặc định dùng `AlertDialog.adaptive`: Material trên Android, Cupertino trên iOS.

## Thử luồng update khi chưa lên store

```dart
AppVersion.init(forceStoreVersion: '99.0.0'); // giả lập store có bản 99.0.0 – KHÔNG ship
```

## Dùng nhiều instance / test

`AppVersion` chỉ là facade cho một `AppVersionChecker` dùng chung. Có thể tạo instance riêng hoặc thay `AppVersion.instance` trong test:

```dart
AppVersion.instance = AppVersionChecker(
  platform: FakePlatform(),                         // implements LibAppVersionPlatform
  source: const StaticVersionSource(version: '9.9.9'),
);
```

Tham số của `AppVersionChecker` / `AppVersion.init`:

| Tham số | Mặc định | Ý nghĩa |
|---|---|---|
| `androidId` | applicationId | id trên Play Store |
| `iosId` | bundle id | App Store id dạng số (khuyên dùng) hoặc bundle id |
| `iosCountry` | `null` (US) | storefront 2 ký tự: `vn`, `us`... nếu app không có ở US |
| `androidLocale` | `en_US` | tham số `hl` của Play Store |
| `minimumVersion` | `null` | dưới version này → update bắt buộc |
| `forceStoreVersion` | `null` | giả lập version store (dev only) |
| `cacheDuration` | 30 phút | thời gian cache kết quả store |
| `timeout` | 10 giây | timeout request |
| `source` | App Store / Play Store | nguồn version tuỳ chỉnh (`VersionSource`) |
| `platform` | method channel | bridge native (thay trong test) |
| `httpGet` | `dart:io` | hàm GET tuỳ chỉnh (mock trong test) |

## Cách hoạt động & lưu ý

- **iOS**: gọi iTunes Lookup API (`https://itunes.apple.com/lookup?id=...` hoặc `bundleId=...`). App mới lên store có thể mất vài giờ mới xuất hiện ở API này.
- **Android**: Google không có API chính thức, lib đọc trang Play Store và tìm chuỗi version (cùng cách `new_version_plus`). Nếu Google đổi layout, `check()` trả `error`, app không bị ảnh hưởng. Nếu cần chắc chắn 100%, dùng `VersionSource.fromCallback` với remote config / backend của bạn.
- So sánh version chỉ dựa trên phần số (`1.2.3`, `1.2`, `1.2.3.4`); `1.2 == 1.2.0`; bỏ qua `-beta`, `+build`.
- Mở store: Android thử `market://` rồi `https://play.google.com/...`; iOS thử `itms-apps://` rồi `https://apps.apple.com/...`.
- Web / desktop: `check()` trả `error`, `isTestFlight()` trả `false`; không crash.

## Migrate từ plant-id

| Cũ | Mới |
|---|---|
| `CheckVersionUtils.instance.checkIsUpdateAvailable()` | `AppVersion.isUpdateAvailable()` |
| `CheckVersionUtils.instance.checkIsTestflight()` | `AppVersion.isTestFlight()` (iOS) hoặc `(await AppVersion.check()).isTestBuild` (cả 2 nền tảng) |
| `DialogBuilder(context).showDialogUpdate(context)` + `ForceUpdateDialog` | `AppVersion.showUpdateDialogIfNeeded(context, force: true, texts: ...)` hoặc giữ `ForceUpdateDialog` qua `builder:` |
| `ForceUpdateDialog._openStore()` | `AppVersion.openStore()` |
| `AppDistributionChannel.swift` + đăng ký trong `AppDelegate` | xoá, plugin tự đăng ký |
| `new_version_plus`, `version` trong pubspec | bỏ được |

## Chạy example

```bash
cd example && flutter run
```

Trong example có switch "Simulate a newer store version" để xem dialog mà không cần publish app.
