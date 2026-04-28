import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:missionout_responder/services/responder_api.dart';

void main() {
  test('fetchIncidents resolves responder status via user_public_id', () async {
    String? capturedAuth;
    final api = ResponderApi(
      client: MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response(
          jsonEncode([
            {
              'id': 14,
              'public_id': 'incident-public-id',
              'team_public_id': 'team-public-id',
              'title': 'Field mission',
              'location': 'North ridge',
              'created': '2020-01-01T12:00:00Z',
              'notes': 'Steep terrain.',
              'responses': [
                {
                  'user_public_id': 'other-user',
                  'status': 'Pending',
                  'rank': 1,
                  'updated': '2020-01-02T12:00:00Z',
                },
                {
                  'user_public_id': 'responder-user',
                  'status': 'Responding',
                  'rank': 0,
                  'updated': '2020-01-03T12:00:00Z',
                },
              ],
            },
          ]),
          200,
        );
      }),
      baseUrl: 'http://example.test',
    );

    final incidents = await api.fetchIncidents(
      accessToken: 'test-jwt',
      userPublicId: 'responder-user',
    );

    expect(capturedAuth, 'Bearer test-jwt');
    expect(incidents, hasLength(1));
    final incident = incidents.first;
    expect(incident.teamPublicId, 'team-public-id');
    expect(incident.status, 'Responding');
    expect(incident.responses, hasLength(2));
    expect(
      incident.responses
          .where((response) => response.userPublicId == 'responder-user')
          .single
          .updated,
      'January 3, 2020',
    );
  });

  test('submitResponse sends canonical source field', () async {
    late Map<String, dynamic> requestBody;
    String? capturedAuth;
    final api = ResponderApi(
      client: MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'user_public_id': 'responder-user',
            'status': 'Responding',
            'rank': 0,
            'updated': '2026-04-27T12:00:00Z',
          }),
          201,
        );
      }),
      baseUrl: 'http://example.test',
    );

    final result = await api.submitResponse(
      incidentPublicId: 'incident-public-id',
      status: 'Responding',
      source: 'android_app',
      accessToken: 'test-jwt',
    );

    expect(capturedAuth, 'Bearer test-jwt');
    expect(requestBody['status'], 'Responding');
    expect(requestBody['source'], 'android_app');
    expect(requestBody.containsKey('detail'), isFalse);
    expect(result.userPublicId, 'responder-user');
    expect(result.status, 'Responding');
    expect(result.rank, 0);
  });
}
