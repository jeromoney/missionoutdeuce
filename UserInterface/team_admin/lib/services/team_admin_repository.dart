import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_models/shared_models.dart';

import '../app_config.dart';
import '../data/demo_team_admin_data.dart';
import '../models/team_admin_models.dart';

class TeamAdminRepository {
  TeamAdminRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? resolveApiBaseUrl();

  final http.Client _client;
  final String _baseUrl;
  int? _currentTeamId;
  String? _currentTeamName;

  String get baseUrl => _baseUrl;

  bool get isLocalBackend {
    final uri = Uri.tryParse(_baseUrl);
    final host = uri?.host ?? _baseUrl;
    return host == '127.0.0.1' || host == 'localhost';
  }

  String get connectionLabel =>
      isLocalBackend ? 'Local FastAPI backend' : 'MissionOut backend';

  Future<TeamAdminWorkspace> loadWorkspace({
    List<AuthTeamMembership> memberships = const [],
  }) async {
    try {
      final healthFuture = _getMap('/health');
      final incidentsFuture = _getList('/incidents');
      final teamId = memberships.isNotEmpty
          ? memberships.first.teamId
          : demoManagedTeam.id;
      final membersFuture = _getOptionalList('/teams/$teamId/members');
      final devicesFuture = _getOptionalList('/teams/$teamId/devices');

      final results = await Future.wait([
        healthFuture,
        incidentsFuture,
        membersFuture,
        devicesFuture,
      ]);

      final health = results[0] as Map<String, dynamic>;
      final incidentJson = results[1] as List<Map<String, dynamic>>;
      final memberJson = results[2] as List<Map<String, dynamic>>?;
      final deviceJson = results[3] as List<Map<String, dynamic>>?;

      final preferredTeamName = memberships.isNotEmpty
          ? memberships.first.teamName
          : demoManagedTeam.name;

      final filteredIncidents = incidentJson
          .where((incident) => incident['team'] == preferredTeamName)
          .toList();
      final teamIncidents = filteredIncidents.isNotEmpty
          ? filteredIncidents
          : incidentJson;

      final resolvedTeamName = teamIncidents.isNotEmpty
          ? teamIncidents.first['team'] as String? ?? preferredTeamName
          : preferredTeamName;

      final incidents = teamIncidents
          .map(
            (incident) => TeamIncidentSummary(
              title: incident['title'] as String? ?? 'Untitled incident',
              location: incident['location'] as String? ?? 'Unknown location',
              state: (incident['active'] as bool? ?? false)
                  ? 'Active'
                  : 'Resolved',
              time: formatMissionTimestamp(
                incident['created'] as String? ?? '',
                fallback: 'Unknown',
              ),
            ),
          )
          .toList();

      final responsesList = <TeamResponseSummary>[
        for (final incident in teamIncidents)
          for (final response
              in (incident['responses'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>())
            TeamResponseSummary(
              memberName: response['name'] as String? ?? 'Unknown responder',
              incidentTitle:
                  incident['title'] as String? ?? 'Untitled incident',
              status: response['status'] as String? ?? 'Pending',
              time: formatMissionTimestamp(
                incident['created'] as String? ?? '',
                fallback: 'Unknown',
              ),
            ),
      ];

      final deviceByUserId = {
        for (final device in deviceJson ?? const <Map<String, dynamic>>[])
          device['user_id']: device,
      };
      final members = memberJson == null
          ? const <TeamAdminMember>[]
          : memberJson
                .map(
                  (member) => _memberFromJson(
                    member,
                    deviceByUserId[member['user_id']],
                  ),
                )
                .toList();

      final liveTeam = demoManagedTeam.copyWith(
        id: teamId,
        name: resolvedTeamName,
        members: members,
        incidents: incidents,
        responses: responsesList,
      );
      _currentTeamId = teamId;
      _currentTeamName = resolvedTeamName;

      final databaseLabel = health['database'] as String? ?? 'unknown';
      final memberCrudSupported = memberJson != null;
      final statusMessage = memberCrudSupported
          ? 'Connected to $connectionLabel with database status "$databaseLabel". Team members, device health, incidents, and response history are live.'
          : 'Connected to $connectionLabel with database status "$databaseLabel". Incident and response history are live, but team member and device CRUD routes are not available on this backend yet.';

      return TeamAdminWorkspace(
        team: liveTeam,
        connectionLabel: connectionLabel,
        connectionDetail: _baseUrl,
        memberCrudSupported: memberCrudSupported,
        usingLiveData: true,
        statusMessage: statusMessage,
      );
    } catch (_) {
      return TeamAdminWorkspace(
        team: demoManagedTeam,
        connectionLabel: 'Fallback demo data',
        connectionDetail: _baseUrl,
        memberCrudSupported: false,
        usingLiveData: false,
        statusMessage:
            'Could not reach $_baseUrl. Showing fallback Team Admin demo data instead.',
      );
    }
  }

  Future<TeamAdminTeam> createMember(TeamAdminMemberDraft draft) async {
    final teamId = _requireTeamId();
    final response = await _client.post(
      Uri.parse('$_baseUrl/teams/$teamId/members'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': draft.name,
        'email': draft.email,
        'phone': draft.phone,
        'roles': draft.roles,
        'is_active': draft.isActive,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create team member (${response.statusCode}).');
    }

    return _reloadTeam(teamId);
  }

  Future<TeamAdminTeam> updateMember(
    int memberId,
    TeamAdminMemberDraft draft,
  ) async {
    final teamId = _requireTeamId();
    final response = await _client.patch(
      Uri.parse('$_baseUrl/teams/$teamId/members/$memberId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roles': draft.roles, 'is_active': draft.isActive}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update team member (${response.statusCode}).');
    }

    return _reloadTeam(teamId);
  }

  Future<TeamAdminTeam> setMemberActive(int memberId, bool isActive) async {
    final teamId = _requireTeamId();
    final response = await _client.patch(
      Uri.parse('$_baseUrl/teams/$teamId/members/$memberId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'is_active': isActive}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to ${isActive ? 'activate' : 'deactivate'} team member (${response.statusCode}).',
      );
    }

    return _reloadTeam(teamId);
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed for $path (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }

    throw Exception('Expected a JSON list from $path');
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed for $path (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Expected a JSON object from $path');
  }

  Future<List<Map<String, dynamic>>?> _getOptionalList(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed for $path (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }

    throw Exception('Expected a JSON list from $path');
  }

  TeamAdminMember _memberFromJson(
    Map<String, dynamic> json, [
    Map<String, dynamic>? device,
  ]) {
    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final isActive =
        json['is_active'] as bool? ?? json['active'] as bool? ?? true;
    final lastSeenRaw = device?['last_seen'] as String?;
    final isVerified = device?['is_verified'] as bool?;
    final isDeviceActive = device?['is_active'] as bool?;

    return TeamAdminMember(
      id: json['membership_id'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown member',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      roles: roles,
      status: isActive ? 'Available' : 'Inactive',
      lastSeen: formatMissionTimestamp(lastSeenRaw ?? '', fallback: 'Unknown'),
      devicePlatform: device?['platform'] as String? ?? 'Unknown',
      deviceHealth: _deviceHealthLabel(
        isVerified: isVerified,
        isActive: isDeviceActive,
        hasDevice: device != null,
      ),
      isActive: isActive,
    );
  }

  Future<TeamAdminTeam> _reloadTeam(int teamId) async {
    final workspace = await loadWorkspace(
      memberships: [
        AuthTeamMembership(
          teamId: teamId,
          teamName: _currentTeamName ?? demoManagedTeam.name,
          roles: const [],
        ),
      ],
    );
    return workspace.team;
  }

  int _requireTeamId() {
    final teamId = _currentTeamId;
    if (teamId == null) {
      throw Exception('Team context is not loaded yet.');
    }
    return teamId;
  }

  String _deviceHealthLabel({
    required bool? isVerified,
    required bool? isActive,
    required bool hasDevice,
  }) {
    if (!hasDevice) {
      return 'No device';
    }
    if (isVerified == true && isActive == true) {
      return 'Healthy';
    }
    if (isVerified == false) {
      return 'Unverified';
    }
    if (isActive == false) {
      return 'Inactive';
    }
    return 'Needs review';
  }
}
