import 'package:flutter_test/flutter_test.dart';
import 'package:app_update_check/app_update_check.dart';

void main() {
  AppUpdateStatus status({
    String local = '1.2.0',
    String? store,
    String? minimum,
    AppInstallSource source = AppInstallSource.appStore,
    Object? error,
  }) {
    return AppUpdateStatus(
      local: LocalAppInfo(version: local, installSource: source),
      store: store == null ? null : StoreVersionInfo(version: store),
      minimumVersion: VersionNumber.tryParse(minimum),
      error: error,
      checkedAt: DateTime(2026),
    );
  }

  test('update available when store is newer', () {
    final AppUpdateStatus s = status(store: '1.3.0');
    expect(s.isUpdateAvailable, isTrue);
    expect(s.isUpToDate, isFalse);
    expect(s.isAheadOfStore, isFalse);
    expect(s.updateType, AppUpdateType.optional);
    expect(s.shouldUpdate, isTrue);
  });

  test('up to date when versions match', () {
    final AppUpdateStatus s = status(store: '1.2');
    expect(s.isUpdateAvailable, isFalse);
    expect(s.isUpToDate, isTrue);
    expect(s.updateType, AppUpdateType.none);
    expect(s.shouldUpdate, isFalse);
  });

  test('ahead of store marks a test build', () {
    final AppUpdateStatus s = status(local: '1.3.0', store: '1.2.0');
    expect(s.isAheadOfStore, isTrue);
    expect(s.isTestBuild, isTrue);
    expect(s.isTestFlight, isFalse);
    expect(s.isUpdateAvailable, isFalse);
  });

  test('TestFlight install source', () {
    final AppUpdateStatus s = status(
      store: '1.2.0',
      source: AppInstallSource.testFlight,
    );
    expect(s.isTestFlight, isTrue);
    expect(s.isTestBuild, isTrue);
    expect(s.installSource.isStore, isFalse);
  });

  test('minimum version makes the update required', () {
    final AppUpdateStatus s = status(store: '1.3.0', minimum: '1.2.1');
    expect(s.isUpdateRequired, isTrue);
    expect(s.updateType, AppUpdateType.required);
  });

  test('minimum version below local does not require', () {
    final AppUpdateStatus s = status(store: '1.3.0', minimum: '1.0.0');
    expect(s.isUpdateRequired, isFalse);
    expect(s.updateType, AppUpdateType.optional);
  });

  test('required even when the store lookup failed', () {
    final AppUpdateStatus s = status(
      minimum: '2.0.0',
      error: const AppUpdateException('down'),
    );
    expect(s.hasStoreVersion, isFalse);
    expect(s.hasError, isTrue);
    expect(s.isUpdateAvailable, isFalse);
    expect(s.updateType, AppUpdateType.required);
  });

  test('no store info means no update', () {
    final AppUpdateStatus s = status(error: 'boom');
    expect(s.hasStoreVersion, isFalse);
    expect(s.isUpdateAvailable, isFalse);
    expect(s.isUpToDate, isFalse);
    expect(s.updateType, AppUpdateType.none);
    expect(s.toString(), contains('error: boom'));
  });

  test('AppInstallSource parses raw values', () {
    expect(
      AppInstallSource.fromRawValue('testflight'),
      AppInstallSource.testFlight,
    );
    expect(
      AppInstallSource.fromRawValue('playstore'),
      AppInstallSource.playStore,
    );
    expect(AppInstallSource.fromRawValue('nope'), AppInstallSource.unknown);
    expect(AppInstallSource.fromRawValue(null), AppInstallSource.unknown);
  });

  test('LocalAppInfo round-trips through a map', () {
    const LocalAppInfo info = LocalAppInfo(
      version: '1.0.0',
      buildNumber: '3',
      packageName: 'com.x',
      installSource: AppInstallSource.sideload,
      installerPackage: 'com.google.android.packageinstaller',
    );
    expect(LocalAppInfo.fromMap(info.toMap()), info);
    expect(
      LocalAppInfo.fromMap(<Object?, Object?>{'buildNumber': 7}).buildNumber,
      '7',
    );
    expect(
      LocalAppInfo.fromMap(const <Object?, Object?>{}).versionNumber,
      VersionNumber.zero,
    );
  });
}
