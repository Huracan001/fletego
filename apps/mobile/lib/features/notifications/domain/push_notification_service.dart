/// Push dispatch abstraction — wire FCM/APNs later without changing callers.
abstract class PushNotificationService {
  Future<void> registerToken(String token, {String platform = 'unknown'});

  Future<void> unregisterToken(String token);

  /// Best-effort fan-out. MVP no-op until server/FCM is configured.
  Future<void> dispatch({
    required String userId,
    required String title,
    String? body,
    Map<String, dynamic>? data,
  });
}

class NoOpPushNotificationService implements PushNotificationService {
  const NoOpPushNotificationService();

  @override
  Future<void> registerToken(String token, {String platform = 'unknown'}) async {}

  @override
  Future<void> unregisterToken(String token) async {}

  @override
  Future<void> dispatch({
    required String userId,
    required String title,
    String? body,
    Map<String, dynamic>? data,
  }) async {}
}
