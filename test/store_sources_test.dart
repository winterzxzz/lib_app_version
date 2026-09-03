import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_update_check/app_update_check.dart';

import 'helpers.dart';

const String lookupJson = '''
{"resultCount":1,"results":[{"version":"1.4.2","trackViewUrl":"https://apps.apple.com/us/app/plant-id/id6762586391?uo=4","releaseNotes":"Bug fixes","currentVersionReleaseDate":"2026-08-01T10:00:00Z","minimumOsVersion":"15.0"}]}
''';

const String playHtml = '''
<html><script>AF_initDataCallback({key: 'ds:5', data:[[["1.4.2"]],[[null,"x"]]],[null,[null,"Bug fixes\\u003cbr\\u003eNew \\u0026quot;scan\\u0026quot; screen"]]});</script></html>
''';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('AppStoreVersionSource', () {
    test('builds the lookup URL from a numeric id', () {
      const AppStoreVersionSource source = AppStoreVersionSource(
        appId: '6762586391',
        country: 'vn',
      );
      final Uri uri = source.buildUri(iosInfo);
      expect(uri.host, 'itunes.apple.com');
      expect(uri.path, '/lookup');
      expect(uri.queryParameters['id'], '6762586391');
      expect(uri.queryParameters['country'], 'vn');
      expect(uri.queryParameters.containsKey('bundleId'), isFalse);
    });

    test('falls back to the bundle id', () {
      const AppStoreVersionSource source = AppStoreVersionSource();
      final Uri uri = source.buildUri(iosInfo);
      expect(uri.queryParameters['bundleId'], 'com.example.app');
      expect(uri.queryParameters.containsKey('country'), isFalse);
    });

    test('parses the lookup response', () async {
      final FakeHttp http = FakeHttp(const HttpTextResponse(200, lookupJson));
      final AppStoreVersionSource source = AppStoreVersionSource(
        appId: '1',
        httpGet: http.call,
      );
      final StoreVersionInfo? info = await source.fetch(iosInfo);
      expect(http.requests.single.host, 'itunes.apple.com');
      expect(info?.version, '1.4.2');
      expect(info?.storeUrl, contains('id6762586391'));
      expect(info?.releaseNotes, 'Bug fixes');
      expect(info?.releaseDate, DateTime.utc(2026, 8, 1, 10));
    });

    test('returns null when the app is not listed', () async {
      final FakeHttp http = FakeHttp(
        const HttpTextResponse(200, '{"resultCount":0,"results":[]}'),
      );
      final AppStoreVersionSource source = AppStoreVersionSource(
        httpGet: http.call,
      );
      expect(await source.fetch(iosInfo), isNull);
    });

    test('throws AppUpdateException on HTTP and network errors', () async {
      final AppStoreVersionSource bad = AppStoreVersionSource(
        httpGet: FakeHttp(const HttpTextResponse(500, '')).call,
      );
      expect(() => bad.fetch(iosInfo), throwsA(isA<AppUpdateException>()));

      final AppStoreVersionSource offline = AppStoreVersionSource(
        httpGet: FakeHttp(
          const HttpTextResponse(200, ''),
          error: 'offline',
        ).call,
      );
      expect(() => offline.fetch(iosInfo), throwsA(isA<AppUpdateException>()));

      final AppStoreVersionSource garbage = AppStoreVersionSource(
        httpGet: FakeHttp(const HttpTextResponse(200, 'not json')).call,
      );
      expect(() => garbage.fetch(iosInfo), throwsA(isA<AppUpdateException>()));
    });
  });

  group('PlayStoreVersionSource', () {
    test('builds the listing URL', () {
      const PlayStoreVersionSource source = PlayStoreVersionSource(
        locale: 'vi',
      );
      final Uri uri = source.buildUri(androidInfo);
      expect(uri.host, 'play.google.com');
      expect(uri.path, '/store/apps/details');
      expect(uri.queryParameters['id'], 'com.example.app');
      expect(uri.queryParameters['hl'], 'vi');
      expect(
        source.listingUrl(androidInfo),
        'https://play.google.com/store/apps/details?id=com.example.app',
      );
    });

    test('parses the version and release notes from the page', () async {
      final FakeHttp http = FakeHttp(const HttpTextResponse(200, playHtml));
      final PlayStoreVersionSource source = PlayStoreVersionSource(
        packageName: 'com.other',
        httpGet: http.call,
      );
      final StoreVersionInfo? info = await source.fetch(androidInfo);
      expect(http.requests.single.queryParameters['id'], 'com.other');
      expect(info?.version, '1.4.2');
      expect(info?.storeUrl, contains('id=com.other'));
      expect(info?.releaseNotes, 'Bug fixes\nNew "scan" screen');
    });

    test('supports Google-Cloud-style versions', () {
      expect(
        PlayStoreVersionSource.parseVersion('[[["1.2.prod.3"]]'),
        '1.2.prod.3',
      );
      expect(PlayStoreVersionSource.parseVersion('nothing here'), isNull);
    });

    test('404 means not listed, other failures throw', () async {
      final PlayStoreVersionSource missing = PlayStoreVersionSource(
        httpGet: FakeHttp(const HttpTextResponse(404, '')).call,
      );
      expect(await missing.fetch(androidInfo), isNull);

      final PlayStoreVersionSource noVersion = PlayStoreVersionSource(
        httpGet: FakeHttp(const HttpTextResponse(200, '<html></html>')).call,
      );
      expect(
        () => noVersion.fetch(androidInfo),
        throwsA(isA<AppUpdateException>()),
      );

      final PlayStoreVersionSource serverError = PlayStoreVersionSource(
        httpGet: FakeHttp(const HttpTextResponse(503, '')).call,
      );
      expect(
        () => serverError.fetch(androidInfo),
        throwsA(isA<AppUpdateException>()),
      );
    });
  });

  group('StoreVersionSource', () {
    test('picks the store for the current platform', () async {
      final FakeHttp http = FakeHttp(const HttpTextResponse(200, playHtml));
      final StoreVersionSource source = StoreVersionSource(httpGet: http.call);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect((await source.fetch(androidInfo))?.version, '1.4.2');
      expect(http.requests.last.host, 'play.google.com');

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final FakeHttp ios = FakeHttp(const HttpTextResponse(200, lookupJson));
      final StoreVersionSource iosSource = StoreVersionSource(
        iosId: '6762586391',
        iosCountry: 'vn',
        httpGet: ios.call,
      );
      expect((await iosSource.fetch(iosInfo))?.version, '1.4.2');
      expect(ios.requests.last.host, 'itunes.apple.com');
      expect(ios.requests.last.queryParameters['country'], 'vn');
    });

    test('throws on unsupported platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      const StoreVersionSource source = StoreVersionSource();
      expect(() => source.fetch(iosInfo), throwsA(isA<AppUpdateException>()));
    });
  });

  group('custom sources', () {
    test('VersionSource.fromCallback', () async {
      final VersionSource source = VersionSource.fromCallback(
        (LocalAppInfo local) async => StoreVersionInfo(
          version: '2.0.0',
          minimumVersion: local.packageName == 'com.example.app'
              ? '1.5.0'
              : null,
        ),
      );
      final StoreVersionInfo? info = await source.fetch(androidInfo);
      expect(info?.version, '2.0.0');
      expect(info?.minimumVersion, '1.5.0');
      expect(info?.minimumVersionNumber, VersionNumber.parse('1.5'));
    });

    test('StaticVersionSource', () async {
      const StaticVersionSource source = StaticVersionSource(
        version: '3.0.0',
        storeUrl: 'https://example.com',
        releaseNotes: 'notes',
      );
      final StoreVersionInfo? info = await source.fetch(androidInfo);
      expect(
        info,
        const StoreVersionInfo(
          version: '3.0.0',
          storeUrl: 'https://example.com',
          releaseNotes: 'notes',
        ),
      );
      expect(info?.copyWith(version: '3.1.0').version, '3.1.0');
    });
  });

  test('StoreUrls', () {
    expect(
      StoreUrls.playStore('a.b'),
      'https://play.google.com/store/apps/details?id=a.b',
    );
    expect(StoreUrls.playStoreMarket('a.b'), 'market://details?id=a.b');
    expect(StoreUrls.appStore('123'), 'https://apps.apple.com/app/id123');
    expect(StoreUrls.appStore('com.a.b'), isNull);
    expect(StoreUrls.appStore(null), isNull);
    expect(
      StoreUrls.appStoreDeepLink('https://apps.apple.com/app/id1'),
      'itms-apps://apps.apple.com/app/id1',
    );
  });
}
