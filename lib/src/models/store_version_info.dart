import 'package:flutter/foundation.dart';

import 'version_number.dart';

/// What a [VersionSource] knows about the version published in the store
/// (or in your own backend / remote config).
@immutable
class StoreVersionInfo {
  const StoreVersionInfo({
    required this.version,
    this.storeUrl,
    this.releaseNotes,
    this.minimumVersion,
    this.releaseDate,
  });

  /// Latest published version, e.g. `1.4.0`.
  final String version;

  /// Link to the store listing. Optional: a platform default is used when
  /// absent.
  final String? storeUrl;

  /// "What's new" text, when the source provides one.
  final String? releaseNotes;

  /// Oldest version that is still allowed to run. Anything below it is a
  /// *required* update. Only custom sources (remote config, own API) usually
  /// provide this.
  final String? minimumVersion;

  /// When [version] was released, when known.
  final DateTime? releaseDate;

  VersionNumber? get versionNumber => VersionNumber.tryParse(version);

  VersionNumber? get minimumVersionNumber =>
      VersionNumber.tryParse(minimumVersion);

  StoreVersionInfo copyWith({
    String? version,
    String? storeUrl,
    String? releaseNotes,
    String? minimumVersion,
    DateTime? releaseDate,
  }) {
    return StoreVersionInfo(
      version: version ?? this.version,
      storeUrl: storeUrl ?? this.storeUrl,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      minimumVersion: minimumVersion ?? this.minimumVersion,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StoreVersionInfo &&
      other.version == version &&
      other.storeUrl == storeUrl &&
      other.releaseNotes == releaseNotes &&
      other.minimumVersion == minimumVersion &&
      other.releaseDate == releaseDate;

  @override
  int get hashCode =>
      Object.hash(version, storeUrl, releaseNotes, minimumVersion, releaseDate);

  @override
  String toString() =>
      'StoreVersionInfo(version: $version, minimumVersion: $minimumVersion, '
      'storeUrl: $storeUrl)';
}
