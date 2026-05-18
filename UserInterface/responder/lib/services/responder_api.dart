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

  Future<List<ResponderIncident>> fetchIncidents({String? userPublicId}) async {
    final response = await _client.get(Uri.parse('$_baseUrl/incidents'));

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
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/incidents/$incidentPublicId/responses'),
      headers: const {'Content-Type': 'application/json'},
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
    String? userAgent,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/devices/web-push'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client': 'responder',
        'endpoint': endpoint,
        'keys': {'p256dh': p256dh, 'auth': auth},
        if (userAgent != null) 'user_agent': userAgent,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed for POST /devices/web-push (${response.statusCode})',
      );
    }
  }

  Future<void> unregisterWebPush({required String endpoint}) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/devices/web-push'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'endpoint': endpoint}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed for DELETE /devices/web-push (${response.statusCode})',
      );
    }
  }
}
