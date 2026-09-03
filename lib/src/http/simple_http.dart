import 'dart:convert';
import 'dart:io';

/// Minimal HTTP GET response.
class HttpTextResponse {
  const HttpTextResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// Signature of the function used to perform HTTP GET requests.
///
/// Inject your own (for example one backed by `package:http` or a mock in
/// tests) through `AppUpdateChecker(httpGet: ...)`.
typedef HttpGet =
    Future<HttpTextResponse> Function(
      Uri uri, {
      Map<String, String>? headers,
      Duration? timeout,
    });

/// Default [HttpGet] built on `dart:io`, so the package needs no HTTP
/// dependency.
Future<HttpTextResponse> defaultHttpGet(
  Uri uri, {
  Map<String, String>? headers,
  Duration? timeout,
}) async {
  final Duration effectiveTimeout = timeout ?? const Duration(seconds: 10);
  final HttpClient client = HttpClient()
    ..connectionTimeout = effectiveTimeout
    ..autoUncompress = true;
  try {
    final HttpClientRequest request = await client
        .getUrl(uri)
        .timeout(effectiveTimeout);
    headers?.forEach(request.headers.set);
    final HttpClientResponse response = await request.close().timeout(
      effectiveTimeout,
    );
    final String body = await response
        .transform(const Utf8Decoder(allowMalformed: true))
        .join()
        .timeout(effectiveTimeout);
    return HttpTextResponse(response.statusCode, body);
  } finally {
    client.close(force: true);
  }
}
