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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// App display name shown in the OS task switcher and app launcher.
  ///
  /// In en, this message translates to:
  /// **'MissionOut Responder'**
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

  /// Error shown when the email-code field is empty during code verification.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email.'**
  String get codeRequired;

  /// Success message after the responder requests a sign-in code.
  ///
  /// In en, this message translates to:
  /// **'Check your email for code'**
  String get codeSentMessage;

  /// Heading on the responder logged-out screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in to responder view'**
  String get signInTitle;

  /// Subhead under the responder sign-in heading.
  ///
  /// In en, this message translates to:
  /// **'Use an emailed code or Google to continue.'**
  String get signInSubtitle;

  /// Label above the email text field on the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFieldLabel;

  /// Placeholder shown inside the empty email field.
  ///
  /// In en, this message translates to:
  /// **'example@domain.com'**
  String get emailFieldHint;

  /// Helper text under the email field on the responder sign-in form.
  ///
  /// In en, this message translates to:
  /// **'We will send a sign-in link for this responder account.'**
  String get emailFieldHelp;

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

  /// Error banner when the responder's mission list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load missions from the API.'**
  String get errorLoadIncidents;

  /// Error banner when refreshing incidents after a live alert event fails.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh missions after a live event.'**
  String get errorRefreshIncidents;

  /// Error when the responder tries to submit a response without a known incident.
  ///
  /// In en, this message translates to:
  /// **'Could not submit response because the incident public ID is missing.'**
  String get errorMissingIncidentId;

  /// Error when posting the responder's status to the API fails.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your responder status.'**
  String get errorSubmitResponse;

  /// Subtitle shown next to the MissionOut brand on the responder header.
  ///
  /// In en, this message translates to:
  /// **'Responder view for acknowledgements, readiness, and active mission context.'**
  String get brandSubtitle;

  /// Tooltip on the account avatar / popup-menu button.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tooltipAccount;

  /// Logout entry inside the account popup menu.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// Heading on the incoming-alert strip when a new mission arrives.
  ///
  /// In en, this message translates to:
  /// **'Incoming mission alert'**
  String get incomingAlertTitle;

  /// Primary button on the incoming-alert strip.
  ///
  /// In en, this message translates to:
  /// **'Open mission'**
  String get openMissionButton;

  /// Secondary button to clear the incoming-alert strip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissButton;

  /// Generic cancel button (dialogs, confirmations).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Title of the confirmation dialog when switching availability to unavailable.
  ///
  /// In en, this message translates to:
  /// **'Go unavailable?'**
  String get dialogGoUnavailableTitle;

  /// Body of the confirmation dialog when switching availability to unavailable.
  ///
  /// In en, this message translates to:
  /// **'If you switch to unavailable, you will not receive alerts until you change your status back.'**
  String get dialogGoUnavailableContent;

  /// Confirm button on the unavailability dialog.
  ///
  /// In en, this message translates to:
  /// **'Go unavailable'**
  String get dialogGoUnavailableConfirm;

  /// Label for the responder's current availability state.
  ///
  /// In en, this message translates to:
  /// **'{status, select, available{Available} unavailable{Unavailable} other{Unknown}}'**
  String availabilityStatus(String status);

  /// Label for a responder's response status on an incident.
  ///
  /// In en, this message translates to:
  /// **'{status, select, responding{Responding} pending{Pending} notAvailable{Not Available} other{Unknown}}'**
  String responseStatus(String status);

  /// Fallback label when a status enum value is missing or unrecognized.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// Pill label on the standby hero when the responder is available and idle.
  ///
  /// In en, this message translates to:
  /// **'Standing by'**
  String get statusStandingBy;

  /// Large idle-state headline on the standby hero.
  ///
  /// In en, this message translates to:
  /// **'Quiet until a mission arrives.'**
  String get standbyHeroTitle;

  /// Standby hero body text when the responder is available.
  ///
  /// In en, this message translates to:
  /// **'This screen stays minimal by default. When dispatch starts, the mission view takes over and response actions move to the front.'**
  String get standbyHeroDescriptionAvailable;

  /// Standby hero body text when the responder is unavailable.
  ///
  /// In en, this message translates to:
  /// **'You are currently unavailable, so the app stays in standby and no responder actions are active until you switch back.'**
  String get standbyHeroDescriptionUnavailable;

  /// Standby metric label: which broad state the responder is in.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get metricStateLabel;

  /// Standby metric value when the responder is available.
  ///
  /// In en, this message translates to:
  /// **'Ready for interrupt'**
  String get metricStateReadyValue;

  /// Standby metric value when the responder is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Alerts paused'**
  String get metricStateAlertsPausedValue;

  /// Standby metric label: the responder's default operating mode.
  ///
  /// In en, this message translates to:
  /// **'Default mode'**
  String get metricDefaultModeLabel;

  /// Standby metric value describing the responder's default mode.
  ///
  /// In en, this message translates to:
  /// **'Idle, not queue-driven'**
  String get metricDefaultModeValue;

  /// Heading of the readiness side panel on the responder home screen.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get readinessHeading;

  /// Subhead under the readiness panel heading.
  ///
  /// In en, this message translates to:
  /// **'Keep this device ready for the next interrupt. Notification channels are supplemental to native mobile alerting.'**
  String get readinessSubtitle;

  /// Section title for the availability row inside the readiness panel.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get readinessAvailabilityTitle;

  /// Readiness availability row detail when the responder is available.
  ///
  /// In en, this message translates to:
  /// **'Responder actions will surface when a mission is assigned.'**
  String get readinessAvailabilityDetailAvailable;

  /// Readiness availability row detail when the responder is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Alert actions stay out of the way until you are available again.'**
  String get readinessAvailabilityDetailUnavailable;

  /// Section title for the native Android alert row inside the readiness panel.
  ///
  /// In en, this message translates to:
  /// **'Native Android alerts'**
  String get readinessNativeAlertsTitle;

  /// Section title for the browser alert row inside the readiness panel.
  ///
  /// In en, this message translates to:
  /// **'Browser alerts'**
  String get readinessBrowserAlertsTitle;

  /// Generic Enable button (used for native and browser alert subscriptions).
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableButton;

  /// Button that opens Android full-screen intent settings.
  ///
  /// In en, this message translates to:
  /// **'Full-screen settings'**
  String get fullScreenSettingsButton;

  /// Button that opens Android Do-Not-Disturb access settings.
  ///
  /// In en, this message translates to:
  /// **'DND settings'**
  String get dndSettingsButton;

  /// Button that sends a test push notification to the current device.
  ///
  /// In en, this message translates to:
  /// **'Test alert'**
  String get testAlertButton;

  /// In-progress label shown beneath the response segmented control while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingButton;

  /// Heading of the active-missions list on the responder home screen.
  ///
  /// In en, this message translates to:
  /// **'Active missions'**
  String get missionListTitle;

  /// Subhead under the active-missions list heading.
  ///
  /// In en, this message translates to:
  /// **'Review active incidents and select one to update your response.'**
  String get missionListSubtitle;

  /// Heading above the incident notes inside the responder mission card.
  ///
  /// In en, this message translates to:
  /// **'Mission notes'**
  String get missionNotesHeading;
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
