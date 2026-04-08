import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_models/shared_models.dart';

import '../app_config.dart';
import '../models/team_admin_models.dart';

class TeamAdminRepository {
  TeamAdminRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? resolveApiBaseUrl();

  final http.Client _client;
  final String _baseUrl;
  String? _currentTeamPublicId;
  String? _currentTeamName;
  String? _currentUserEmail;

  String get baseUrl => _baseUrl;

  bool get isLocalBackend {
    final uri = Uri.tryParse(_baseUrl);
    final host = uri?.host ?? _baseUrl;
    return host == '127.0.0.1' || host == 'localhost';
  }

  Future<TeamAdminWorkspace> loadWorkspace({
    List<AuthTeamMembership> memberships = const [],
    String? userEmail,
  }) async {
    _currentUserEmail = userEmail;
    final teamPublicId = memberships.isNotEmpty
        ? memberships.first.teamPublicId
        : '';
    final preferredTeamName = memberships.isNotEmpty
        ? memberships.first.teamName
        : 'Unassigned team';

    try {
      final healthFuture = _getMap('/health');
      final incidentsFuture = _getList('/incidents', userEmail: userEmail);
      final membersFuture = teamPublicId.isEmpty
          ? Future.value(null)
          : _getOptionalList('/teams/$teamPublicId/members');
      final devicesFuture = teamPublicId.isEmpty
          ? Future.value(null)
          : _getOptionalList('/teams/$teamPublicId/devices');

      final results = await Future.wait([
        healthFuture,
        incidentsFuture,
        membersFuture,
        devicesFuture,
      ]);

      final incidentJson = results[1] as List<Map<String, dynamic>>;
      final memberJson = results[2] as List<Map<String, dynamic>>?;
      final deviceJson = results[3] as List<Map<String, dynamic>>?;

      final teamIncidents = incidentJson;

      final resolvedTeamName = teamIncidents.isNotEmpty
          ? teamIncidents.first['team'] as String? ?? preferredTeamName
          : preferredTeamName;
      final resolvedTeamPublicId = teamIncidents.isNotEmpty
          ? teamIncidents.first['team_public_id'] as String? ??
                (memberships.isNotEmpty ? memberships.first.teamPublicId : '')
          : (memberships.isNotEmpty ? memberships.first.teamPublicId : '');

      final incidents = teamIncidents
          .map(
            (incident) => TeamIncidentSummary(
              publicId: incident['public_id'] as String? ?? '',
              teamPublicId: incident['team_public_id'] as String?,
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

      final deviceByUserPublicId = {
        for (final device in deviceJson ?? const <Map<String, dynamic>>[])
          device['user_public_id']: device,
      };
      final members = memberJson == null
          ? const <TeamAdminMember>[]
          : memberJson
                .map(
                  (member) => _memberFromJson(
                    member,
                    deviceByUserPublicId[member['user_public_id']],
                  ),
                )
                .toList();

      final liveTeam = _buildTeam(
        teamPublicId: resolvedTeamPublicId,
        teamName: resolvedTeamName,
        members: members,
        incidents: incidents,
        responses: responsesList,
      );
      _currentTeamPublicId = resolvedTeamPublicId;
      _currentTeamName = resolvedTeamName;

      final memberCrudSupported = memberJson != null;

      return TeamAdminWorkspace(
        team: liveTeam,
        memberCrudSupported: memberCrudSupported,
        usingLiveData: true,
      );
    } catch (error) {
      return TeamAdminWorkspace(
        team: _buildTeam(
          teamPublicId: memberships.isNotEmpty
              ? memberships.first.teamPublicId
              : '',
          teamName: preferredTeamName,
          members: const [],
          incidents: const [],
          responses: const [],
        ),
        memberCrudSupported: false,
        usingLiveData: false,
        statusMessage: 'Could not load team data from $_baseUrl. Error: $error',
      );
    }
  }

  Future<TeamAdminTeam> createMember(TeamAdminMemberDraft draft) async {
    final teamPublicId = _requireTeamPublicId();
    final response = await _client.post(
      Uri.parse('$_baseUrl/teams/$teamPublicId/members'),
      headers: {
        'Content-Type': 'application/json',
        ..._headers(userEmail: _currentUserEmail),
      },
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

    return _reloadTeam(teamPublicId);
  }

  Future<TeamAdminTeam> updateMember(
    String membershipPublicId,
    TeamAdminMemberDraft draft,
  ) async {
    final teamPublicId = _requireTeamPublicId();
    final response = await _client.patch(
      Uri.parse('$_baseUrl/teams/$teamPublicId/members/$membershipPublicId'),
      headers: {
        'Content-Type': 'application/json',
        ..._headers(userEmail: _currentUserEmail),
      },
      body: jsonEncode({'roles': draft.roles, 'is_active': draft.isActive}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update team member (${response.statusCode}).');
    }

    return _reloadTeam(teamPublicId);
  }

  Future<TeamAdminTeam> setMemberActive(
    String membershipPublicId,
    bool isActive,
  ) async {
    final teamPublicId = _requireTeamPublicId();
    final response = await _client.patch(
      Uri.parse('$_baseUrl/teams/$teamPublicId/members/$membershipPublicId'),
      headers: {
        'Content-Type': 'application/json',
        ..._headers(userEmail: _currentUserEmail),
      },
      body: jsonEncode({'is_active': isActive}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to ${isActive ? 'activate' : 'deactivate'} team member (${response.statusCode}).',
      );
    }

    return _reloadTeam(teamPublicId);
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    String? userEmail,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.get(
      uri,
      headers: _headers(userEmail: userEmail),
    );
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
      publicId: json['public_id'] as String? ?? '',
      userPublicId: json['user_public_id'] as String? ?? '',
      teamPublicId: json['team_public_id'] as String? ?? '',
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

  Future<TeamAdminTeam> _reloadTeam(String teamPublicId) async {
    final workspace = await loadWorkspace(
      memberships: [
        AuthTeamMembership(
          teamPublicId: teamPublicId,
          teamName: _currentTeamName ?? 'Unknown team',
          roles: const [],
        ),
      ],
      userEmail: _currentUserEmail,
    );
    return workspace.team;
  }

  String _requireTeamPublicId() {
    final teamPublicId = _currentTeamPublicId;
    if (teamPublicId == null || teamPublicId.isEmpty) {
      throw Exception('Team context is not loaded yet.');
    }
    return teamPublicId;
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

  Map<String, String> _headers({String? userEmail}) {
    final trimmedEmail = userEmail?.trim();
    if (trimmedEmail == null || trimmedEmail.isEmpty) {
      return const {};
    }

    return {'X-MissionOut-User-Email': trimmedEmail};
  }

  TeamAdminTeam _buildTeam({
    required String teamPublicId,
    required String teamName,
    required List<TeamAdminMember> members,
    required List<TeamIncidentSummary> incidents,
    required List<TeamResponseSummary> responses,
  }) {
    return TeamAdminTeam(
      publicId: teamPublicId,
      name: teamName,
      organization: 'MissionOut',
      region: 'Current team scope',
      dispatchChannel: 'API-managed',
      notes:
          'Team Admin manages memberships, roles, device readiness, and team visibility for one existing operational team.',
      members: members,
      incidents: incidents,
      responses: responses,
    );
  }
}
