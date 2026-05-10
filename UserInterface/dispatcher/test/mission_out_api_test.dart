import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:missionout/services/mission_out_api.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('AuthHeaderClient', () {
    test('stamps Authorization: Bearer <token> from the async provider',
        () async {
      String? capturedAuth;
      final inner = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });
      final wrapped = AuthHeaderClient(inner, () async => 'jwt');

      await wrapped.get(Uri.parse('http://example.test/x'));

      expect(capturedAuth, 'Bearer jwt');
    });

    test('omits Authorization when the provider returns null', () async {
      String? capturedAuth = 'sentinel';
      final inner = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });
      final wrapped = AuthHeaderClient(inner, () async => null);

      await wrapped.get(Uri.parse('http://example.test/x'));

      expect(capturedAuth, isNull);
    });

    test('omits Authorization when the provider returns empty string',
        () async {
      String? capturedAuth = 'sentinel';
      final inner = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });
      final wrapped = AuthHeaderClient(inner, () async => '');

      await wrapped.get(Uri.parse('http://example.test/x'));

      expect(capturedAuth, isNull);
    });

    test('trims surrounding whitespace from the token', () async {
      String? capturedAuth;
      final inner = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });
      final wrapped = AuthHeaderClient(inner, () async => '  jwt  ');

      await wrapped.get(Uri.parse('http://example.test/x'));

      expect(capturedAuth, 'Bearer jwt');
    });

    test('omits Authorization when the trimmed token is empty', () async {
      String? capturedAuth = 'sentinel';
      final inner = MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        return http.Response('{}', 200);
      });
      final wrapped = AuthHeaderClient(inner, () async => '   ');

      await wrapped.get(Uri.parse('http://example.test/x'));

      expect(capturedAuth, isNull);
    });
  });

  group('MissionOutApi.fetchDashboard', () {
    test('aggregates incidents, events, and member name lookups', () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          final path = request.url.path;
          if (path == '/incidents') {
            return http.Response(
              jsonEncode([
                {
                  'public_id': 'incident-1',
                  'team_public_id': 'team-1',
                  'title': 'Mission',
                  'location': 'Trail',
                  'created': '2026-05-01T12:00:00Z',
                  'notes': '',
                  'active': true,
                  'responses': const [],
                },
              ]),
              200,
            );
          }
          if (path == '/events/delivery-feed') {
            return http.Response(
              jsonEncode([
                {
                  'title': 'Delivered',
                  'detail': 'Pager delivered',
                  'time': '2026-05-01T12:05:00Z',
                  'icon': 'task_alt',
                  'color': '#FF8800',
                },
              ]),
              200,
            );
          }
          if (path == '/teams/team-1/members') {
            return http.Response(
              jsonEncode([
                {'user_public_id': 'u-1', 'name': 'Alex Responder'},
                {'user_public_id': 'u-2', 'name': 'Pat Dispatcher'},
                {'user_public_id': '', 'name': 'Skipped'},
                {'user_public_id': 'u-3', 'name': ''},
              ]),
              200,
            );
          }
          return http.Response('not found', 404);
        }),
        baseUrl: 'http://example.test',
      );

      final snapshot = await api.fetchDashboard(
        memberships: const [
          AuthTeamMembership(
            teamPublicId: 'team-1',
            teamName: 'Alpha team',
            roles: ['dispatcher'],
          ),
        ],
      );

      expect(snapshot.baseUrl, 'http://example.test');
      expect(snapshot.incidents, hasLength(1));
      expect(snapshot.incidents.first.publicId, 'incident-1');
      expect(snapshot.events, hasLength(1));
      expect(snapshot.events.first.title, 'Delivered');
      expect(snapshot.teamNamesByPublicId, {'team-1': 'Alpha team'});
      expect(snapshot.responderNamesByPublicId, {
        'u-1': 'Alex Responder',
        'u-2': 'Pat Dispatcher',
      });
    });

    test('returns an empty events list when the events endpoint 404s',
        () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          if (request.url.path == '/incidents') {
            return http.Response(jsonEncode(const []), 200);
          }
          return http.Response('missing', 404);
        }),
        baseUrl: 'http://example.test',
      );

      final snapshot = await api.fetchDashboard();

      expect(snapshot.incidents, isEmpty);
      expect(snapshot.events, isEmpty);
      expect(snapshot.teamNamesByPublicId, isEmpty);
      expect(snapshot.responderNamesByPublicId, isEmpty);
    });

    test('throws when the incidents endpoint fails (primary panel)',
        () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          if (request.url.path == '/incidents') {
            return http.Response('boom', 500);
          }
          return http.Response(jsonEncode(const []), 200);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.fetchDashboard(),
        throwsA(isA<Exception>()),
      );
    });

    test('skips memberships with blank or whitespace teamPublicId',
        () async {
      final calledPaths = <String>[];
      final api = MissionOutApi(
        client: MockClient((request) async {
          calledPaths.add(request.url.path);
          if (request.url.path.startsWith('/teams/')) {
            return http.Response(jsonEncode(const []), 200);
          }
          return http.Response(jsonEncode(const []), 200);
        }),
        baseUrl: 'http://example.test',
      );

      await api.fetchDashboard(
        memberships: const [
          AuthTeamMembership(
            teamPublicId: '   ',
            teamName: 'Whitespace',
            roles: [],
          ),
          AuthTeamMembership(
            teamPublicId: '',
            teamName: 'Empty',
            roles: [],
          ),
        ],
      );

      expect(
        calledPaths.any((path) => path.startsWith('/teams/')),
        isFalse,
      );
    });

    test('accepts an envelope-shaped {items: []} body', () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          if (request.url.path == '/incidents') {
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'public_id': 'incident-1',
                    'team_public_id': 'team-1',
                    'title': 'Mission',
                    'location': 'Trail',
                    'created': '2026-05-01T12:00:00Z',
                    'notes': '',
                    'active': true,
                    'responses': const [],
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('missing', 404);
        }),
        baseUrl: 'http://example.test',
      );

      final snapshot = await api.fetchDashboard();

      expect(snapshot.incidents, hasLength(1));
    });

    test('accepts an envelope-shaped {data: []} body', () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          if (request.url.path == '/incidents') {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'public_id': 'incident-2',
                    'team_public_id': 'team-1',
                    'title': 'Mission',
                    'location': 'Trail',
                    'created': '2026-05-01T12:00:00Z',
                    'notes': '',
                    'active': true,
                    'responses': const [],
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('missing', 404);
        }),
        baseUrl: 'http://example.test',
      );

      final snapshot = await api.fetchDashboard();

      expect(snapshot.incidents.single.publicId, 'incident-2');
    });

    test('throws when /incidents returns an unexpected JSON shape', () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          if (request.url.path == '/incidents') {
            return http.Response(jsonEncode({'unexpected': true}), 200);
          }
          return http.Response('missing', 404);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.fetchDashboard(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('MissionOutApi.createIncident', () {
    test('posts the canonical incident shape', () async {
      late Map<String, dynamic> requestBody;
      String capturedMethod = '';
      Uri? capturedUri;
      final api = MissionOutApi(
        client: MockClient((request) async {
          capturedMethod = request.method;
          capturedUri = request.url;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'public_id': 'incident-new',
              'team_public_id': 'team-1',
              'title': 'New mission',
              'location': 'Forest',
              'created': '2026-05-02T12:00:00Z',
              'notes': 'Plan A',
              'active': true,
              'responses': const [],
            }),
            201,
          );
        }),
        baseUrl: 'http://example.test',
      );

      final result = await api.createIncident(
        const IncidentDraft(
          title: 'New mission',
          location: 'Forest',
          notes: 'Plan A',
        ),
        teamPublicId: 'team-1',
      );

      expect(capturedMethod, 'POST');
      expect(capturedUri.toString(), 'http://example.test/incidents');
      expect(requestBody, {
        'title': 'New mission',
        'team_public_id': 'team-1',
        'location': 'Forest',
        'notes': 'Plan A',
        'active': true,
      });
      expect(result.publicId, 'incident-new');
      expect(result.title, 'New mission');
    });

    test('throws on non-2xx', () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          return http.Response('boom', 500);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.createIncident(
          const IncidentDraft(title: 't', location: 'l', notes: 'n'),
          teamPublicId: 'team-1',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when the response body is not a JSON object', () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          return http.Response(jsonEncode(const []), 201);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.createIncident(
          const IncidentDraft(title: 't', location: 'l', notes: 'n'),
          teamPublicId: 'team-1',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('MissionOutApi.updateIncident', () {
    test('patches the canonical incident shape', () async {
      late Map<String, dynamic> requestBody;
      String capturedMethod = '';
      Uri? capturedUri;
      final api = MissionOutApi(
        client: MockClient((request) async {
          capturedMethod = request.method;
          capturedUri = request.url;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'public_id': 'incident-1',
              'team_public_id': 'team-1',
              'title': 'Updated',
              'location': 'Forest',
              'created': '2026-05-02T12:00:00Z',
              'notes': 'Plan B',
              'active': false,
              'responses': const [],
            }),
            200,
          );
        }),
        baseUrl: 'http://example.test',
      );

      final result = await api.updateIncident(
        'incident-1',
        const IncidentUpdate(
          title: 'Updated',
          location: 'Forest',
          notes: 'Plan B',
          active: false,
        ),
      );

      expect(capturedMethod, 'PATCH');
      expect(
        capturedUri.toString(),
        'http://example.test/incidents/incident-1',
      );
      expect(requestBody, {
        'title': 'Updated',
        'location': 'Forest',
        'notes': 'Plan B',
        'active': false,
      });
      expect(result.title, 'Updated');
      expect(result.active, isFalse);
    });

    test('throws on non-2xx', () async {
      final api = MissionOutApi(
        client: MockClient((request) async {
          return http.Response('forbidden', 403);
        }),
        baseUrl: 'http://example.test',
      );

      await expectLater(
        api.updateIncident(
          'incident-1',
          const IncidentUpdate(
            title: 't',
            location: 'l',
            notes: 'n',
            active: true,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
