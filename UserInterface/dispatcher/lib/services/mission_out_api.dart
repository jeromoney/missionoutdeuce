import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_auth/shared_auth.dart';

import '../app_config.dart';
import '../models/dashboard_snapshot.dart';
import '../models/incident_draft.dart';
import '../models/incident_update.dart';
import '../models/records.dart';

typedef AccessTokenProvider = Future<String?> Function();

// Wraps an http.Client and stamps Authorization: Bearer onto every outbound
// request. Centralizing this prevents call sites from forgetting to forward
// the token and silently issuing unauthenticated requests. The provider is
// async so it can await `AuthController.ensureFreshAccessToken()` and
// transparently refresh tokens that are about to expire.
class AuthHeaderClient extends http.BaseClient {
  AuthHeaderClient(this._inner, this._tokenProvider);

  final http.Client _inner;
  final AccessTokenProvider _tokenProvider;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = (await _tokenProvider())?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class MissionOutApi {
  MissionOutApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? resolveApiBaseUrl();

  final http.Client _client;
  final String _baseUrl;

  String get baseUrl => _baseUrl;

  // The UI/backend contract for these routes lives in docs/api-contracts.md.
  Future<DashboardSnapshot> fetchDashboard({
    List<AuthTeamMembership> memberships = const [],
  }) async {
    // /incidents is the primary panel — its failure aborts the load. Other
    // panels are fetched optionally so a single 4xx doesn't blank the screen.
    final incidentsFuture = _getList('/incidents');
    final eventsFuture = _getOptionalList(
      '/events/delivery-feed',
      onError: (error) =>
          debugPrint('[Dispatcher] delivery feed unavailable: $error'),
    );
    final memberFutures = memberships
        .map((membership) => membership.teamPublicId.trim())
        .where((teamPublicId) => teamPublicId.isNotEmpty)
        .map(
          (teamPublicId) => _getOptionalList('/teams/$teamPublicId/members'),
        )
        .toList();

    final responses = await Future.wait([
      incidentsFuture,
      eventsFuture,
      ...memberFutures,
    ]);
    final incidents = responses[0]
        .map((item) => Incident.fromJson(item))
        .toList();
    final events = responses[1]
        .map((item) => EventRecord.fromJson(item))
        .toList();
    final responderNamesByPublicId = <String, String>{};
    for (final memberList in responses.skip(2)) {
      for (final member in memberList) {
        final userPublicId = member['user_public_id'] as String? ?? '';
        final name = member['name'] as String? ?? '';
        if (userPublicId.isEmpty || name.isEmpty) {
          continue;
        }
        responderNamesByPublicId[userPublicId] = name;
      }
    }
    final teamNamesByPublicId = {
      for (final membership in memberships)
        if (membership.teamPublicId.isNotEmpty)
          membership.teamPublicId: membership.teamName,
    };

    return DashboardSnapshot(
      incidents: incidents,
      events: events,
      baseUrl: _baseUrl,
      teamNamesByPublicId: teamNamesByPublicId,
      responderNamesByPublicId: responderNamesByPublicId,
    );
  }

  Future<Incident> createIncident(
    IncidentDraft draft, {
    required String teamPublicId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/incidents'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': draft.title,
        'team_public_id': teamPublicId,
        'location': draft.location,
        'notes': draft.notes,
        'active': true,
      }),
    );

    return _decodeIncidentResponse(response, 'create incident');
  }

  Future<Incident> updateIncident(
    String incidentPublicId,
    IncidentUpdate update,
  ) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/incidents/$incidentPublicId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': update.title,
        'location': update.location,
        'notes': update.notes,
        'active': update.active,
      }),
    );

    return _decodeIncidentResponse(response, 'update incident');
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed for $path (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }

    if (decoded is Map<String, dynamic>) {
      final nested = decoded['items'] ?? decoded['data'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
    }

    throw Exception('Expected a JSON list from $path');
  }

  Future<List<Map<String, dynamic>>> _getOptionalList(
    String path, {
    void Function(Object error)? onError,
  }) async {
    try {
      return await _getList(path);
    } catch (error) {
      onError?.call(error);
      return const [];
    }
  }

  Incident _decodeIncidentResponse(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to $action (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return Incident.fromJson(decoded);
    }

    throw Exception('Expected a JSON object when attempting to $action');
  }
}
