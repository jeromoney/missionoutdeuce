import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import 'app_config.dart';
import 'app_palette.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/logged_out_screen.dart';
import 'screens/responder_home_screen.dart';
import 'services/native_alert_bridge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  unawaited(nativeAlertBridge.initialize());
  runApp(const MissionOutResponderApp());
}

/// Exposed for integration tests to inject a stub [http.Client].
Widget buildApp({http.Client? httpClient}) =>
    MissionOutResponderApp(httpClient: httpClient);

class MissionOutResponderApp extends StatefulWidget {
  const MissionOutResponderApp({super.key, this.httpClient});

  final http.Client? httpClient;

  @override
  State<MissionOutResponderApp> createState() => _MissionOutResponderAppState();
}

class _MissionOutResponderAppState extends State<MissionOutResponderApp> {
  late final AuthController auth;

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    auth = AuthController(
      backendBaseUrl: resolveApiBaseUrl(),
      requestedClient: 'responder',
      loggedOutRoleLabel: 'Responder',
      emailLinkContinueUrl:
          emailLinkContinueUrl.isEmpty ? null : emailLinkContinueUrl,
      httpClient: widget.httpClient,
    );
    unawaited(auth.checkIncomingEmailLink()); // handles web
    _initAppLinks();
  }

  void _initAppLinks() {
    final appLinks = AppLinks();
    appLinks.getInitialLink().then(_handleIncomingLink).catchError(_onLinkError);
    _linkSub = appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: _onLinkError,
    );
  }

  Future<void> _handleIncomingLink(Uri? uri) async {
    if (uri == null) return;
    if (!auth.isSignInWithEmailLink(uri.toString())) return;
    try {
      final completed = await auth.handleMobileDeepLink(uri.toString());
      if (!completed) {
        _showSnackBar(
          'Open the sign-in link on the device where you entered your email, or request a new link.',
        );
      }
    } catch (e) {
      _showSnackBar('Sign-in failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _onLinkError(Object error) {
    _showSnackBar('Could not process sign-in link: $error');
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildMissionOutTheme(accent: ResponderPalette.accent),
      home: AuthGate(
        auth: auth,
        loggedInBuilder: (auth) => ResponderHomeScreen(auth: auth),
        loggedOutBuilder: (auth) => LoggedOutScreen(
          key: ValueKey(auth.rejectedEmail),
          rejectedEmail: auth.rejectedEmail,
          onSendSignInLink: auth.sendSignInLinkToEmail,
          onGoogleLogin: auth.loginWithGoogle,
          googleLoginEnabled: auth.canUseGoogleLogin,
          roleLabel: auth.roleLabel,
        ),
      ),
    );
  }
}

