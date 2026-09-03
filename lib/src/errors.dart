/// Raised by a [VersionSource] when the store could not be queried.
///
/// [AppUpdateChecker.check] never lets it escape; it is exposed through
/// [AppUpdateStatus.error] instead.
class AppUpdateException implements Exception {
  const AppUpdateException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'AppUpdateException: $message${cause != null ? ' ($cause)' : ''}';
}
