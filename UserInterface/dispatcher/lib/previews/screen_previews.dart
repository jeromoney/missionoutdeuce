import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_previews/shared_previews.dart';

import '../app_palette.dart';
import '../models/records.dart';
import '../screens/create_incident_screen.dart';
import '../screens/edit_incident_screen.dart';
import '../screens/logged_out_screen.dart';
import '../screens/mission_control_screen.dart';

const _accent = AppPalette.info;

List<Incident> _sampleIncidents() {
  const teamA = 'team_alpha';
  const teamB = 'team_bravo';
  final now = DateTime.now();
  return [
    Incident(
      publicId: 'inc_001',
      title: 'Hiker overdue at Snow Lake',
      teamPublicId: teamA,
      location: 'Snow Lake Trailhead, Alpine Lakes',
      created: now.subtract(const Duration(hours: 2)),
      notes:
          'Reporting party last contact 14:20. Two hikers, lightly equipped, weather turning.',
      responses: [
        ResponseRecord(
          userPublicId: 'user_responder_demo',
          status: ResponseStatus.responding,
          rank: 0,
          updated: now.subtract(const Duration(minutes: 5)),
        ),
        ResponseRecord(
          userPublicId: 'user_responder_2',
          status: ResponseStatus.pending,
          rank: 1,
          updated: now.subtract(const Duration(minutes: 7)),
        ),
      ],
      priority: 'High',
    ),
    Incident(
      publicId: 'inc_002',
      title: 'Vehicle off road, county hwy 12',
      teamPublicId: teamB,
      location: 'Mile marker 47, Hwy 12',
      created: now.subtract(const Duration(minutes: 40)),
      notes: 'Single vehicle, occupants ambulatory. EMS staged.',
      responses: [
        ResponseRecord(
          userPublicId: 'user_responder_3',
          status: ResponseStatus.responding,
          rank: 0,
          updated: now.subtract(const Duration(minutes: 2)),
        ),
      ],
      priority: 'Medium',
    ),
  ];
}

List<EventRecord> _sampleEventsList() {
  final now = DateTime.now();
  return [
    EventRecord(
      title: 'Dispatch sent',
      detail: 'Snow Lake page delivered to 8 responders.',
      time: now.subtract(const Duration(hours: 2)),
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFF4F6F95),
    ),
    EventRecord(
      title: 'Response confirmed',
      detail: 'Riley Responder accepted Snow Lake.',
      time: now.subtract(const Duration(minutes: 5)),
      icon: Icons.task_alt_rounded,
      color: const Color(0xFF50A36A),
    ),
  ];
}

const _teamNames = <String, String>{
  'team_alpha': 'Alpha Team',
  'team_bravo': 'Bravo Team',
};

const _responderNames = <String, String>{
  'user_responder_demo': 'Riley Responder',
  'user_responder_2': 'Pat Responder',
  'user_responder_3': 'Sam Responder',
};

@Preview(name: 'MissionControl — populated')
Widget missionControlPopulated() {
  final incidents = _sampleIncidents();
  return PreviewApp(
    accent: _accent,
    child: MissionControlBody(
      role: 'Dispatcher',
      userInitials: 'AD',
      incidents: incidents,
      events: _sampleEventsList(),
      teamNamesByPublicId: _teamNames,
      responderNamesByPublicId: _responderNames,
      selected: 0,
      loading: false,
      loadError: null,
      onLogout: () {},
      onSelectIncident: (_) {},
      onCreateIncident: () {},
      onEditIncident: () {},
    ),
  );
}

@Preview(name: 'MissionControl — empty')
Widget missionControlEmpty() {
  return PreviewApp(
    accent: _accent,
    child: MissionControlBody(
      role: 'Dispatcher',
      userInitials: 'AD',
      incidents: const [],
      events: const [],
      teamNamesByPublicId: const {},
      responderNamesByPublicId: const {},
      selected: 0,
      loading: false,
      loadError: null,
      onLogout: () {},
      onSelectIncident: (_) {},
      onCreateIncident: () {},
      onEditIncident: () {},
    ),
  );
}

@Preview(name: 'MissionControl — loading')
Widget missionControlLoading() {
  return PreviewApp(
    accent: _accent,
    child: MissionControlBody(
      role: 'Dispatcher',
      userInitials: 'AD',
      incidents: const [],
      events: const [],
      teamNamesByPublicId: const {},
      responderNamesByPublicId: const {},
      selected: 0,
      loading: true,
      loadError: null,
      onLogout: () {},
      onSelectIncident: (_) {},
      onCreateIncident: () {},
      onEditIncident: () {},
    ),
  );
}

@Preview(name: 'CreateIncidentScreen')
Widget createIncidentScreen() {
  return PreviewApp(
    accent: _accent,
    child: CreateIncidentScreen(onSubmit: (_) {}, onCancel: () {}),
  );
}

@Preview(name: 'EditIncidentScreen')
Widget editIncidentScreen() {
  final incident = _sampleIncidents().first;
  return PreviewApp(
    accent: _accent,
    child: EditIncidentScreen(
      incident: incident,
      onSubmit: (_) {},
      onCancel: () {},
    ),
  );
}

@Preview(name: 'LoggedOutScreen')
Widget loggedOutScreen() {
  return PreviewApp(
    accent: _accent,
    child: LoggedOutScreen(
      onRequestEmailCode: ({required String email}) async {},
      onVerifyEmailCode:
          ({required String email, required String code}) async {},
      onGoogleLogin: () async {},
      googleLoginEnabled: true,
      roleLabel: 'Dispatcher',
    ),
  );
}
