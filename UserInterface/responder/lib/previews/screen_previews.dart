import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_previews/shared_previews.dart';

import '../app_palette.dart';
import '../models/backup_alert.dart';
import '../models/incident.dart';
import '../screens/logged_out_screen.dart';
import '../screens/responder_home_screen.dart';
import '../services/browser_alert_channel.dart';
import '../services/native_alert_status_service.dart';
import '../services/responder_api.dart';

const _accent = ResponderPalette.accent;

List<ResponderIncident> _sampleIncidents() {
  const responderPublicId = 'user_responder_preview';
  final now = DateTime.now();
  return [
    ResponderIncident.fromIncident(
      Incident(
        publicId: 'inc_001',
        title: 'Hiker overdue at Snow Lake',
        location: 'Snow Lake Trailhead, Alpine Lakes',
        teamPublicId: 'team_alpha',
        created: now.subtract(const Duration(hours: 2)),
        notes:
            'Two hikers, lightly equipped, weather turning. Reporting party last contact 14:20.',
        responses: [
          ResponseRecord(
            userPublicId: responderPublicId,
            status: ResponseStatus.pending,
            rank: 1,
            updated: now.subtract(const Duration(minutes: 5)),
          ),
        ],
        priority: 'High',
      ),
      responderPublicId: responderPublicId,
    ),
    ResponderIncident.fromIncident(
      Incident(
        publicId: 'inc_002',
        title: 'Vehicle off road, county hwy 12',
        location: 'Mile marker 47, Hwy 12',
        teamPublicId: 'team_alpha',
        created: now.subtract(const Duration(hours: 2, minutes: 40)),
        notes: 'Single vehicle, occupants ambulatory. EMS staged.',
        responses: [
          ResponseRecord(
            userPublicId: responderPublicId,
            status: ResponseStatus.responding,
            rank: 0,
            updated: now.subtract(const Duration(minutes: 2)),
          ),
        ],
      ),
      responderPublicId: responderPublicId,
    ),
  ];
}

ResponderHomeBody _body({
  required List<ResponderIncident> incidents,
  required bool loading,
  String? loadError,
  BackupAlert? activeBackupAlert,
}) {
  final selectedIncident = incidents.isEmpty ? null : incidents.first;
  return ResponderHomeBody(
    userInitials: 'RR',
    availability: AvailabilityStatus.available,
    incidents: incidents,
    selected: 0,
    selectedIncident: selectedIncident,
    loading: loading,
    loadError: loadError,
    activeBackupAlert: activeBackupAlert,
    submittingResponse: false,
    browserAlerts: BrowserAlertChannel(api: ResponderApi(), publicKey: ''),
    nativeAlerts: NativeAlertStatusService(),
    onLogout: () {},
    onAvailabilityChanged: (_) {},
    onSelected: (_) {},
    onDismissAlert: () {},
    onOpenAlert: () {},
    onEnableBrowserAlerts: () async {},
    onSendTestAlert: () async {},
    onResponding: () async {},
    onNotAvailable: () async {},
  );
}

@Preview(name: 'ResponderHome — active mission')
Widget responderHomeActive() {
  return PreviewApp(
    accent: _accent,
    child: _body(incidents: _sampleIncidents(), loading: false),
  );
}

@Preview(name: 'ResponderHome — standby')
Widget responderHomeStandby() {
  return PreviewApp(
    accent: _accent,
    child: _body(incidents: const [], loading: false),
  );
}

@Preview(name: 'ResponderHome — incoming alert')
Widget responderHomeIncomingAlert() {
  return PreviewApp(
    accent: _accent,
    child: _body(
      incidents: _sampleIncidents(),
      loading: false,
      activeBackupAlert: const BackupAlert(
        incidentPublicId: 'inc_001',
        title: 'Page: Hiker overdue at Snow Lake',
        body: 'Snow Lake Trailhead, Alpine Lakes - 14:20',
      ),
    ),
  );
}

@Preview(name: 'ResponderHome — load error')
Widget responderHomeLoadError() {
  return PreviewApp(
    accent: _accent,
    child: _body(
      incidents: const [],
      loading: false,
      loadError: 'Could not load missions from the API.',
    ),
  );
}

@Preview(name: 'LoggedOutScreen')
Widget loggedOutScreen() {
  return PreviewApp(
    accent: _accent,
    child: LoggedOutScreen(
      onSendSignInLink: (email) async {},
      onGoogleLogin: () async {},
      googleLoginEnabled: true,
      roleLabel: 'Responder',
    ),
  );
}
