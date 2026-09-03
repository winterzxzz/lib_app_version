import 'package:flutter/foundation.dart';

import 'app_install_source.dart';
import 'version_number.dart';

/// Information about the build that is currently running.
@immutable
class LocalAppInfo {
  const LocalAppInfo({
    required this.version,
    this.buildNumber = '',
    this.packageName = '',
    this.installSource = AppInstallSource.unknown,
    this.installerPackage,
  });

  /// Reads the map returned by the native `getAppInfo` call.
  factory LocalAppInfo.fromMap(Map<Object?, Object?> map) {
    return LocalAppInfo(
      version: (map['version'] ?? '').toString(),
      buildNumber: (map['buildNumber'] ?? '').toString(),
      packageName: (map['packageName'] ?? '').toString(),
      installSource: AppInstallSource.fromRawValue(
        map['installSource']?.toString(),
      ),
      installerPackage: map['installerPackage']?.toString(),
    );
  }

  /// Placeholder used when the platform could not be queried.
  static const LocalAppInfo unknown = LocalAppInfo(version: '0.0.0');

  /// Marketing version: `CFBundleShortVersionString` / `versionName`.
  final String version;

  /// Build number: `CFBundleVersion` / `versionCode`.
  final String buildNumber;

  /// Bundle identifier (iOS) or application id (Android).
  final String packageName;

  /// Where this build was installed from.
  final AppInstallSource installSource;

  /// Android only: the raw installer package name (e.g. `com.android.vending`).
  final String? installerPackage;

  /// [version] parsed for comparisons; falls back to `0` if unparsable.
  VersionNumber get versionNumber =>
      VersionNumber.tryParse(version) ?? VersionNumber.zero;

  /// `true` when running from TestFlight.
  bool get isTestFlight => installSource.isTestFlight;

  Map<String, Object?> toMap() => <String, Object?>{
    'version': version,
    'buildNumber': buildNumber,
    'packageName': packageName,
    'installSource': installSource.rawValue,
    'installerPackage': installerPackage,
  };

  @override
  bool operator ==(Object other) =>
      other is LocalAppInfo &&
      other.version == version &&
      other.buildNumber == buildNumber &&
      other.packageName == packageName &&
      other.installSource == installSource &&
      other.installerPackage == installerPackage;

  @override
  int get hashCode => Object.hash(
    version,
    buildNumber,
    packageName,
    installSource,
    installerPackage,
  );

  @override
  String toString() =>
      'LocalAppInfo(version: $version, build: $buildNumber, '
      'package: $packageName, installSource: ${installSource.name})';
}
