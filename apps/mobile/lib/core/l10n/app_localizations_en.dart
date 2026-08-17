// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FLETEGO';

  @override
  String get appTagline => 'Move cargo. Move business.';

  @override
  String get brandBy => 'by Pick&Truck';

  @override
  String get welcomeHeadline => 'The heavy transportation marketplace';

  @override
  String get welcomeBody =>
      'Request the right truck for your cargo or find compatible loads and reduce empty returns.';

  @override
  String get getStarted => 'Get started';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get whatDoYouWant => 'What do you want to do?';

  @override
  String get needTransportTitle => 'I need transport';

  @override
  String get needTransportSubtitle => 'I need a truck for my cargo.';

  @override
  String get offerTransportTitle => 'I offer transport';

  @override
  String get offerTransportSubtitle => 'I have a truck and want to haul cargo.';

  @override
  String get manageTransportTitle => 'I manage transport';

  @override
  String get manageTransportSubtitle =>
      'I manage operations for a company or third parties.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get signupTitle => 'Create your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get continueAction => 'Continue';

  @override
  String get retry => 'Retry';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get requestTruck => 'Request a truck';
}
