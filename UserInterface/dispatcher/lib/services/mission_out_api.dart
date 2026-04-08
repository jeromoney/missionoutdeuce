import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/dashboard_snapshot.dart';
import '../models/incident_draft.dart';
import '../models/incident_update.dart';
import '../models/records.dart';

class MissionOutApi {
  MissionOutApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? resolveApiBaseUrl();

  final http.Client _client;
  final String _baseUrl;

  String get baseUrl => _baseUrl;

  // The UI/backend contract for these routes lives in docs/api-contracts.md.
  Future<DashboardSnapshot> fetchDashboard({String? userEmail}) async {
    final incidentsFuture = _getList('/incidents', userEmail: userEmail);
    final eventsFuture = _getList('/events/delivery-feed');

    final responses = await Future.wait([incidentsFuture, eventsFuture]);
    final incidents = responses[0]
        .map((item) => Incident.fromJson(item))
        .toList();
    final events = responses[1]
        .map((item) => EventRecord.fromJson(item))
        .toList();

    return DashboardSnapshot(
      incidents: incidents,
      events: events,
      baseUrl: _baseUrl,
    );
  }

  Future<Incident> createIncident(IncidentDraft draft, {String? userEmail}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/incidents'),
      headers: {
        'Content-Type': 'application/json',
        ..._headers(userEmail: userEmail),
      },
      body: jsonEncode({
        'title': draft.title,
        'team': draft.team,
        'location': draft.location,
        'notes': draft.notes,
        'active': true,
      }),
    );

    return _decodeIncidentResponse(response, 'create incident');
  }

  Future<Incident> updateIncident(int incidentId, IncidentUpdate update) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/incidents/$incidentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': update.title,
        'location': update.location,
        'notes': update.notes,
        'active': update.active,
      }),
    );

    return _decodeIncidentResponse(response, 'update incident');
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

    if (decoded is Map<String, dynamic>) {
      final nested = decoded['items'] ?? decoded['data'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
    }

    throw Exception('Expected a JSON list from $path');
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

  Map<String, String> _headers({String? userEmail}) {
    final trimmedEmail = userEmail?.trim();
    if (trimmedEmail == null || trimmedEmail.isEmpty) {
      return const {};
    }

    return {'X-MissionOut-User-Email': trimmedEmail};
  }
}
