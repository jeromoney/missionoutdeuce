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
    String? userEmail,
    String? userName,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/incidents'),
      headers: _headers(userEmail: userEmail),
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
          (item) => ResponderIncident.fromJson(item, responderName: userName),
        )
        .toList();
  }

  Map<String, String> _headers({String? userEmail}) {
    final trimmedEmail = userEmail?.trim();
    if (trimmedEmail == null || trimmedEmail.isEmpty) {
      return const {};
    }

    return {'X-MissionOut-User-Email': trimmedEmail};
  }
}
