/// Product onboarding intent (UX), separate from platform/company roles.
enum OnboardingIntent {
  needTransport,
  offerTransport,
  manageTransport;

  String get dbValue => switch (this) {
    OnboardingIntent.needTransport => 'need_transport',
    OnboardingIntent.offerTransport => 'offer_transport',
    OnboardingIntent.manageTransport => 'manage_transport',
  };
}
