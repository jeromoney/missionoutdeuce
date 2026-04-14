import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:missionout_responder/services/responder_api.dart';

void main() {
  test('fetchIncidents resolves responder status via user_public_id', () async {
    final api = ResponderApi(
      client: MockClient((request) async {
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
      userEmail: 'responder@example.com',
      userPublicId: 'responder-user',
    );

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
    final api = ResponderApi(
      client: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{}', 200);
      }),
      baseUrl: 'http://example.test',
    );

    await api.submitResponse(
      incidentPublicId: 'incident-public-id',
      status: 'Responding',
      source: 'android_app',
      userEmail: 'responder@example.com',
    );

    expect(requestBody['status'], 'Responding');
    expect(requestBody['source'], 'android_app');
    expect(requestBody.containsKey('detail'), isFalse);
  });
}
