import 'package:equatable/equatable.dart';

import '../../../shared/enums/onboarding_intent.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    this.fullName,
    this.displayName,
    this.phone,
    this.email,
    this.onboardingIntent,
    this.isDriver = false,
    this.isCustomer = false,
    this.onboardingCompletedAt,
    this.countryCode = 'BO',
    this.locale = 'es',
  });

  final String id;
  final String? fullName;
  final String? displayName;
  final String? phone;
  final String? email;
  final OnboardingIntent? onboardingIntent;
  final bool isDriver;
  final bool isCustomer;
  final DateTime? onboardingCompletedAt;
  final String countryCode;
  final String locale;

  bool get hasCompletedOnboarding => onboardingCompletedAt != null;

  String get greetingName {
    final name = displayName ?? fullName;
    if (name == null || name.trim().isEmpty) return '';
    return name.trim().split(RegExp(r'\s+')).first;
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      displayName: json['display_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      onboardingIntent: OnboardingIntentX.fromDb(
        json['onboarding_intent'] as String?,
      ),
      isDriver: json['is_driver'] as bool? ?? false,
      isCustomer: json['is_customer'] as bool? ?? false,
      onboardingCompletedAt: json['onboarding_completed_at'] == null
          ? null
          : DateTime.tryParse(json['onboarding_completed_at'] as String),
      countryCode: json['country_code'] as String? ?? 'BO',
      locale: json['locale'] as String? ?? 'es',
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (fullName != null) 'full_name': fullName,
      if (displayName != null) 'display_name': displayName,
      if (phone != null) 'phone': phone,
      if (onboardingIntent != null)
        'onboarding_intent': onboardingIntent!.dbValue,
      'is_driver': isDriver,
      'is_customer': isCustomer,
      if (onboardingCompletedAt != null)
        'onboarding_completed_at': onboardingCompletedAt!.toIso8601String(),
    };
  }

  Profile copyWith({
    String? fullName,
    String? displayName,
    String? phone,
    String? email,
    OnboardingIntent? onboardingIntent,
    bool? isDriver,
    bool? isCustomer,
    DateTime? onboardingCompletedAt,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      onboardingIntent: onboardingIntent ?? this.onboardingIntent,
      isDriver: isDriver ?? this.isDriver,
      isCustomer: isCustomer ?? this.isCustomer,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      countryCode: countryCode,
      locale: locale,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    onboardingIntent,
    onboardingCompletedAt,
  ];
}

extension OnboardingIntentX on OnboardingIntent {
  static OnboardingIntent? fromDb(String? value) {
    if (value == null) return null;
    for (final intent in OnboardingIntent.values) {
      if (intent.dbValue == value) return intent;
    }
    return null;
  }
}
