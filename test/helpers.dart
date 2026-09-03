import 'dart:async';

import 'package:app_update_check/app_update_check.dart';

const LocalAppInfo androidInfo = LocalAppInfo(
  version: '1.2.0',
  buildNumber: '12',
  packageName: 'com.example.app',
  installSource: AppInstallSource.playStore,
  installerPackage: 'com.android.vending',
);

const LocalAppInfo iosInfo = LocalAppInfo(
  version: '1.2.0',
  buildNumber: '12',
  packageName: 'com.example.app',
  installSource: AppInstallSource.appStore,
);

class FakePlatform extends AppUpdateCheckPlatform {
  FakePlatform({
    this.info = androidInfo,
    this.infoError,
    this.openResults = const <String, bool>{},
    this.openDefault = true,
  });

  final LocalAppInfo info;
  final Object? infoError;
  final Map<String, bool> openResults;
  final bool openDefault;

  final List<String> openedUrls = <String>[];
  int infoCalls = 0;

  @override
  Future<LocalAppInfo> getAppInfo() async {
    infoCalls++;
    final Object? error = infoError;
    if (error != null) throw error;
    return info;
  }

  @override
  Future<bool> openUrl(String url) async {
    openedUrls.add(url);
    return openResults[url] ?? openDefault;
  }
}

class CountingSource extends VersionSource {
  CountingSource({this.info, this.error});

  StoreVersionInfo? info;
  Object? error;
  int calls = 0;
  Completer<StoreVersionInfo?>? completer;

  @override
  Future<StoreVersionInfo?> fetch(LocalAppInfo local) async {
    calls++;
    final Completer<StoreVersionInfo?>? pending = completer;
    if (pending != null) return pending.future;
    final Object? failure = error;
    if (failure != null) throw failure;
    return info;
  }
}

/// A fake [HttpGet] that records requested URIs and returns [response].
class FakeHttp {
  FakeHttp(this.response, {this.error});

  final HttpTextResponse response;
  final Object? error;
  final List<Uri> requests = <Uri>[];

  Future<HttpTextResponse> call(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    requests.add(uri);
    final Object? failure = error;
    if (failure != null) throw failure;
    return response;
  }
}
