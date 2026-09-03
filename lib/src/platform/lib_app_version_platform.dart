import 'package:flutter/services.dart';

import '../models/local_app_info.dart';

/// Native bridge used by [AppVersionChecker]. Swap it in tests.
abstract class LibAppVersionPlatform {
  const LibAppVersionPlatform();

  /// Version, build number, package name and install source of the running
  /// app.
  Future<LocalAppInfo> getAppInfo();

  /// Opens [url] in the matching external app (store, browser...). Returns
  /// `false` when nothing could handle it.
  Future<bool> openUrl(String url);
}

/// [LibAppVersionPlatform] backed by the `lib_app_version` method channel.
class MethodChannelLibAppVersion extends LibAppVersionPlatform {
  const MethodChannelLibAppVersion([
    this.channel = const MethodChannel('lib_app_version'),
  ]);

  final MethodChannel channel;

  @override
  Future<LocalAppInfo> getAppInfo() async {
    final Map<Object?, Object?>? map = await channel
        .invokeMapMethod<Object?, Object?>('getAppInfo');
    return LocalAppInfo.fromMap(map ?? const <Object?, Object?>{});
  }

  @override
  Future<bool> openUrl(String url) async {
    final bool? opened = await channel.invokeMethod<bool>(
      'openUrl',
      <String, Object?>{'url': url},
    );
    return opened ?? false;
  }
}
