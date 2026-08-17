import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'FLETEGO'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Move cargo. Move business.'**
  String get appTagline;

  /// No description provided for @brandBy.
  ///
  /// In es, this message translates to:
  /// **'by Pick&Truck'**
  String get brandBy;

  /// No description provided for @welcomeHeadline.
  ///
  /// In es, this message translates to:
  /// **'El marketplace de transporte pesado'**
  String get welcomeHeadline;

  /// No description provided for @welcomeBody.
  ///
  /// In es, this message translates to:
  /// **'Solicita el camión correcto para tu carga o encuentra fletes compatibles y reduce viajes en vacío.'**
  String get welcomeBody;

  /// No description provided for @getStarted.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get getStarted;

  /// No description provided for @haveAccount.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get haveAccount;

  /// No description provided for @whatDoYouWant.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer?'**
  String get whatDoYouWant;

  /// No description provided for @needTransportTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesito transportar'**
  String get needTransportTitle;

  /// No description provided for @needTransportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Quiero un camión para mi carga.'**
  String get needTransportSubtitle;

  /// No description provided for @offerTransportTitle.
  ///
  /// In es, this message translates to:
  /// **'Ofrezco transporte'**
  String get offerTransportTitle;

  /// No description provided for @offerTransportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tengo camión y quiero transportar carga.'**
  String get offerTransportSubtitle;

  /// No description provided for @manageTransportTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiono transporte'**
  String get manageTransportTitle;

  /// No description provided for @manageTransportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Administro operaciones para una empresa o terceros.'**
  String get manageTransportSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get loginTitle;

  /// No description provided for @signupTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get signupTitle;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullName;

  /// No description provided for @continueAction.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get somethingWentWrong;

  /// No description provided for @requestTruck.
  ///
  /// In es, this message translates to:
  /// **'Solicitar un camión'**
  String get requestTruck;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
