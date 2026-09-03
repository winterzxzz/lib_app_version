/// Where the currently running build was installed from.
///
/// * iOS: [appStore], [testFlight], [development] (Xcode / Ad Hoc /
///   Enterprise builds carry an `embedded.mobileprovision`) or [simulator].
/// * Android: [playStore], [sideload] (any other installer such as the system
///   package installer or a third-party store) or [development] (`adb install`
///   / IDE runs, which have no installer package).
enum AppInstallSource {
  /// Installed from the Apple App Store.
  appStore('appstore'),

  /// Installed through TestFlight (sandbox receipt).
  testFlight('testflight'),

  /// Installed from Google Play (any track: production, open/closed/internal
  /// testing).
  playStore('playstore'),

  /// Android build installed by something other than Google Play.
  sideload('sideload'),

  /// Debug / development build (Xcode, Ad Hoc, Enterprise, `adb install`).
  development('development'),

  /// Running on the iOS simulator.
  simulator('simulator'),

  /// Could not be determined (also used on unsupported platforms).
  unknown('unknown');

  const AppInstallSource(this.rawValue);

  /// The string sent over the platform channel.
  final String rawValue;

  /// Parses a [rawValue] coming from native code; unknown values map to
  /// [unknown].
  static AppInstallSource fromRawValue(String? rawValue) {
    for (final AppInstallSource source in values) {
      if (source.rawValue == rawValue) return source;
    }
    return unknown;
  }

  /// `true` for [testFlight].
  bool get isTestFlight => this == testFlight;

  /// `true` for builds delivered by an official store ([appStore] or
  /// [playStore]).
  bool get isStore => this == appStore || this == playStore;
}
