import 'package:flutter/foundation.dart';

import '../errors.dart';
import '../http/simple_http.dart';
import '../models/local_app_info.dart';
import '../models/store_version_info.dart';
import 'app_store_version_source.dart';
import 'play_store_version_source.dart';
import 'version_source.dart';

/// Default source: App Store on iOS, Play Store on Android.
class StoreVersionSource extends VersionSource {
  const StoreVersionSource({
    this.androidId,
    this.iosId,
    this.iosCountry,
    this.androidLocale = 'en_US',
    this.timeout = const Duration(seconds: 10),
    this.httpGet = defaultHttpGet,
  });

  final String? androidId;
  final String? iosId;
  final String? iosCountry;
  final String androidLocale;
  final Duration timeout;
  final HttpGet httpGet;

  @override
  Future<StoreVersionInfo?> fetch(LocalAppInfo local) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return AppStoreVersionSource(
          appId: iosId,
          country: iosCountry,
          timeout: timeout,
          httpGet: httpGet,
        ).fetch(local);
      case TargetPlatform.android:
        return PlayStoreVersionSource(
          packageName: androidId,
          locale: androidLocale,
          timeout: timeout,
          httpGet: httpGet,
        ).fetch(local);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw AppUpdateException(
          'Store lookup is not supported on ${defaultTargetPlatform.name}',
        );
    }
  }
}
