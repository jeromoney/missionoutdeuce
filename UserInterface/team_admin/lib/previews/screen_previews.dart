import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:shared_previews/shared_previews.dart';

import '../app_palette.dart';
import '../models/team_admin_models.dart';
import '../screens/logged_out_screen.dart';
import '../screens/team_admin_home_screen.dart';

const _accent = TeamAdminPalette.accent;

TeamAdminTeam _sampleTeam() {
  final now = DateTime.now();
  return TeamAdminTeam(
    publicId: 'team_alpha',
    name: 'Alpha Team',
    organization: 'MissionOut',
    region: 'Pacific Northwest',
    dispatchChannel: 'API-managed',
    notes:
        'Alpha Team manages SAR coordination for the central Cascades. Membership is curated by Team Admin; ops are routed through the dispatcher.',
    members: [
      TeamAdminMember(
        publicId: 'mem_1',
        userPublicId: 'user_1',
        teamPublicId: 'team_alpha',
        name: 'Avery Dispatcher',
        email: 'avery@missionout.example',
        phone: '+15551234567',
        roles: const ['team_admin', 'dispatcher'],
        status: 'Available',
        lastSeenAt: now.subtract(const Duration(minutes: 2)),
        devicePlatform: 'Web',
        deviceHealth: 'Healthy',
        isActive: true,
      ),
      TeamAdminMember(
        publicId: 'mem_2',
        userPublicId: 'user_2',
        teamPublicId: 'team_alpha',
        name: 'Riley Responder',
        email: 'riley@missionout.example',
        phone: '+15557654321',
        roles: const ['responder'],
        status: 'Responding',
        lastSeenAt: now.subtract(const Duration(minutes: 12)),
        devicePlatform: 'Android',
        deviceHealth: 'Healthy',
        isActive: true,
      ),
      TeamAdminMember(
        publicId: 'mem_3',
        userPublicId: 'user_3',
        teamPublicId: 'team_alpha',
        name: 'Sam Standby',
        email: 'sam@missionout.example',
        phone: '+15550003333',
        roles: const ['responder'],
        status: 'Pending',
        lastSeenAt: now.subtract(const Duration(days: 1)),
        devicePlatform: 'iOS',
        deviceHealth: 'Stale',
        isActive: false,
      ),
    ],
  );
}

TeamAdminHomeBody _body({
  required TeamAdminTeam team,
  required bool loading,
  bool memberCrudSupported = true,
  bool usingLiveData = true,
  String? statusMessage,
  String connectionLabel = 'Live data',
  String connectionDetail = 'Connected to API',
}) {
  return TeamAdminHomeBody(
    team: team,
    userInitials: 'TA',
    loading: loading,
    memberCrudSupported: memberCrudSupported,
    usingLiveData: usingLiveData,
    statusMessage: statusMessage,
    connectionLabel: connectionLabel,
    connectionDetail: connectionDetail,
    onLogout: () {},
    onCreateMember: () {},
    onEditMember: (_) {},
    onToggleMember: (_) {},
    onDeleteMember: (_) {},
  );
}

@Preview(name: 'TeamAdminHome — populated')
Widget teamAdminHomePopulated() {
  return PreviewApp(
    accent: _accent,
    child: _body(team: _sampleTeam(), loading: false),
  );
}

@Preview(name: 'TeamAdminHome — CRUD unsupported')
Widget teamAdminHomeReadOnly() {
  return PreviewApp(
    accent: _accent,
    child: _body(
      team: _sampleTeam(),
      loading: false,
      memberCrudSupported: false,
      statusMessage:
          'This backend does not expose team membership CRUD yet. Member invites still need backend routes.',
      connectionLabel: 'Read-only',
      connectionDetail: 'Membership API unavailable',
      usingLiveData: false,
    ),
  );
}

@Preview(name: 'TeamAdminHome — loading')
Widget teamAdminHomeLoading() {
  return PreviewApp(
    accent: _accent,
    child: _body(
      team: const TeamAdminTeam(
        publicId: 'team_loading',
        name: 'Loading team',
        organization: 'MissionOut',
        region: 'Current team scope',
        dispatchChannel: 'API-managed',
        notes: '',
        members: [],
      ),
      loading: true,
      connectionLabel: 'Connecting',
      connectionDetail: '',
      usingLiveData: false,
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
      roleLabel: 'Team Admin',
    ),
  );
}
