import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_app_version/lib_app_version.dart';

import 'helpers.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('check', () {
    test('reports an available update and a Play Store link', () async {
      final AppVersionChecker checker = AppVersionChecker(
        platform: FakePlatform(),
        source: const StaticVersionSource(version: '1.3.0'),
      );
      final AppVersionStatus status = await checker.check();
      expect(status.isUpdateAvailable, isTrue);
      expect(status.localVersion, '1.2.0');
      expect(status.storeVersion, '1.3.0');
      expect(
        status.storeUrl,
        'https://play.google.com/store/apps/details?id=com.example.app',
      );
      expect(status.error, isNull);
    });

    test('androidId overrides the package name in the link', () async {
      final AppVersionChecker checker = AppVersionChecker(
        androidId: 'com.other.app',
        platform: FakePlatform(),
        source: const StaticVersionSource(version: '1.0.0'),
      );
      expect((await checker.check()).storeUrl, contains('id=com.other.app'));
    });

    test('iOS link comes from a numeric iosId', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final AppVersionChecker checker = AppVersionChecker(
        iosId: '6762586391',
        platform: FakePlatform(info: iosInfo),
        source: const StaticVersionSource(version: '1.0.0'),
      );
      expect(
        (await checker.check()).storeUrl,
        'https://apps.apple.com/app/id6762586391',
      );
    });

    test('iOS link prefers the source URL, and is null without any', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final AppVersionChecker withUrl = AppVersionChecker(
        iosId: '123',
        platform: FakePlatform(info: iosInfo),
        source: const StaticVersionSource(
          version: '1.0.0',
          storeUrl: 'https://apps.apple.com/vn/app/x/id123',
        ),
      );
      expect(
        (await withUrl.check()).storeUrl,
        'https://apps.apple.com/vn/app/x/id123',
      );

      final AppVersionChecker withoutUrl = AppVersionChecker(
        platform: FakePlatform(info: iosInfo),
        source: const StaticVersionSource(version: '1.0.0'),
      );
      expect((await withoutUrl.check()).storeUrl, isNull);
    });

    test('caches the store answer for cacheDuration', () async {
      final CountingSource source = CountingSource(
        info: const StoreVersionInfo(version: '1.0.0'),
      );
      final AppVersionChecker checker = AppVersionChecker(
        platform: FakePlatform(),
        source: source,
      );
      await checker.check();
      await checker.check();
      expect(source.calls, 1);
      await checker.check(refresh: true);
      expect(source.calls, 2);
      checker.clearCache();
      await checker.check();
      expect(source.calls, 3);
    });

    test('does not cache with a zero cacheDuration', () async {
      final CountingSource source = CountingSource(
        info: const StoreVersionInfo(version: '1.0.0'),
      );
      final AppVersionChecker checker = AppVersionChecker(
        platform: FakePlatform(),
        source: source,
        cacheDuration: Duration.zero,
      );
      await checker.check();
      await checker.check();
      expect(source.calls, 2);
    });

    test('concurrent checks share one request', () async {
      final CountingSource source = CountingSource()
        ..completer = Completer<StoreVersionInfo?>();
      final AppVersionChecker checker = AppVersionChecker(
        platform: FakePlatform(),
        source: source,
      );
      final Future<AppVersionStatus> first = checker.check();
      final Future<AppVersionStatus> second = checker.check();
      source.completer!.complete(const StoreVersionInfo(version: '2.0.0'));
      final List<AppVersionStatus> results = await Future.wait(
        <Future<AppVersionStatus>>[first, second],
      );
      expect(source.calls, 1);
      expect(
        results.every((AppVersionStatus s) => s.isUpdateAvailable),
        isTrue,
      );
    });

    test('captures lookup errors instead of throwing', () async {
      final CountingSource source = CountingSource(
        error: const AppVersionException('offline'),
      );
      final AppVersionChecker checker = AppVersionChecker(
        platform: FakePlatform(),
        source: source,
      );
      final AppVersionStatus status = await checker.check();
      expect(status.hasError, isTrue);
      expect(status.error, isA<AppVersionException>());
      expect(status.isUpdateAvailable, isFalse);
      expect(status.storeUrl, contains('play.google.com'));
      // Errors are not cached: the next call retries.
      await checker.check();
      expect(source.calls, 2);
    });

    test('captures platform errors', () async {
      final AppVersionChecker checker = AppVersionChecker(
        platform: FakePlatform(infoError: StateError('no channel')),
        source: const StaticVersionSource(version: '9.0.0'),
      );
      final AppVersionStatus status = await checker.check();
      expect(status.hasError, isTrue);
      expect(status.local, LocalAppInfo.unknown);
      expect(status.isUpdateAvailable, isFalse);
    });

    test('forceStoreVersion pretends the store has that version', () async {
      final AppVersionChecker checker = AppVersionChecker(
        forceStoreVersion: '99.0.0',
        platform: FakePlatform(),
        source: CountingSource(error: const AppVersionException('offline')),
      );
      final AppVersionStatus status = await checker.check();
      expect(status.storeVersion, '99.0.0');
      expect(status.isUpdateAvailable, isTrue);
    });

    test('minimumVersion from checker, call or source', () async {
      final FakePlatform platform = FakePlatform();
      final AppVersionChecker fromChecker = AppVersionChecker(
        minimumVersion: '1.2.1',
        platform: platform,
        source: const StaticVersionSource(version: '1.3.0'),
      );
      expect((await fromChecker.check()).updateType, AppUpdateType.required);
      expect(
        (await fromChecker.check(minimumVersion: '1.0.0')).updateType,
        AppUpdateType.optional,
      );

      final AppVersionChecker fromSource = AppVersionChecker(
        platform: platform,
        source: const StaticVersionSource(
          version: '1.3.0',
          minimumVersion: '1.2.5',
        ),
      );
      expect((await fromSource.check()).isUpdateRequired, isTrue);
    });
  });

  group('local info', () {
    test('is read once and cached', () async {
      final FakePlatform platform = FakePlatform();
      final AppVersionChecker checker = AppVersionChecker(
        platform: platform,
        source: const StaticVersionSource(version: '1.0.0'),
      );
      await checker.getLocalInfo();
      await checker.check();
      await checker.getInstallSource();
      expect(platform.infoCalls, 1);
    });

    test('isTestFlight reflects the install source', () async {
      final AppVersionChecker tf = AppVersionChecker(
        platform: FakePlatform(
          info: const LocalAppInfo(
            version: '1.0.0',
            installSource: AppInstallSource.testFlight,
          ),
        ),
      );
      expect(await tf.isTestFlight(), isTrue);
      expect(await tf.getInstallSource(), AppInstallSource.testFlight);

      final AppVersionChecker play = AppVersionChecker(
        platform: FakePlatform(),
      );
      expect(await play.isTestFlight(), isFalse);

      final AppVersionChecker broken = AppVersionChecker(
        platform: FakePlatform(infoError: StateError('x')),
      );
      expect(await broken.isTestFlight(), isFalse);
      expect(await broken.getInstallSource(), AppInstallSource.unknown);
    });
  });

  group('openStore', () {
    test('Android tries the Play app first, then the web link', () async {
      final FakePlatform platform = FakePlatform(
        openResults: <String, bool>{
          'market://details?id=com.example.app': false,
        },
      );
      final AppVersionChecker checker = AppVersionChecker(
        platform: platform,
        source: const StaticVersionSource(version: '1.0.0'),
      );
      expect(await checker.openStore(), isTrue);
      expect(platform.openedUrls, <String>[
        'market://details?id=com.example.app',
        'https://play.google.com/store/apps/details?id=com.example.app',
      ]);
    });

    test('Android does not need a store lookup', () async {
      final FakePlatform platform = FakePlatform();
      final CountingSource source = CountingSource(
        info: const StoreVersionInfo(version: '1.0.0'),
      );
      final AppVersionChecker checker = AppVersionChecker(
        platform: platform,
        source: source,
      );
      expect(await checker.openStore(), isTrue);
      expect(source.calls, 0);
      expect(platform.openedUrls.single, startsWith('market://'));
    });

    test('iOS tries itms-apps first, then https', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final FakePlatform platform = FakePlatform(
        info: iosInfo,
        openResults: <String, bool>{
          'itms-apps://apps.apple.com/app/id123': false,
        },
      );
      final AppVersionChecker checker = AppVersionChecker(
        iosId: '123',
        platform: platform,
        source: const StaticVersionSource(version: '1.0.0'),
      );
      expect(await checker.openStore(), isTrue);
      expect(platform.openedUrls, <String>[
        'itms-apps://apps.apple.com/app/id123',
        'https://apps.apple.com/app/id123',
      ]);
    });

    test('iOS without iosId falls back to the lookup URL', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final FakePlatform platform = FakePlatform(info: iosInfo);
      final AppVersionChecker checker = AppVersionChecker(
        platform: platform,
        source: const StaticVersionSource(
          version: '1.0.0',
          storeUrl: 'https://apps.apple.com/us/app/x/id999',
        ),
      );
      expect(await checker.openStore(), isTrue);
      expect(
        platform.openedUrls.first,
        'itms-apps://apps.apple.com/us/app/x/id999',
      );
    });

    test('returns false when no link exists', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final FakePlatform platform = FakePlatform(info: iosInfo);
      final AppVersionChecker checker = AppVersionChecker(
        platform: platform,
        source: CountingSource(),
      );
      expect(await checker.openStore(), isFalse);
      expect(platform.openedUrls, isEmpty);
    });

    test('returns false when nothing can open the link', () async {
      final FakePlatform platform = FakePlatform(openDefault: false);
      final AppVersionChecker checker = AppVersionChecker(
        platform: platform,
        source: const StaticVersionSource(version: '1.0.0'),
      );
      expect(await checker.openStore(), isFalse);
      expect(platform.openedUrls, hasLength(2));
    });
  });

  group('AppVersion facade', () {
    tearDown(() => AppVersion.instance = AppVersionChecker());

    test('init replaces the shared checker', () async {
      final FakePlatform platform = FakePlatform();
      AppVersion.init(
        androidId: 'com.facade.app',
        platform: platform,
        source: const StaticVersionSource(version: '5.0.0'),
      );
      expect(AppVersion.instance.androidId, 'com.facade.app');
      expect(await AppVersion.isUpdateAvailable(), isTrue);
      expect(await AppVersion.isTestFlight(), isFalse);
      expect((await AppVersion.getLocalInfo()).packageName, 'com.example.app');
      expect(await AppVersion.getInstallSource(), AppInstallSource.playStore);
      expect((await AppVersion.check()).storeUrl, contains('com.facade.app'));
      expect(await AppVersion.openStore(), isTrue);
      AppVersion.clearCache();
    });

    test('instance can be swapped directly', () async {
      AppVersion.instance = AppVersionChecker(
        platform: FakePlatform(),
        source: const StaticVersionSource(version: '0.1.0'),
      );
      expect(await AppVersion.isUpdateAvailable(), isFalse);
    });
  });
}
