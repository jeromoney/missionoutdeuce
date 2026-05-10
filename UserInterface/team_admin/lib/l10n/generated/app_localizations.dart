import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App display name shown in the OS task switcher and app launcher.
  ///
  /// In en, this message translates to:
  /// **'MissionOut Team Admin'**
  String get appName;

  /// Validation error when an email field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address.'**
  String get emailRequired;

  /// Validation error when an email field has malformed input.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// Validation error when a name field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get nameRequired;

  /// Validation error when a name field has malformed input.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name.'**
  String get nameInvalid;

  /// Validation error when a phone field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number.'**
  String get phoneRequired;

  /// Validation error when a phone field has malformed input.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get phoneInvalid;

  /// Error shown when the email-code field is empty during code verification.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email.'**
  String get codeRequired;

  /// Success message after the team admin requests a sign-in code.
  ///
  /// In en, this message translates to:
  /// **'Check your email for code'**
  String get codeSentMessage;

  /// Heading on the team-admin logged-out screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Team Admin'**
  String get signInTitle;

  /// Subhead under the team-admin sign-in heading.
  ///
  /// In en, this message translates to:
  /// **'Use an emailed code or Google to continue into your team-management workspace.'**
  String get signInSubtitle;

  /// Subtitle next to the brand on the team-admin sign-in panel.
  ///
  /// In en, this message translates to:
  /// **'Secure sign-in for active MissionOut operations.'**
  String get signInBrandSubtitle;

  /// Label above the email text field on the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFieldLabel;

  /// Placeholder shown inside the empty email field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailFieldHint;

  /// Helper text under the email field before a code has been sent.
  ///
  /// In en, this message translates to:
  /// **'We will send a one-time code for this Team Admin account.'**
  String get emailFieldHelpInitial;

  /// Helper text under the email field once a code has been sent.
  ///
  /// In en, this message translates to:
  /// **'Enter the emailed code to finish Team Admin sign-in.'**
  String get emailFieldHelpAwaitingCode;

  /// Label above the email-code input field that appears after a code has been sent.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeFieldLabel;

  /// Placeholder for the email-code input field.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get codeFieldHint;

  /// Sign-in button text while the entered code is being verified.
  ///
  /// In en, this message translates to:
  /// **'Verifying code...'**
  String get verifyingButton;

  /// Sign-in button text while the email code is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending code...'**
  String get sendingButton;

  /// Sign-in button text when ready to verify a code.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get verifyCodeButton;

  /// Sign-in button text on the initial state.
  ///
  /// In en, this message translates to:
  /// **'Email me a sign-in code'**
  String get emailMeCodeButton;

  /// Label on the Google sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Disabled Google button label when the client id is missing.
  ///
  /// In en, this message translates to:
  /// **'Google login not configured'**
  String get googleNotConfigured;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
