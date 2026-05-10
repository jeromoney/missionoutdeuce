// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'MissionOut Responder';

  @override
  String get emailRequired => 'Enter an email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get codeRequired => 'Enter the code from your email.';

  @override
  String get codeSentMessage => 'Check your email for code';

  @override
  String get signInTitle => 'Sign in to responder view';

  @override
  String get signInSubtitle => 'Use an emailed code or Google to continue.';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailFieldHint => 'example@domain.com';

  @override
  String get emailFieldHelp =>
      'We will send a sign-in link for this responder account.';

  @override
  String get verifyingButton => 'Verifying code...';

  @override
  String get sendingButton => 'Sending code...';

  @override
  String get verifyCodeButton => 'Verify code';

  @override
  String get emailMeCodeButton => 'Envíame un código por correo';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleNotConfigured => 'Google login not configured';

  @override
  String get errorLoadIncidents => 'Could not load missions from the API.';

  @override
  String get errorRefreshIncidents =>
      'Could not refresh missions after a live event.';

  @override
  String get errorMissingIncidentId =>
      'Could not submit response because the incident public ID is missing.';

  @override
  String get errorSubmitResponse => 'Could not submit your responder status.';

  @override
  String get brandSubtitle =>
      'Responder view for acknowledgements, readiness, and active mission context.';

  @override
  String get tooltipAccount => 'Account';

  @override
  String get logOut => 'Log out';

  @override
  String get incomingAlertTitle => 'Incoming mission alert';

  @override
  String get openMissionButton => 'Open mission';

  @override
  String get dismissButton => 'Dismiss';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get dialogGoUnavailableTitle => 'Go unavailable?';

  @override
  String get dialogGoUnavailableContent =>
      'If you switch to unavailable, you will not receive alerts until you change your status back.';

  @override
  String get dialogGoUnavailableConfirm => 'Go unavailable';

  @override
  String availabilityStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'available': 'Available',
      'unavailable': 'Unavailable',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

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

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get statusStandingBy => 'Standing by';

  @override
  String get standbyHeroTitle => 'Quiet until a mission arrives.';

  @override
  String get standbyHeroDescriptionAvailable =>
      'This screen stays minimal by default. When dispatch starts, the mission view takes over and response actions move to the front.';

  @override
  String get standbyHeroDescriptionUnavailable =>
      'You are currently unavailable, so the app stays in standby and no responder actions are active until you switch back.';

  @override
  String get metricStateLabel => 'State';

  @override
  String get metricStateReadyValue => 'Ready for interrupt';

  @override
  String get metricStateAlertsPausedValue => 'Alerts paused';

  @override
  String get metricDefaultModeLabel => 'Default mode';

  @override
  String get metricDefaultModeValue => 'Idle, not queue-driven';

  @override
  String get readinessHeading => 'Readiness';

  @override
  String get readinessSubtitle =>
      'Keep this device ready for the next interrupt. Notification channels are supplemental to native mobile alerting.';

  @override
  String get readinessAvailabilityTitle => 'Availability';

  @override
  String get readinessAvailabilityDetailAvailable =>
      'Responder actions will surface when a mission is assigned.';

  @override
  String get readinessAvailabilityDetailUnavailable =>
      'Alert actions stay out of the way until you are available again.';

  @override
  String get readinessNativeAlertsTitle => 'Native Android alerts';

  @override
  String get readinessBrowserAlertsTitle => 'Browser alerts';

  @override
  String get enableButton => 'Enable';

  @override
  String get fullScreenSettingsButton => 'Full-screen settings';

  @override
  String get dndSettingsButton => 'DND settings';

  @override
  String get testAlertButton => 'Test alert';

  @override
  String get savingButton => 'Saving...';

  @override
  String get missionListTitle => 'Active missions';

  @override
  String get missionListSubtitle =>
      'Review active incidents and select one to update your response.';

  @override
  String get missionNotesHeading => 'Mission notes';
}
