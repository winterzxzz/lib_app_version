import 'package:flutter/widgets.dart';

import 'app_version_checker.dart';
import 'http/simple_http.dart';
import 'models/app_install_source.dart';
import 'models/app_version_status.dart';
import 'models/local_app_info.dart';
import 'platform/lib_app_version_platform.dart';
import 'sources/version_source.dart';
import 'ui/app_update_dialog.dart';

/// One-liner access to a shared [AppVersionChecker].
///
/// ```dart
/// // main.dart (optional; defaults to the app's own ids)
/// AppVersion.init(iosId: '6762586391');
///
/// // anywhere
/// await AppVersion.showUpdateDialogIfNeeded(context);
/// final bool testFlight = await AppVersion.isTestFlight();
/// ```
abstract final class AppVersion {
  /// The shared checker. Assign your own (for example in tests).
  static AppVersionChecker instance = AppVersionChecker();

  /// Configures the shared checker. Optional, synchronous, call it once
  /// before the first check (for example in `main`). See
  /// [AppVersionChecker.new] for the parameters.
  static void init({
    String? androidId,
    String? iosId,
    String? iosCountry,
    String androidLocale = 'en_US',
    String? minimumVersion,
    String? forceStoreVersion,
    Duration cacheDuration = const Duration(minutes: 30),
    Duration timeout = const Duration(seconds: 10),
    VersionSource? source,
    LibAppVersionPlatform? platform,
    HttpGet? httpGet,
  }) {
    instance = AppVersionChecker(
      androidId: androidId,
      iosId: iosId,
      iosCountry: iosCountry,
      androidLocale: androidLocale,
      minimumVersion: minimumVersion,
      forceStoreVersion: forceStoreVersion,
      cacheDuration: cacheDuration,
      timeout: timeout,
      source: source,
      platform: platform,
      httpGet: httpGet,
    );
  }

  /// See [AppVersionChecker.getLocalInfo].
  static Future<LocalAppInfo> getLocalInfo() => instance.getLocalInfo();

  /// See [AppVersionChecker.getInstallSource].
  static Future<AppInstallSource> getInstallSource() =>
      instance.getInstallSource();

  /// See [AppVersionChecker.isTestFlight].
  static Future<bool> isTestFlight() => instance.isTestFlight();

  /// See [AppVersionChecker.check].
  static Future<AppVersionStatus> check({
    bool refresh = false,
    String? minimumVersion,
  }) => instance.check(refresh: refresh, minimumVersion: minimumVersion);

  /// See [AppVersionChecker.isUpdateAvailable].
  static Future<bool> isUpdateAvailable({bool refresh = false}) =>
      instance.isUpdateAvailable(refresh: refresh);

  /// See [AppVersionChecker.openStore].
  static Future<bool> openStore() => instance.openStore();

  /// See [AppVersionChecker.showUpdateDialogIfNeeded].
  static Future<AppVersionStatus> showUpdateDialogIfNeeded(
    BuildContext context, {
    bool force = false,
    String? minimumVersion,
    bool refresh = false,
    AppUpdateDialogTexts texts = const AppUpdateDialogTexts(),
    AppUpdateDialogBuilder? builder,
    bool showReleaseNotes = false,
    bool useRootNavigator = true,
  }) => instance.showUpdateDialogIfNeeded(
    context,
    force: force,
    minimumVersion: minimumVersion,
    refresh: refresh,
    texts: texts,
    builder: builder,
    showReleaseNotes: showReleaseNotes,
    useRootNavigator: useRootNavigator,
  );

  /// See [AppVersionChecker.clearCache].
  static void clearCache() => instance.clearCache();
}
