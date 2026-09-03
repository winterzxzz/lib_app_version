/// Check whether a newer version of your app is on the App Store / Play Store,
/// detect TestFlight builds and show an update dialog, with no extra
/// dependencies and no native setup.
///
/// Quick start:
///
/// ```dart
/// AppVersion.init(iosId: '6762586391');            // optional
/// await AppVersion.showUpdateDialogIfNeeded(context);
/// ```
library;

export 'src/app_version.dart';
export 'src/app_version_checker.dart';
export 'src/errors.dart';
export 'src/http/simple_http.dart'
    show HttpGet, HttpTextResponse, defaultHttpGet;
export 'src/models/app_install_source.dart';
export 'src/models/app_version_status.dart';
export 'src/models/local_app_info.dart';
export 'src/models/store_version_info.dart';
export 'src/models/version_number.dart';
export 'src/platform/lib_app_version_platform.dart';
export 'src/sources/app_store_version_source.dart';
export 'src/sources/play_store_version_source.dart';
export 'src/sources/store_version_source.dart';
export 'src/sources/version_source.dart';
export 'src/store_urls.dart';
export 'src/ui/app_update_dialog.dart';
