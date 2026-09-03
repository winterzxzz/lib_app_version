/// Raised by a [VersionSource] when the store could not be queried.
///
/// [AppVersionChecker.check] never lets it escape; it is exposed through
/// [AppVersionStatus.error] instead.
class AppVersionException implements Exception {
  const AppVersionException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'AppVersionException: $message${cause != null ? ' ($cause)' : ''}';
}
