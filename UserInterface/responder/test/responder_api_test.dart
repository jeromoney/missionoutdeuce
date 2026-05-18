import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:missionout_responder/services/responder_api.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_models/shared_models.dart';

ResponderApi _apiWithAuth(
  Future<http.Response> Function(http.Request) handler, {
  String token = 'test-jwt',
}) {
  return ResponderApi(
    client: AuthHeaderClient(
      MockClient(handler),
      () async => token,
    ),
    baseUrl: 'http://example.test',
  );
}

void main() {
  test('fetchIncidents resolves responder status via user_public_id', () async {
    String? capturedAuth;
    final api = _apiWithAuth((request) async {
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
    });

    final incidents = await api.fetchIncidents(userPublicId: 'responder-user');

    expect(capturedAuth, 'Bearer test-jwt');
    expect(incidents, hasLength(1));
    final incident = incidents.first;
    expect(incident.teamPublicId, 'team-public-id');
    expect(incident.status, ResponseStatus.responding);
    expect(incident.responses, hasLength(2));
    expect(
      incident.responses
          .where((response) => response.userPublicId == 'responder-user')
          .single
          .updated,
      DateTime.utc(2020, 1, 3, 12),
    );
  });

  test('submitResponse sends canonical source field', () async {
    late Map<String, dynamic> requestBody;
    String? capturedAuth;
    final api = _apiWithAuth((request) async {
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
    });

    final result = await api.submitResponse(
      incidentPublicId: 'incident-public-id',
      status: ResponseStatus.responding,
      source: 'android_app',
    );

    expect(capturedAuth, 'Bearer test-jwt');
    expect(requestBody['status'], 'Responding');
    expect(requestBody['source'], 'android_app');
    expect(requestBody.containsKey('detail'), isFalse);
    expect(result.userPublicId, 'responder-user');
    expect(result.status, ResponseStatus.responding);
    expect(result.rank, 0);
  });

  group('fetchIncidents edge cases', () {
    test('returns null status when responses is empty', () async {
      final api = ResponderApi(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'public_id': 'incident-1',
                'team_public_id': 'team-1',
                'title': 'Mission',
                'location': 'Trail',
                'created': '2026-05-01T12:00:00Z',
                'notes': '',
                'responses': const [],
              },
            ]),
            200,
          );
        }),
        baseUrl: 'http://example.test',
      );

      final incidents = await api.fetchIncidents(userPublicId: 'responder-user');

      expect(incidents, hasLength(1));
      expect(incidents.first.status, isNull);
    });

    test('every incident status is null when userPublicId is omitted',
        () async {
      final api = ResponderApi(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'public_id': 'incident-1',
                'team_public_id': 'team-1',
                'title': 'Mission',
                'location': 'Trail',
                'created': '2026-05-01T12:00:00Z',
                'notes': '',
                'responses': [
                  {
                    'user_public_id': 'someone-else',
                    'status': 'Responding',
                    'rank': 0,
                    'updated': '2026-05-01T12:00:00Z',
                  },
                ],
              },
            ]),
            200,
          );
        }),
        baseUrl: 'http://example.test',
      );

      final incidents = await api.fetchIncidents();

      expect(incidents, hasLength(1));
      expect(incidents.first.status, isNull);
    });

    test('throws when /incidents returns a non-2xx status', () async {
      final api = ResponderApi(
        client: MockClient((request) async {
          return http.Response('boom', 503);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.fetchIncidents(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when /incidents body is not a JSON list', () async {
      final api = ResponderApi(
        client: MockClient((request) async {
          return http.Response(jsonEncode({'items': []}), 200);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.fetchIncidents(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('submitResponse edge cases', () {
    test('throws on non-2xx status', () async {
      final api = ResponderApi(
        client: MockClient((request) async {
          return http.Response('forbidden', 403);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.submitResponse(
          incidentPublicId: 'incident-1',
          status: ResponseStatus.responding,
          source: 'android_app',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when the response body is not a JSON object', () async {
      final api = ResponderApi(
        client: MockClient((request) async {
          return http.Response(jsonEncode(const []), 201);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.submitResponse(
          incidentPublicId: 'incident-1',
          status: ResponseStatus.responding,
          source: 'android_app',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('registerWebPush', () {
    test('posts subscription details with auth header', () async {
      late Map<String, dynamic> requestBody;
      String? capturedAuth;
      String capturedMethod = '';
      Uri? capturedUri;
      final api = _apiWithAuth(
        (request) async {
          capturedAuth = request.headers['Authorization'];
          capturedMethod = request.method;
          capturedUri = request.url;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 204);
        },
        token: 'jwt',
      );

      await api.registerWebPush(
        endpoint: 'https://push.example/abc',
        p256dh: 'key1',
        auth: 'key2',
        userAgent: 'Mozilla/5.0',
      );

      expect(capturedMethod, 'POST');
      expect(capturedUri.toString(), 'http://example.test/devices/web-push');
      expect(capturedAuth, 'Bearer jwt');
      expect(requestBody['client'], 'responder');
      expect(requestBody['endpoint'], 'https://push.example/abc');
      expect(requestBody['keys'], {'p256dh': 'key1', 'auth': 'key2'});
      expect(requestBody['user_agent'], 'Mozilla/5.0');
    });

    test('omits optional fields when not provided', () async {
      late Map<String, dynamic> requestBody;
      final api = ResponderApi(
        client: MockClient((request) async {
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 204);
        }),
        baseUrl: 'http://example.test',
      );

      await api.registerWebPush(
        endpoint: 'https://push.example/abc',
        p256dh: 'k1',
        auth: 'k2',
      );

      expect(requestBody.containsKey('user_agent'), isFalse);
    });

    test('throws on non-2xx status', () async {
      final api = ResponderApi(
        client: MockClient((request) async {
          return http.Response('boom', 500);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.registerWebPush(
          endpoint: 'https://push.example/abc',
          p256dh: 'k1',
          auth: 'k2',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('unregisterWebPush', () {
    test('sends DELETE with endpoint payload', () async {
      late Map<String, dynamic> requestBody;
      String capturedMethod = '';
      final api = ResponderApi(
        client: MockClient((request) async {
          capturedMethod = request.method;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 204);
        }),
        baseUrl: 'http://example.test',
      );

      await api.unregisterWebPush(endpoint: 'https://push.example/abc');

      expect(capturedMethod, 'DELETE');
      expect(requestBody['endpoint'], 'https://push.example/abc');
    });

    test('throws on non-2xx status', () async {
      final api = ResponderApi(
        client: MockClient((request) async {
          return http.Response('boom', 500);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.unregisterWebPush(endpoint: 'https://push.example/abc'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
