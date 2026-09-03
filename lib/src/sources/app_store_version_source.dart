import 'dart:convert';

import '../errors.dart';
import '../http/simple_http.dart';
import '../models/local_app_info.dart';
import '../models/store_version_info.dart';
import 'version_source.dart';

/// Looks the app up through the public iTunes Lookup API
/// (`https://itunes.apple.com/lookup`).
class AppStoreVersionSource extends VersionSource {
  const AppStoreVersionSource({
    this.appId,
    this.country,
    this.timeout = const Duration(seconds: 10),
    this.httpGet = defaultHttpGet,
  });

  /// Numeric App Store id (`6762586391`) or bundle id
  /// (`com.example.app`). Defaults to the running app's bundle id.
  final String? appId;

  /// Two-letter storefront code (`us`, `vn`, ...). Set it when the app is not
  /// available in the US store.
  final String? country;

  final Duration timeout;
  final HttpGet httpGet;

  /// The lookup URL that will be requested for [local].
  Uri buildUri(LocalAppInfo local) {
    final String id = appId ?? local.packageName;
    final Map<String, String> params = <String, String>{
      if (id.contains('.')) 'bundleId': id else 'id': id,
      'country': ?country,
      // Cache buster: Apple's CDN otherwise happily serves stale answers.
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    return Uri.https('itunes.apple.com', '/lookup', params);
  }

  @override
  Future<StoreVersionInfo?> fetch(LocalAppInfo local) async {
    final Uri uri = buildUri(local);
    final HttpTextResponse response;
    try {
      response = await httpGet(uri, timeout: timeout);
    } catch (error) {
      throw AppVersionException('App Store lookup failed', error);
    }
    if (!response.isOk) {
      throw AppVersionException(
        'App Store lookup failed with HTTP ${response.statusCode}',
      );
    }
    try {
      return parseLookupJson(response.body);
    } catch (error) {
      throw AppVersionException('Could not parse App Store response', error);
    }
  }

  /// Parses an iTunes Lookup JSON document. Returns `null` when the app is not
  /// found (`resultCount == 0`).
  static StoreVersionInfo? parseLookupJson(String body) {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final Object? results = decoded['results'];
    if (results is! List || results.isEmpty) return null;
    final Object? first = results.first;
    if (first is! Map) return null;
    final String? version = first['version']?.toString();
    if (version == null || version.isEmpty) return null;
    return StoreVersionInfo(
      version: version,
      storeUrl: first['trackViewUrl']?.toString(),
      releaseNotes: first['releaseNotes']?.toString(),
      releaseDate: DateTime.tryParse(
        first['currentVersionReleaseDate']?.toString() ?? '',
      ),
    );
  }
}
