/// Vendor-agnostic crash / error monitoring seam (Sentry, Crashlytics, …).
abstract class CrashReportingService {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  });
  Future<void> setUserId(String? userId);
  Future<void> log(String message);
}

class NoOpCrashReportingService implements CrashReportingService {
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> log(String message) async {}
}
