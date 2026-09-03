import '../models/local_app_info.dart';
import '../models/store_version_info.dart';

/// Where the "latest version" comes from.
///
/// The package ships with [StoreVersionSource] (App Store / Play Store),
/// [StaticVersionSource] (tests) and [CallbackVersionSource] (remote config,
/// your own API). Implement this class for anything else.
abstract class VersionSource {
  const VersionSource();

  /// Builds a source from a plain function. Handy for Firebase Remote Config:
  ///
  /// ```dart
  /// VersionSource.fromCallback((local) async => StoreVersionInfo(
  ///   version: remoteConfig.getString('latest_version'),
  ///   minimumVersion: remoteConfig.getString('min_version'),
  /// ));
  /// ```
  const factory VersionSource.fromCallback(
    Future<StoreVersionInfo?> Function(LocalAppInfo local) fetch,
  ) = CallbackVersionSource;

  /// Returns the published version info, `null` when the app is not listed,
  /// or throws (any error) when the lookup fails.
  Future<StoreVersionInfo?> fetch(LocalAppInfo local);
}

/// A [VersionSource] backed by a function.
class CallbackVersionSource extends VersionSource {
  const CallbackVersionSource(this._fetch);

  final Future<StoreVersionInfo?> Function(LocalAppInfo local) _fetch;

  @override
  Future<StoreVersionInfo?> fetch(LocalAppInfo local) => _fetch(local);
}

/// A [VersionSource] that always returns the same info. Useful in tests and
/// when you already know the latest version.
class StaticVersionSource extends VersionSource {
  const StaticVersionSource({
    required this.version,
    this.storeUrl,
    this.releaseNotes,
    this.minimumVersion,
  });

  final String version;
  final String? storeUrl;
  final String? releaseNotes;
  final String? minimumVersion;

  @override
  Future<StoreVersionInfo?> fetch(LocalAppInfo local) async {
    return StoreVersionInfo(
      version: version,
      storeUrl: storeUrl,
      releaseNotes: releaseNotes,
      minimumVersion: minimumVersion,
    );
  }
}
