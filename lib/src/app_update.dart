import 'package:flutter/widgets.dart';

import 'app_update_checker.dart';
import 'http/simple_http.dart';
import 'models/app_install_source.dart';
import 'models/app_update_status.dart';
import 'models/local_app_info.dart';
import 'platform/app_update_check_platform.dart';
import 'sources/version_source.dart';
import 'ui/app_update_dialog.dart';

/// One-liner access to a shared [AppUpdateChecker].
///
/// ```dart
/// // main.dart (optional; defaults to the app's own ids)
/// AppUpdate.init(iosId: '6762586391');
///
/// // anywhere
/// await AppUpdate.showUpdateDialogIfNeeded(context);
/// final bool testFlight = await AppUpdate.isTestFlight();
/// ```
abstract final class AppUpdate {
  /// The shared checker. Assign your own (for example in tests).
  static AppUpdateChecker instance = AppUpdateChecker();

  /// Configures the shared checker. Optional, synchronous, call it once
  /// before the first check (for example in `main`). See
  /// [AppUpdateChecker.new] for the parameters.
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
    AppUpdateCheckPlatform? platform,
    HttpGet? httpGet,
  }) {
    instance = AppUpdateChecker(
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

  /// See [AppUpdateChecker.getLocalInfo].
  static Future<LocalAppInfo> getLocalInfo() => instance.getLocalInfo();

  /// See [AppUpdateChecker.getInstallSource].
  static Future<AppInstallSource> getInstallSource() =>
      instance.getInstallSource();

  /// See [AppUpdateChecker.isTestFlight].
  static Future<bool> isTestFlight() => instance.isTestFlight();

  /// See [AppUpdateChecker.check].
  static Future<AppUpdateStatus> check({
    bool refresh = false,
    String? minimumVersion,
  }) => instance.check(refresh: refresh, minimumVersion: minimumVersion);

  /// See [AppUpdateChecker.isUpdateAvailable].
  static Future<bool> isUpdateAvailable({bool refresh = false}) =>
      instance.isUpdateAvailable(refresh: refresh);

  /// See [AppUpdateChecker.openStore].
  static Future<bool> openStore() => instance.openStore();

  /// See [AppUpdateChecker.showUpdateDialogIfNeeded].
  static Future<AppUpdateStatus> showUpdateDialogIfNeeded(
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

  /// See [AppUpdateChecker.clearCache].
  static void clearCache() => instance.clearCache();
}
