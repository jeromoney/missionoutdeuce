// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'MissionOut Team Admin';

  @override
  String get emailRequired => 'Enter an email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get nameRequired => 'Enter a name.';

  @override
  String get nameInvalid => 'Enter a valid name.';

  @override
  String get phoneRequired => 'Enter a phone number.';

  @override
  String get phoneInvalid => 'Enter a valid phone number.';

  @override
  String get codeRequired => 'Enter the code from your email.';

  @override
  String get codeSentMessage => 'Check your email for code';

  @override
  String get signInTitle => 'Sign in to Team Admin';

  @override
  String get signInSubtitle =>
      'Use an emailed code or Google to continue into your team-management workspace.';

  @override
  String get signInBrandSubtitle =>
      'Secure sign-in for active MissionOut operations.';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailFieldHint => 'name@example.com';

  @override
  String get emailFieldHelpInitial =>
      'We will send a one-time code for this Team Admin account.';

  @override
  String get emailFieldHelpAwaitingCode =>
      'Enter the emailed code to finish Team Admin sign-in.';

  @override
  String get codeFieldLabel => 'Code';

  @override
  String get codeFieldHint => '123456';

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
  String get logOut => 'Log out';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteAction => 'Delete';

  @override
  String get activateAction => 'Activate';

  @override
  String get deactivateAction => 'Deactivate';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String homeBrandSubtitle(String teamName) {
    return 'Team Admin workspace for $teamName. Manage one team only: memberships, team-scoped roles, device readiness, and team-level visibility.';
  }

  @override
  String get summaryActiveMembersTitle => 'Active members';

  @override
  String get summaryActiveMembersSubtitle =>
      'Users currently active in this one managed team.';

  @override
  String get summaryTeamAdminsTitle => 'Team admins';

  @override
  String get summaryTeamAdminsSubtitle =>
      'Members who can manage roles and activation.';

  @override
  String get summaryDeviceIssuesTitle => 'Device issues';

  @override
  String get summaryDeviceIssuesSubtitle =>
      'Members with device state needing follow-up.';

  @override
  String get membersPanelTitle => 'Team memberships';

  @override
  String get membersPanelSubtitle =>
      'Invite, activate, deactivate, and role-manage users for this one existing team.';

  @override
  String get addMemberButton => 'Add member';

  @override
  String get crudUnavailableButton => 'CRUD unavailable';

  @override
  String get noMembersReturned => 'No team members returned yet.';

  @override
  String get noMembershipsExposed =>
      'This backend is connected, but it does not expose team membership data yet.';

  @override
  String get pillInactive => 'Inactive';

  @override
  String lastSeenLabel(String time) {
    return 'Last seen $time';
  }

  @override
  String get moreActionsTooltip => 'More actions';

  @override
  String get deleteMemberMenuItem => 'Delete member...';

  @override
  String get teamContextTitle => 'Team context';

  @override
  String get teamContextSubtitle =>
      'This app manages one existing team only. Team creation and global administration live elsewhere.';

  @override
  String get addMemberDialogTitle => 'Add team member';

  @override
  String get editMemberDialogTitle => 'Edit member';

  @override
  String get nameFieldLabel => 'Name';

  @override
  String get phoneFieldLabel => 'Phone';

  @override
  String get phoneFieldHint => '555 123 4567';

  @override
  String get roleTeamAdmin => 'Team Admin';

  @override
  String get roleDispatcher => 'Dispatcher';

  @override
  String get roleResponder => 'Responder';

  @override
  String get saveChangesButton => 'Save changes';

  @override
  String get requiredFieldError => 'Required';

  @override
  String get activateMemberTitle => 'Activate member?';

  @override
  String get deactivateMemberTitle => 'Deactivate member?';

  @override
  String activateMemberBody(String name, String teamName) {
    return 'Reactivate $name for $teamName?';
  }

  @override
  String deactivateMemberBody(String name) {
    return 'Deactivate $name? Team Admin should prefer deactivation over hard deletion so operational history remains auditable.';
  }

  @override
  String get deleteMemberTitle => 'Delete member?';

  @override
  String deleteMemberBody(String name, String teamName) {
    return 'Permanently remove $name from $teamName? This cannot be undone — re-add them via \"Add member\" if you change your mind. Deactivate instead if they may return.';
  }

  @override
  String memberAdded(String name, String teamName) {
    return 'Added $name to $teamName.';
  }

  @override
  String memberUpdated(String name) {
    return 'Updated $name.';
  }

  @override
  String memberActivated(String name) {
    return 'Activated $name.';
  }

  @override
  String memberDeactivated(String name) {
    return 'Deactivated $name.';
  }

  @override
  String memberRemoved(String name, String teamName) {
    return 'Removed $name from $teamName.';
  }

  @override
  String get crudUnavailableInvites =>
      'This backend does not expose team membership CRUD yet. Member invites and device management still need backend routes.';

  @override
  String get crudUnavailableEdits =>
      'This backend does not expose team membership CRUD yet. Member role edits still need backend routes.';

  @override
  String get crudUnavailableActivate =>
      'This backend does not expose activate/deactivate membership routes yet. Member state changes still need backend support.';

  @override
  String get crudUnavailableDelete =>
      'This backend does not expose membership deletion yet. Permanent removals still need backend support.';

  @override
  String deviceHealth(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'healthy': 'Healthy',
      'unverified': 'Unverified',
      'inactive': 'Inactive',
      'needsReview': 'Needs review',
      'noDevice': 'No device',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String get memberStatusAvailable => 'Available';
}
