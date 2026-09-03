import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext, showDialog;

import 'http/simple_http.dart';
import 'models/app_install_source.dart';
import 'models/app_update_status.dart';
import 'models/local_app_info.dart';
import 'models/store_version_info.dart';
import 'models/version_number.dart';
import 'platform/app_update_check_platform.dart';
import 'sources/store_version_source.dart';
import 'sources/version_source.dart';
import 'store_urls.dart';
import 'ui/app_update_dialog.dart';

/// Checks the installed version against the store, detects TestFlight builds
/// and opens the store listing.
///
/// Most apps only need the static [AppUpdate] facade, which wraps a single
/// shared instance of this class. Create your own instance when you want
/// several configurations or full control in tests.
///
/// Every method is safe to call: nothing throws on network errors, the result
/// simply reports no update (see [AppUpdateStatus.error]).
class AppUpdateChecker {
  AppUpdateChecker({
    this.androidId,
    this.iosId,
    this.iosCountry,
    this.androidLocale = 'en_US',
    this.minimumVersion,
    this.forceStoreVersion,
    this.cacheDuration = const Duration(minutes: 30),
    this.timeout = const Duration(seconds: 10),
    VersionSource? source,
    AppUpdateCheckPlatform? platform,
    HttpGet? httpGet,
  }) : _platform = platform ?? const MethodChannelAppUpdateCheck(),
       _source =
           source ??
           StoreVersionSource(
             androidId: androidId,
             iosId: iosId,
             iosCountry: iosCountry,
             androidLocale: androidLocale,
             timeout: timeout,
             httpGet: httpGet ?? defaultHttpGet,
           );

  /// Play Store application id. Defaults to the running app's id.
  final String? androidId;

  /// Numeric App Store id (recommended, gives a store link even offline) or
  /// bundle id. Defaults to the running app's bundle id.
  final String? iosId;

  /// Two-letter App Store storefront (`us`, `vn`, ...).
  final String? iosCountry;

  /// Play Store `hl` parameter.
  final String androidLocale;

  /// Versions below this one are reported as [AppUpdateType.required].
  final String? minimumVersion;

  /// Pretend the store has this version. Only for trying the update flow out
  /// during development; never ship it.
  final String? forceStoreVersion;

  /// How long a store answer is reused before hitting the network again.
  final Duration cacheDuration;

  /// Network timeout for store lookups.
  final Duration timeout;

  final AppUpdateCheckPlatform _platform;
  final VersionSource _source;

  LocalAppInfo? _local;
  Future<LocalAppInfo>? _localFuture;
  StoreVersionInfo? _store;
  DateTime? _storeFetchedAt;
  Future<StoreVersionInfo?>? _storeFuture;
  bool _dialogVisible = false;

  // ---------------------------------------------------------------------------
  // Local build
  // ---------------------------------------------------------------------------

  /// Version, build number, package name and install source of this build.
  /// Read once from native code and cached for the lifetime of the checker.
  Future<LocalAppInfo> getLocalInfo() {
    final LocalAppInfo? cached = _local;
    if (cached != null) return Future<LocalAppInfo>.value(cached);
    return _localFuture ??= _platform
        .getAppInfo()
        .then((LocalAppInfo info) {
          _local = info;
          return info;
        })
        .whenComplete(() => _localFuture = null);
  }

  /// Where this build was installed from. [AppInstallSource.unknown] when the
  /// platform could not be queried.
  Future<AppInstallSource> getInstallSource() async {
    try {
      return (await getLocalInfo()).installSource;
    } catch (_) {
      return AppInstallSource.unknown;
    }
  }

  /// `true` when running from TestFlight. iOS only, no network needed;
  /// always `false` on Android. For a cross-platform "is this a test build?"
  /// answer use `(await check()).isTestBuild`.
  Future<bool> isTestFlight() async =>
      (await getInstallSource()) == AppInstallSource.testFlight;

  // ---------------------------------------------------------------------------
  // Store
  // ---------------------------------------------------------------------------

  /// Compares the installed version with the store.
  ///
  /// The store answer is cached for [cacheDuration]; pass [refresh] to force a
  /// new lookup. [minimumVersion] overrides the checker-level value for this
  /// call (handy when it comes from remote config).
  Future<AppUpdateStatus> check({
    bool refresh = false,
    String? minimumVersion,
  }) async {
    LocalAppInfo local;
    Object? error;
    try {
      local = await getLocalInfo();
    } catch (e) {
      local = LocalAppInfo.unknown;
      error = e;
    }

    StoreVersionInfo? store;
    if (error == null) {
      try {
        store = await _fetchStore(local, refresh: refresh);
      } catch (e) {
        error = e;
      }
    }

    final String? forced = forceStoreVersion;
    if (forced != null && forced.isNotEmpty) {
      store = (store ?? const StoreVersionInfo(version: '0')).copyWith(
        version: forced,
      );
    }

    return AppUpdateStatus(
      local: local,
      store: store,
      minimumVersion: VersionNumber.tryParse(
        minimumVersion ?? this.minimumVersion ?? store?.minimumVersion,
      ),
      storeUrl: resolveStoreUrl(local, store),
      error: error,
      checkedAt: DateTime.now(),
    );
  }

  /// Shortcut for `(await check()).isUpdateAvailable`.
  Future<bool> isUpdateAvailable({bool refresh = false}) async =>
      (await check(refresh: refresh)).isUpdateAvailable;

  /// Forgets cached store data so the next [check] hits the network.
  void clearCache() {
    _store = null;
    _storeFetchedAt = null;
  }

  Future<StoreVersionInfo?> _fetchStore(
    LocalAppInfo local, {
    required bool refresh,
  }) {
    final StoreVersionInfo? cached = _store;
    final DateTime? fetchedAt = _storeFetchedAt;
    if (!refresh &&
        cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < cacheDuration) {
      return Future<StoreVersionInfo?>.value(cached);
    }
    // Concurrent callers share one in-flight request.
    return _storeFuture ??= _source
        .fetch(local)
        .then((StoreVersionInfo? info) {
          _store = info;
          _storeFetchedAt = info == null ? null : DateTime.now();
          return info;
        })
        .whenComplete(() => _storeFuture = null);
  }

  /// Store listing link for [local]: the source's URL when it has one,
  /// otherwise a platform default built from [androidId] / [iosId].
  String? resolveStoreUrl(LocalAppInfo local, StoreVersionInfo? store) {
    final String? fromSource = store?.storeUrl;
    if (fromSource != null && fromSource.isNotEmpty) return fromSource;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final String id = androidId ?? local.packageName;
        return id.isEmpty ? null : StoreUrls.playStore(id);
      case TargetPlatform.iOS:
        return StoreUrls.appStore(iosId);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Opening the store
  // ---------------------------------------------------------------------------

  /// Opens the app's store listing (Play Store app / App Store app, falling
  /// back to the browser). Returns `false` when no link could be opened.
  Future<bool> openStore() async {
    LocalAppInfo local;
    try {
      local = await getLocalInfo();
    } catch (_) {
      local = LocalAppInfo.unknown;
    }
    String? url = resolveStoreUrl(local, _store);
    // iOS without a numeric id: the link only comes from a lookup.
    url ??= (await check()).storeUrl;
    if (url == null || url.isEmpty) return false;
    return openStoreUrl(url, local: local);
  }

  /// Opens [url], trying the store app first (`market://` on Android,
  /// `itms-apps://` on iOS) and the plain link second.
  Future<bool> openStoreUrl(String url, {LocalAppInfo? local}) async {
    final List<String> candidates = <String>[];
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final String id = androidId ?? local?.packageName ?? '';
        if (id.isNotEmpty) candidates.add(StoreUrls.playStoreMarket(id));
      case TargetPlatform.iOS:
        if (url.startsWith('http')) {
          candidates.add(StoreUrls.appStoreDeepLink(url));
        }
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        break;
    }
    candidates.add(url);
    for (final String candidate in candidates) {
      try {
        if (await _platform.openUrl(candidate)) return true;
      } catch (_) {
        // Try the next candidate.
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Dialog
  // ---------------------------------------------------------------------------

  /// Runs [check] and shows an update dialog when an update exists.
  ///
  /// * [force]: treat any available update as mandatory (no "Later" button,
  ///   not dismissible). Updates below [minimumVersion] are always mandatory.
  /// * [texts]: localized strings for the default dialog.
  /// * [builder]: replace the default dialog with your own widget.
  /// * [showReleaseNotes]: append the store's "what's new" to the default
  ///   dialog.
  ///
  /// Returns the status so callers can log it. Never throws.
  Future<AppUpdateStatus> showUpdateDialogIfNeeded(
    BuildContext context, {
    bool force = false,
    String? minimumVersion,
    bool refresh = false,
    AppUpdateDialogTexts texts = const AppUpdateDialogTexts(),
    AppUpdateDialogBuilder? builder,
    bool showReleaseNotes = false,
    bool useRootNavigator = true,
  }) async {
    final AppUpdateStatus status = await check(
      refresh: refresh,
      minimumVersion: minimumVersion,
    );
    if (!status.shouldUpdate || _dialogVisible || !context.mounted) {
      return status;
    }
    final bool mandatory = force || status.isUpdateRequired;
    _dialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !mandatory,
        useRootNavigator: useRootNavigator,
        builder: (BuildContext dialogContext) {
          if (builder != null) {
            return builder(dialogContext, status, mandatory, openStore);
          }
          return AppUpdateDialog(
            status: status,
            mandatory: mandatory,
            texts: texts,
            showReleaseNotes: showReleaseNotes,
            onUpdate: openStore,
          );
        },
      );
    } finally {
      _dialogVisible = false;
    }
    return status;
  }
}
