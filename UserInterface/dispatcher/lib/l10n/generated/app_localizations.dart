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
  /// **'MissionOut'**
  String get appName;

  /// Banner shown when the user has no active MissionOut team membership.
  ///
  /// In en, this message translates to:
  /// **'Contact your local administrator referencing this email: {email}'**
  String contactAdministrator(String email);

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

  /// Success message shown after a Firebase Email Link is sent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a sign-in link. Tap it to complete sign-in.'**
  String get linkSentMessage;

  /// Heading on the dispatcher logged-out screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in to mission control'**
  String get signInTitle;

  /// Subhead under the dispatcher sign-in heading.
  ///
  /// In en, this message translates to:
  /// **'Use an email sign-in link or Google to continue into the dispatcher workspace.'**
  String get signInSubtitle;

  /// Subtitle next to the brand on the dispatcher sign-in panel.
  ///
  /// In en, this message translates to:
  /// **'Secure sign-in for active MissionOut operations.'**
  String get signInBrandSubtitle;

  /// Section eyebrow above the sign-in heading.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get sectionEyebrowAccess;

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

  /// Helper text under the email field on the dispatcher sign-in form.
  ///
  /// In en, this message translates to:
  /// **'We will send a sign-in link to this email address.'**
  String get emailFieldHelp;

  /// Sign-in button text while the email sign-in link is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending link...'**
  String get sendingButton;

  /// Sign-in button label — sends a Firebase Email Link.
  ///
  /// In en, this message translates to:
  /// **'Email me a sign-in link'**
  String get emailMeCodeButton;

  /// Sign-in button label shown after a link has already been sent.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get resendLinkButton;

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

  /// Error banner shown on the dispatcher when the dashboard fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load incident data.'**
  String get errorLoadIncidents;

  /// Subtitle next to the MissionOut brand on the mission-control header.
  ///
  /// In en, this message translates to:
  /// **'Mission control for recent dispatch activity, team visibility, and live responder coordination.'**
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

  /// MetricBadge label for the count of active incidents in the header.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get metricActiveLabel;

  /// MetricBadge label next to the relative creation time of an incident.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get metricCreatedLabel;

  /// SummaryCard title for the active-incidents tile on the summary strip.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get summaryActiveTitle;

  /// SummaryCard subtitle for the active-incidents tile.
  ///
  /// In en, this message translates to:
  /// **'Open incidents from the last 7 days in the current feed.'**
  String get summaryActiveSubtitle;

  /// SummaryCard subtitle for the responding-responders tile.
  ///
  /// In en, this message translates to:
  /// **'Confirmed field responders across the recent incident feed.'**
  String get summaryRespondingSubtitle;

  /// SummaryCard subtitle for the pending-responders tile.
  ///
  /// In en, this message translates to:
  /// **'Awaiting acknowledgement in the last-7-days incident feed.'**
  String get summaryPendingSubtitle;

  /// Heading shown on the empty-state when no incidents have been dispatched yet.
  ///
  /// In en, this message translates to:
  /// **'No active incidents yet'**
  String get emptyIncidentTitle;

  /// Fallback label when an incident's team name cannot be resolved.
  ///
  /// In en, this message translates to:
  /// **'Assigned team'**
  String get teamFallbackName;

  /// Heading of the dispatch-board panel.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Board'**
  String get dispatchBoardTitle;

  /// Subhead under the dispatch-board panel heading.
  ///
  /// In en, this message translates to:
  /// **'Open missions, team load, and responder acknowledgement state.'**
  String get dispatchBoardSubtitle;

  /// Button label that opens the create-incident form.
  ///
  /// In en, this message translates to:
  /// **'Create incident'**
  String get createIncidentButton;

  /// Pill label for an incident that is still active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get incidentStateActive;

  /// Pill label for an incident that has been resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get incidentStateResolved;

  /// Heading of the incident-detail panel.
  ///
  /// In en, this message translates to:
  /// **'Incident Detail'**
  String get incidentDetailTitle;

  /// Subhead under the incident-detail panel heading.
  ///
  /// In en, this message translates to:
  /// **'Dispatch notes, responder roster, and mission context.'**
  String get incidentDetailSubtitle;

  /// Button on the incident-detail panel that opens the edit form.
  ///
  /// In en, this message translates to:
  /// **'Edit incident'**
  String get editIncidentButton;

  /// Prefix shown next to a response's relative update time, e.g. 'Updated 5 minutes ago'.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String responseUpdated(String time);

  /// Fallback label when a response status enum value is missing or unrecognized.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// Fallback name when a response has no associated user public id.
  ///
  /// In en, this message translates to:
  /// **'Unknown responder'**
  String get responderUnknown;

  /// Fallback name showing a short prefix of a responder's public id when no name is on file.
  ///
  /// In en, this message translates to:
  /// **'Responder {prefix}'**
  String responderFallbackName(String prefix);

  /// Heading of the delivery-feed panel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Feed'**
  String get deliveryFeedTitle;

  /// Subhead under the delivery-feed panel heading.
  ///
  /// In en, this message translates to:
  /// **'Push attempts, acknowledgements, and escalation activity.'**
  String get deliveryFeedSubtitle;

  /// Action button that opens the full delivery log view.
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get viewLogsButton;

  /// Section eyebrow above the create-incident heading.
  ///
  /// In en, this message translates to:
  /// **'New incident'**
  String get newIncidentEyebrow;

  /// Heading on the create-incident screen.
  ///
  /// In en, this message translates to:
  /// **'Dispatch a new incident'**
  String get newIncidentTitle;

  /// Section eyebrow above the edit-incident heading.
  ///
  /// In en, this message translates to:
  /// **'Update incident'**
  String get updateIncidentEyebrow;

  /// Heading on the edit-incident screen.
  ///
  /// In en, this message translates to:
  /// **'Edit live mission details'**
  String get editIncidentTitle;

  /// Subhead under the edit-incident heading.
  ///
  /// In en, this message translates to:
  /// **'Keep dispatch information current as access, hazards, and mission status change.'**
  String get editIncidentSubtitle;

  /// Field label / hint for the incident title input.
  ///
  /// In en, this message translates to:
  /// **'Incident title'**
  String get incidentTitleLabel;

  /// Field label / hint for the incident location input.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get incidentLocationLabel;

  /// Field label for the incident dispatch-notes input.
  ///
  /// In en, this message translates to:
  /// **'Dispatch notes'**
  String get incidentNotesLabel;

  /// Placeholder hint inside the dispatch-notes input on the edit-incident screen.
  ///
  /// In en, this message translates to:
  /// **'Updated incident notes'**
  String get incidentNotesEditHint;

  /// Title of the active/resolved switch on the edit-incident screen.
  ///
  /// In en, this message translates to:
  /// **'Incident active'**
  String get incidentActiveTitle;

  /// Subtitle of the active/resolved switch on the edit-incident screen.
  ///
  /// In en, this message translates to:
  /// **'Turn this off when the incident is resolved or no longer needs live response tracking.'**
  String get incidentActiveSubtitle;

  /// Generic cancel button (forms, dialogs).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Submit button on the edit-incident screen.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// Generic short validation error shown beneath an empty required text field.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// Label for a responder's response status on an incident.
  ///
  /// In en, this message translates to:
  /// **'{status, select, responding{Responding} pending{Pending} notAvailable{Not Available} other{Unknown}}'**
  String responseStatus(String status);
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
