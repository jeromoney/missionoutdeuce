import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/incident.dart';

class ResponderApi {
  ResponderApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? resolveApiBaseUrl();

  final http.Client _client;
  final String _baseUrl;

  String get baseUrl => _baseUrl;

  Future<List<ResponderIncident>> fetchIncidents({
    String? accessToken,
    String? userPublicId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/incidents'),
      headers: _headers(accessToken: accessToken),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed for /incidents (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Expected a JSON list from /incidents');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (item) =>
              ResponderIncident.fromJson(item, responderPublicId: userPublicId),
        )
        .toList();
  }

  Future<ResponderIncidentResponse> submitResponse({
    required String incidentPublicId,
    required String status,
    required String source,
    String? accessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/incidents/$incidentPublicId/responses'),
      headers: {
        'Content-Type': 'application/json',
        ..._headers(accessToken: accessToken),
      },
      body: jsonEncode({'status': status, 'source': source}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed for /incidents/$incidentPublicId/responses (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Expected a JSON object from POST /incidents/$incidentPublicId/responses',
      );
    }
    return ResponderIncidentResponse.fromJson(decoded);
  }

  Map<String, String> _headers({String? accessToken}) {
    final trimmed = accessToken?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const {};
    }

    return {'Authorization': 'Bearer $trimmed'};
  }
}
