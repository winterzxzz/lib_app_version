import '../errors.dart';
import '../http/simple_http.dart';
import '../models/local_app_info.dart';
import '../models/store_version_info.dart';
import 'version_source.dart';

/// Reads the version from the public Google Play listing page.
///
/// Google offers no official API for this, so the page HTML is scanned for the
/// version string the same way `new_version_plus` does. Should Google change
/// the page layout, [fetch] throws and [AppUpdateStatus.error] is set; the
/// app keeps working.
class PlayStoreVersionSource extends VersionSource {
  const PlayStoreVersionSource({
    this.packageName,
    this.locale = 'en_US',
    this.timeout = const Duration(seconds: 10),
    this.httpGet = defaultHttpGet,
  });

  /// Play Store application id. Defaults to the running app's id.
  final String? packageName;

  /// `hl` query parameter, e.g. `en_US` or `vi`.
  final String locale;

  final Duration timeout;
  final HttpGet httpGet;

  static final RegExp _versionPattern = RegExp(
    r'\[\[\["(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)"\]\]',
  );
  static final RegExp _releaseNotesPattern = RegExp(
    r'\[null,\[null,"((?:[^"\\]|\\.)*)"\]\]',
  );
  static final RegExp _lineBreakPattern = RegExp(
    r'<br\s*/?>',
    caseSensitive: false,
  );
  static final RegExp _htmlTagPattern = RegExp(r'<[^>]+>');
  static final RegExp _unicodeEscapePattern = RegExp(r'\\u([0-9a-fA-F]{4})');

  /// The listing URL that will be requested for [local].
  Uri buildUri(LocalAppInfo local) {
    return Uri.https('play.google.com', '/store/apps/details', <String, String>{
      'id': packageName ?? local.packageName,
      'hl': locale,
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  /// Public listing URL without the cache-buster parameter.
  String listingUrl(LocalAppInfo local) =>
      'https://play.google.com/store/apps/details?id=${packageName ?? local.packageName}';

  @override
  Future<StoreVersionInfo?> fetch(LocalAppInfo local) async {
    final Uri uri = buildUri(local);
    final HttpTextResponse response;
    try {
      response = await httpGet(uri, timeout: timeout);
    } catch (error) {
      throw AppUpdateException('Play Store lookup failed', error);
    }
    if (response.statusCode == 404) return null;
    if (!response.isOk) {
      throw AppUpdateException(
        'Play Store lookup failed with HTTP ${response.statusCode}',
      );
    }
    final String? version = parseVersion(response.body);
    if (version == null) {
      throw AppUpdateException(
        'Could not find the version in the Play Store page',
      );
    }
    return StoreVersionInfo(
      version: version,
      storeUrl: listingUrl(local),
      releaseNotes: parseReleaseNotes(response.body),
    );
  }

  /// Extracts the version string from a Play Store listing page.
  static String? parseVersion(String html) =>
      _versionPattern.firstMatch(html)?.group(1);

  /// Extracts the "What's new" text from a Play Store listing page.
  static String? parseReleaseNotes(String html) {
    final String? raw = _releaseNotesPattern.firstMatch(html)?.group(1);
    if (raw == null) return null;
    final String decoded = _decodeJsString(raw)
        .replaceAll(_lineBreakPattern, '\n')
        .replaceAll(_htmlTagPattern, '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
    return decoded.isEmpty ? null : decoded;
  }

  static String _decodeJsString(String input) {
    return input
        .replaceAllMapped(
          _unicodeEscapePattern,
          (Match m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
        )
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\/', '/')
        .replaceAll(r'\\', r'\');
  }
}
