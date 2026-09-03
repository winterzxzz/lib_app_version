/// Builds store links.
abstract final class StoreUrls {
  static final RegExp _numeric = RegExp(r'^\d+$');
  static final RegExp _httpScheme = RegExp(r'^https?://');

  /// `https://play.google.com/store/apps/details?id=<packageName>`
  static String playStore(String packageName) =>
      'https://play.google.com/store/apps/details?id=$packageName';

  /// `market://details?id=<packageName>` (opens the Play app directly).
  static String playStoreMarket(String packageName) =>
      'market://details?id=$packageName';

  /// `https://apps.apple.com/app/id<appId>` when [appId] is a numeric App
  /// Store id, otherwise `null` (a bundle id cannot be turned into a link
  /// without a lookup).
  static String? appStore(String? appId) {
    if (appId == null || !_numeric.hasMatch(appId)) return null;
    return 'https://apps.apple.com/app/id$appId';
  }

  /// Turns an `https://apps.apple.com/...` link into an `itms-apps://` one so
  /// the App Store app opens instead of Safari.
  static String appStoreDeepLink(String httpsUrl) =>
      httpsUrl.replaceFirst(_httpScheme, 'itms-apps://');
}
