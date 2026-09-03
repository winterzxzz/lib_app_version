import 'package:flutter/foundation.dart';

import 'app_install_source.dart';
import 'local_app_info.dart';
import 'store_version_info.dart';
import 'version_number.dart';

/// Kind of update the user should be offered.
enum AppUpdateType {
  /// Local version is up to date (or the store could not be reached).
  none,

  /// A newer version exists; the user may skip it.
  optional,

  /// Local version is below the minimum allowed version; block the app until
  /// the user updates.
  required,
}

/// Result of [AppVersionChecker.check]: local build info, store info, and all
/// the derived flags you typically need.
@immutable
class AppVersionStatus {
  const AppVersionStatus({
    required this.local,
    required this.checkedAt,
    this.store,
    this.minimumVersion,
    this.storeUrl,
    this.error,
  });

  /// The running build.
  final LocalAppInfo local;

  /// Store data, or `null` when the lookup failed / app not found.
  final StoreVersionInfo? store;

  /// Effective minimum allowed version (from the check call, the checker
  /// configuration, or the source), when any.
  final VersionNumber? minimumVersion;

  /// Store listing URL, when it could be determined.
  final String? storeUrl;

  /// The error raised while looking up the store, if any. [isUpdateAvailable]
  /// is simply `false` in that case; nothing is thrown.
  final Object? error;

  /// When this status was produced.
  final DateTime checkedAt;

  // ---------------------------------------------------------------------------
  // Shortcuts
  // ---------------------------------------------------------------------------

  /// Installed marketing version, e.g. `1.1.4`.
  String get localVersion => local.version;

  /// Installed build number, e.g. `12`.
  String get buildNumber => local.buildNumber;

  /// Version published in the store, e.g. `1.2.0`, or `null` if unknown.
  String? get storeVersion => store?.version;

  /// Store release notes when the source provides them.
  String? get releaseNotes => store?.releaseNotes;

  AppInstallSource get installSource => local.installSource;

  VersionNumber get localVersionNumber => local.versionNumber;

  VersionNumber? get storeVersionNumber => store?.versionNumber;

  // ---------------------------------------------------------------------------
  // Flags
  // ---------------------------------------------------------------------------

  /// Whether the store lookup produced a comparable version.
  bool get hasStoreVersion => storeVersionNumber != null;

  /// Store version is newer than the installed one.
  bool get isUpdateAvailable {
    final VersionNumber? remote = storeVersionNumber;
    return remote != null && remote > localVersionNumber;
  }

  /// Installed version is below [minimumVersion] (force-update case).
  bool get isUpdateRequired {
    final VersionNumber? minimum = minimumVersion;
    return minimum != null && localVersionNumber < minimum;
  }

  /// Installed version is *newer* than the store one. Typical for TestFlight,
  /// Play internal-testing tracks and local debug builds.
  bool get isAheadOfStore {
    final VersionNumber? remote = storeVersionNumber;
    return remote != null && localVersionNumber > remote;
  }

  /// Store reachable and nothing newer available.
  bool get isUpToDate => hasStoreVersion && !isUpdateAvailable;

  /// Running from TestFlight (iOS only; always `false` on Android).
  bool get isTestFlight => local.isTestFlight;

  /// Running a pre-release build: TestFlight, or a build newer than the store
  /// listing (works on Android too).
  bool get isTestBuild => isTestFlight || isAheadOfStore;

  /// The store lookup failed. See [error].
  bool get hasError => error != null;

  /// [AppUpdateType.required] when below the minimum version,
  /// [AppUpdateType.optional] when a newer version exists, otherwise
  /// [AppUpdateType.none].
  AppUpdateType get updateType {
    if (isUpdateRequired) return AppUpdateType.required;
    if (isUpdateAvailable) return AppUpdateType.optional;
    return AppUpdateType.none;
  }

  /// Any update (optional or required) should be offered.
  bool get shouldUpdate => updateType != AppUpdateType.none;

  AppVersionStatus copyWith({
    LocalAppInfo? local,
    StoreVersionInfo? store,
    VersionNumber? minimumVersion,
    String? storeUrl,
    Object? error,
    DateTime? checkedAt,
  }) {
    return AppVersionStatus(
      local: local ?? this.local,
      store: store ?? this.store,
      minimumVersion: minimumVersion ?? this.minimumVersion,
      storeUrl: storeUrl ?? this.storeUrl,
      error: error ?? this.error,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  String toString() =>
      'AppVersionStatus(local: $localVersion+$buildNumber, '
      'store: ${storeVersion ?? '-'}, minimum: ${minimumVersion ?? '-'}, '
      'updateType: ${updateType.name}, installSource: ${installSource.name}'
      '${error != null ? ', error: $error' : ''})';
}
