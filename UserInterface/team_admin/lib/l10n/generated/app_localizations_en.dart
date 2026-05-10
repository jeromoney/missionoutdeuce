// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get emailMeCodeButton => 'Email me a sign-in code';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleNotConfigured => 'Google login not configured';
}
