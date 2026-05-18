// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MissionOut';

  @override
  String get emailRequired => 'Enter an email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get linkSentMessage =>
      'Check your email for a sign-in link. Tap it to complete sign-in.';

  @override
  String get signInTitle => 'Sign in to mission control';

  @override
  String get signInSubtitle =>
      'Use an email sign-in link or Google to continue into the dispatcher workspace.';

  @override
  String get signInBrandSubtitle =>
      'Secure sign-in for active MissionOut operations.';

  @override
  String get sectionEyebrowAccess => 'Access';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailFieldHint => 'name@example.com';

  @override
  String get emailFieldHelp =>
      'We will send a sign-in link to this email address.';

  @override
  String get sendingButton => 'Sending link...';

  @override
  String get emailMeCodeButton => 'Email me a sign-in link';

  @override
  String get resendLinkButton => 'Resend link';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleNotConfigured => 'Google login not configured';

  @override
  String get errorLoadIncidents => 'Could not load incident data.';

  @override
  String get brandSubtitle =>
      'Mission control for recent dispatch activity, team visibility, and live responder coordination.';

  @override
  String get tooltipAccount => 'Account';

  @override
  String get logOut => 'Log out';

  @override
  String get metricActiveLabel => 'Active';

  @override
  String get metricCreatedLabel => 'Created';

  @override
  String get summaryActiveTitle => 'Active';

  @override
  String get summaryActiveSubtitle =>
      'Open incidents from the last 7 days in the current feed.';

  @override
  String get summaryRespondingSubtitle =>
      'Confirmed field responders across the recent incident feed.';

  @override
  String get summaryPendingSubtitle =>
      'Awaiting acknowledgement in the last-7-days incident feed.';

  @override
  String get emptyIncidentTitle => 'No active incidents yet';

  @override
  String get teamFallbackName => 'Assigned team';

  @override
  String get dispatchBoardTitle => 'Dispatch Board';

  @override
  String get dispatchBoardSubtitle =>
      'Open missions, team load, and responder acknowledgement state.';

  @override
  String get createIncidentButton => 'Create incident';

  @override
  String get incidentStateActive => 'Active';

  @override
  String get incidentStateResolved => 'Resolved';

  @override
  String get incidentDetailTitle => 'Incident Detail';

  @override
  String get incidentDetailSubtitle =>
      'Dispatch notes, responder roster, and mission context.';

  @override
  String get editIncidentButton => 'Edit incident';

  @override
  String responseUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get responderUnknown => 'Unknown responder';

  @override
  String responderFallbackName(String prefix) {
    return 'Responder $prefix';
  }

  @override
  String get deliveryFeedTitle => 'Delivery Feed';

  @override
  String get deliveryFeedSubtitle =>
      'Push attempts, acknowledgements, and escalation activity.';

  @override
  String get viewLogsButton => 'View logs';

  @override
  String get newIncidentEyebrow => 'New incident';

  @override
  String get newIncidentTitle => 'Dispatch a new incident';

  @override
  String get updateIncidentEyebrow => 'Update incident';

  @override
  String get editIncidentTitle => 'Edit live mission details';

  @override
  String get editIncidentSubtitle =>
      'Keep dispatch information current as access, hazards, and mission status change.';

  @override
  String get incidentTitleLabel => 'Incident title';

  @override
  String get incidentLocationLabel => 'Location';

  @override
  String get incidentNotesLabel => 'Dispatch notes';

  @override
  String get incidentNotesEditHint => 'Updated incident notes';

  @override
  String get incidentActiveTitle => 'Incident active';

  @override
  String get incidentActiveSubtitle =>
      'Turn this off when the incident is resolved or no longer needs live response tracking.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveChangesButton => 'Save changes';

  @override
  String get fieldRequired => 'Required';

  @override
  String responseStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'responding': 'Responding',
      'pending': 'Pending',
      'notAvailable': 'Not Available',
      'other': 'Unknown',
    });
    return '$_temp0';
  }
}
