import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

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

  Future<ResponseRecord> submitResponse({
    required String incidentPublicId,
    required ResponseStatus status,
    required String source,
    String? accessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/incidents/$incidentPublicId/responses'),
      headers: {
        'Content-Type': 'application/json',
        ..._headers(accessToken: accessToken),
      },
      body: jsonEncode({'status': status.label, 'source': source}),
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
    return ResponseRecord.fromJson(decoded);
  }

  Future<void> registerWebPush({
    required String endpoint,
    required String p256dh,
    required String auth,
    String? accessToken,
    String? teamPublicId,
    String? userAgent,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/devices/web-push'),
      headers: {
        'Content-Type': 'application/json',
        ..._headers(accessToken: accessToken),
      },
      body: jsonEncode({
        'client': 'responder',
        'endpoint': endpoint,
        'keys': {'p256dh': p256dh, 'auth': auth},
        if (teamPublicId != null) 'team_public_id': teamPublicId,
        if (userAgent != null) 'user_agent': userAgent,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed for POST /devices/web-push (${response.statusCode})',
      );
    }
  }

  Future<void> unregisterWebPush({
    required String endpoint,
    String? accessToken,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/devices/web-push'),
      headers: {
        'Content-Type': 'application/json',
        ..._headers(accessToken: accessToken),
      },
      body: jsonEncode({'endpoint': endpoint}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed for DELETE /devices/web-push (${response.statusCode})',
      );
    }
  }

  Map<String, String> _headers({String? accessToken}) {
    final trimmed = accessToken?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const {};
    }

    return {'Authorization': 'Bearer $trimmed'};
  }
}
