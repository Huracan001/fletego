import 'package:flutter_test/flutter_test.dart';
import 'package:fletego/features/auth/domain/profile.dart';
import 'package:fletego/shared/enums/onboarding_intent.dart';

void main() {
  test('Profile.fromJson maps onboarding intent and greeting', () {
    final profile = Profile.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'full_name': 'María Pérez',
      'display_name': 'María Pérez',
      'email': 'maria@example.com',
      'onboarding_intent': 'need_transport',
      'is_customer': true,
      'is_driver': false,
      'onboarding_completed_at': '2026-08-12T12:00:00Z',
      'country_code': 'BO',
      'locale': 'es',
    });

    expect(profile.onboardingIntent, OnboardingIntent.needTransport);
    expect(profile.hasCompletedOnboarding, isTrue);
    expect(profile.greetingName, 'María');
    expect(profile.isCustomer, isTrue);
  });

  test('Profile.fromJson handles missing onboarding', () {
    final profile = Profile.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'email': 'x@y.com',
    });

    expect(profile.onboardingIntent, isNull);
    expect(profile.hasCompletedOnboarding, isFalse);
  });
}
