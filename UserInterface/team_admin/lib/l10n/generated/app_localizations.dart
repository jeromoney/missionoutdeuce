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
  /// **'MissionOut Team Admin'**
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

  /// Success message shown after a Firebase Email Link is sent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a sign-in link. Tap it to complete sign-in.'**
  String get linkSentMessage;

  /// Heading on the team-admin logged-out screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Team Admin'**
  String get signInTitle;

  /// Subhead under the team-admin sign-in heading.
  ///
  /// In en, this message translates to:
  /// **'Use an email sign-in link or Google to continue into your team-management workspace.'**
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

  /// Helper text under the email field on the team-admin sign-in form.
  ///
  /// In en, this message translates to:
  /// **'We will send a sign-in link to this email address.'**
  String get emailFieldHelpInitial;

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

  /// Logout button in the home-screen header.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// Generic Cancel button in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Confirmation button text for permanently deleting a team member.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// Confirmation button text for reactivating a team member.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activateAction;

  /// Confirmation button text for deactivating a team member.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateAction;

  /// Fallback shown when a relative-time value is missing or in the future.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// Subtitle next to the brand lockup on the home screen header.
  ///
  /// In en, this message translates to:
  /// **'Team Admin workspace for {teamName}. Manage one team only: memberships, team-scoped roles, device readiness, and team-level visibility.'**
  String homeBrandSubtitle(String teamName);

  /// Title on the Active members summary card.
  ///
  /// In en, this message translates to:
  /// **'Active members'**
  String get summaryActiveMembersTitle;

  /// Subtitle on the Active members summary card.
  ///
  /// In en, this message translates to:
  /// **'Users currently active in this one managed team.'**
  String get summaryActiveMembersSubtitle;

  /// Title on the Team admins summary card.
  ///
  /// In en, this message translates to:
  /// **'Team admins'**
  String get summaryTeamAdminsTitle;

  /// Subtitle on the Team admins summary card.
  ///
  /// In en, this message translates to:
  /// **'Members who can manage roles and activation.'**
  String get summaryTeamAdminsSubtitle;

  /// Title on the Device issues summary card.
  ///
  /// In en, this message translates to:
  /// **'Device issues'**
  String get summaryDeviceIssuesTitle;

  /// Subtitle on the Device issues summary card.
  ///
  /// In en, this message translates to:
  /// **'Members with device state needing follow-up.'**
  String get summaryDeviceIssuesSubtitle;

  /// Title of the team memberships panel.
  ///
  /// In en, this message translates to:
  /// **'Team memberships'**
  String get membersPanelTitle;

  /// Subtitle of the team memberships panel.
  ///
  /// In en, this message translates to:
  /// **'Invite, activate, deactivate, and role-manage users for this one existing team.'**
  String get membersPanelSubtitle;

  /// Button to open the add-member dialog.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMemberButton;

  /// Disabled-state label on the add-member button when backend CRUD routes are missing.
  ///
  /// In en, this message translates to:
  /// **'CRUD unavailable'**
  String get crudUnavailableButton;

  /// Empty-state when backend CRUD is supported but the team has no members yet.
  ///
  /// In en, this message translates to:
  /// **'No team members returned yet.'**
  String get noMembersReturned;

  /// Empty-state when backend does not expose membership routes.
  ///
  /// In en, this message translates to:
  /// **'This backend is connected, but it does not expose team membership data yet.'**
  String get noMembershipsExposed;

  /// Pill label for an inactive team member.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get pillInactive;

  /// Pill label showing when a member was last seen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String lastSeenLabel(String time);

  /// Tooltip on the per-member overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActionsTooltip;

  /// Overflow menu item to permanently delete a team member.
  ///
  /// In en, this message translates to:
  /// **'Delete member...'**
  String get deleteMemberMenuItem;

  /// Title of the team context panel.
  ///
  /// In en, this message translates to:
  /// **'Team context'**
  String get teamContextTitle;

  /// Subtitle of the team context panel.
  ///
  /// In en, this message translates to:
  /// **'This app manages one existing team only. Team creation and global administration live elsewhere.'**
  String get teamContextSubtitle;

  /// Title of the add-member dialog.
  ///
  /// In en, this message translates to:
  /// **'Add team member'**
  String get addMemberDialogTitle;

  /// Title of the edit-member dialog.
  ///
  /// In en, this message translates to:
  /// **'Edit member'**
  String get editMemberDialogTitle;

  /// Label on the name input field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameFieldLabel;

  /// Label on the phone input field.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneFieldLabel;

  /// Placeholder for the phone input field.
  ///
  /// In en, this message translates to:
  /// **'555 123 4567'**
  String get phoneFieldHint;

  /// Checkbox label for the team_admin role.
  ///
  /// In en, this message translates to:
  /// **'Team Admin'**
  String get roleTeamAdmin;

  /// Checkbox label for the dispatcher role.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get roleDispatcher;

  /// Checkbox label for the responder role.
  ///
  /// In en, this message translates to:
  /// **'Responder'**
  String get roleResponder;

  /// Submit button on the edit-member dialog.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// Validation error shown for an empty required field.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredFieldError;

  /// Title of the activate-member confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Activate member?'**
  String get activateMemberTitle;

  /// Title of the deactivate-member confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Deactivate member?'**
  String get deactivateMemberTitle;

  /// Body of the activate-member confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Reactivate {name} for {teamName}?'**
  String activateMemberBody(String name, String teamName);

  /// Body of the deactivate-member confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}? Team Admin should prefer deactivation over hard deletion so operational history remains auditable.'**
  String deactivateMemberBody(String name);

  /// Title of the delete-member confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete member?'**
  String get deleteMemberTitle;

  /// Body of the delete-member confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove {name} from {teamName}? This cannot be undone — re-add them via \"Add member\" if you change your mind. Deactivate instead if they may return.'**
  String deleteMemberBody(String name, String teamName);

  /// Status banner after a team member is added.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to {teamName}.'**
  String memberAdded(String name, String teamName);

  /// Status banner after a team member's roles are updated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}.'**
  String memberUpdated(String name);

  /// Status banner after activating a member.
  ///
  /// In en, this message translates to:
  /// **'Activated {name}.'**
  String memberActivated(String name);

  /// Status banner after deactivating a member.
  ///
  /// In en, this message translates to:
  /// **'Deactivated {name}.'**
  String memberDeactivated(String name);

  /// Status banner after a member is removed.
  ///
  /// In en, this message translates to:
  /// **'Removed {name} from {teamName}.'**
  String memberRemoved(String name, String teamName);

  /// Status banner shown when invite/create paths are not supported by the backend.
  ///
  /// In en, this message translates to:
  /// **'This backend does not expose team membership CRUD yet. Member invites and device management still need backend routes.'**
  String get crudUnavailableInvites;

  /// Status banner shown when role-edit path is not supported by the backend.
  ///
  /// In en, this message translates to:
  /// **'This backend does not expose team membership CRUD yet. Member role edits still need backend routes.'**
  String get crudUnavailableEdits;

  /// Status banner shown when activate/deactivate is not supported by the backend.
  ///
  /// In en, this message translates to:
  /// **'This backend does not expose activate/deactivate membership routes yet. Member state changes still need backend support.'**
  String get crudUnavailableActivate;

  /// Status banner shown when delete path is not supported by the backend.
  ///
  /// In en, this message translates to:
  /// **'This backend does not expose membership deletion yet. Permanent removals still need backend support.'**
  String get crudUnavailableDelete;

  /// ICU select that maps a device-health token to its localized label.
  ///
  /// In en, this message translates to:
  /// **'{value, select, healthy{Healthy} unverified{Unverified} inactive{Inactive} needsReview{Needs review} noDevice{No device} other{{value}}}'**
  String deviceHealth(String value);

  /// Pill label for an active member whose device is reachable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get memberStatusAvailable;
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
