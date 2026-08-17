/// Vendor-agnostic analytics seam.
abstract class AnalyticsService {
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  });
}

class NoOpAnalyticsService implements AnalyticsService {
  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {}
}

abstract final class AnalyticsEvents {
  static const appOpened = 'app_opened';
  static const signupStarted = 'signup_started';
  static const signupCompleted = 'signup_completed';
  static const cargoRequestStarted = 'cargo_request_started';
  static const cargoRequestCompleted = 'cargo_request_completed';
  static const offerReceived = 'offer_received';
  static const offerAccepted = 'offer_accepted';
  static const tripStarted = 'trip_started';
  static const tripCompleted = 'trip_completed';
  static const ratingSubmitted = 'rating_submitted';
}
