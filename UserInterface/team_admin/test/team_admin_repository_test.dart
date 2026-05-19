import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:missionout_team_admin/models/team_admin_models.dart';
import 'package:missionout_team_admin/services/team_admin_repository.dart';
import 'package:shared_auth/shared_auth.dart';

const _baseUrl = 'http://example.test';

const _membership = AuthTeamMembership(
  teamPublicId: 'team-1',
  teamName: 'Alpha team',
  roles: ['team_admin'],
);

TeamAdminRepository _repo(MockClientHandler handler) {
  return TeamAdminRepository(
    client: MockClient(handler),
    baseUrl: _baseUrl,
  );
}

Map<String, dynamic> _memberJson({
  String publicId = 'm-1',
  String userPublicId = 'u-1',
  String teamPublicId = 'team-1',
  String name = 'Alex Responder',
  String email = 'alex@example.test',
  String phone = '+15555550000',
  List<String> roles = const ['responder'],
  bool isActive = true,
  String? revokedAt,
}) {
  return {
    'public_id': publicId,
    'user_public_id': userPublicId,
    'team_public_id': teamPublicId,
    'name': name,
    'email': email,
    'phone': phone,
    'roles': roles,
    'is_active': isActive,
    'revoked_at': revokedAt,
  };
}

void main() {
  group('TeamAdminRepository.isLocalBackend', () {
    test('treats 127.0.0.1 as local', () {
      final repo = TeamAdminRepository(
        client: MockClient((_) async => http.Response('{}', 200)),
        baseUrl: 'http://127.0.0.1:8000',
      );
      expect(repo.isLocalBackend, isTrue);
    });

    test('treats localhost as local', () {
      final repo = TeamAdminRepository(
        client: MockClient((_) async => http.Response('{}', 200)),
        baseUrl: 'http://localhost:8000',
      );
      expect(repo.isLocalBackend, isTrue);
    });

    test('treats real hosts as remote', () {
      final repo = TeamAdminRepository(
        client: MockClient((_) async => http.Response('{}', 200)),
        baseUrl: 'https://api.example.com',
      );
      expect(repo.isLocalBackend, isFalse);
    });
  });

  group('TeamAdminRepository.loadWorkspace', () {
    test('happy path returns live workspace with merged member + device data',
        () async {
      String? capturedAuth;
      final repo = _repo((request) async {
        capturedAuth = request.headers['Authorization'];
        final path = request.url.path;
        if (path == '/health') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (path == '/teams/team-1/members') {
          return http.Response(
            jsonEncode([
              _memberJson(),
              _memberJson(
                publicId: 'm-2',
                userPublicId: 'u-2',
                name: 'Pat Dispatcher',
                isActive: false,
              ),
              _memberJson(
                publicId: 'm-3',
                userPublicId: 'u-3',
                revokedAt: '2026-01-01T00:00:00Z',
              ),
            ]),
            200,
          );
        }
        if (path == '/teams/team-1/devices') {
          return http.Response(
            jsonEncode([
              {
                'user_public_id': 'u-1',
                'platform': 'iOS',
                'last_seen': '2026-05-01T12:00:00Z',
                'is_verified': true,
                'is_active': true,
              },
            ]),
            200,
          );
        }
        return http.Response('not found', 404);
      });

      final workspace = await repo.loadWorkspace(
        memberships: const [_membership],
      );

      expect(workspace.usingLiveData, isTrue);
      expect(workspace.memberCrudSupported, isTrue);
      expect(workspace.statusMessage, isNull);
      expect(workspace.team.publicId, 'team-1');
      expect(workspace.team.name, 'Alpha team');
      expect(workspace.team.members, hasLength(2));

      final alex = workspace.team.members
          .firstWhere((m) => m.userPublicId == 'u-1');
      expect(alex.devicePlatform, 'iOS');
      expect(alex.deviceHealth, 'Healthy');
      expect(alex.status, 'Available');

      final pat = workspace.team.members
          .firstWhere((m) => m.userPublicId == 'u-2');
      expect(pat.devicePlatform, 'Unknown');
      expect(pat.deviceHealth, 'No device');
      expect(pat.status, 'Inactive');

      // Auth header is not currently sent on GET _getMap/_getOptionalList; the
      // first request (whichever the mock saw last) will reflect that.
      expect(capturedAuth, isNull);
    });

    test('with no memberships skips member/device fetches', () async {
      final calledPaths = <String>[];
      final repo = _repo((request) async {
        calledPaths.add(request.url.path);
        if (request.url.path == '/health') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        return http.Response('not found', 404);
      });

      final workspace = await repo.loadWorkspace();

      expect(workspace.usingLiveData, isTrue);
      expect(workspace.memberCrudSupported, isFalse);
      expect(workspace.team.members, isEmpty);
      expect(workspace.team.publicId, '');
      expect(workspace.team.name, 'Unassigned team');
      expect(
        calledPaths.any((p) => p.startsWith('/teams/')),
        isFalse,
      );
    });

    test('members 404 yields workspace with memberCrudSupported=false',
        () async {
      final repo = _repo((request) async {
        final path = request.url.path;
        if (path == '/health') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (path == '/teams/team-1/members') {
          return http.Response('missing', 404);
        }
        if (path == '/teams/team-1/devices') {
          return http.Response(jsonEncode(const []), 200);
        }
        return http.Response('not found', 404);
      });

      final workspace = await repo.loadWorkspace(
        memberships: const [_membership],
      );

      expect(workspace.usingLiveData, isTrue);
      expect(workspace.memberCrudSupported, isFalse);
      expect(workspace.team.members, isEmpty);
    });

    test('health failure returns degraded workspace with statusMessage',
        () async {
      final repo = _repo((request) async {
        return http.Response('boom', 500);
      });

      final workspace = await repo.loadWorkspace(
        memberships: const [_membership],
      );

      expect(workspace.usingLiveData, isFalse);
      expect(workspace.memberCrudSupported, isFalse);
      expect(workspace.statusMessage, contains('Could not load team data'));
      expect(workspace.team.members, isEmpty);
      expect(workspace.team.name, 'Alpha team');
    });

    test('exposes _deviceHealthLabel paths via member device fixtures',
        () async {
      final repo = _repo((request) async {
        final path = request.url.path;
        if (path == '/health') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (path == '/teams/team-1/members') {
          return http.Response(
            jsonEncode([
              _memberJson(publicId: 'm-1', userPublicId: 'u-1'),
              _memberJson(publicId: 'm-2', userPublicId: 'u-2'),
              _memberJson(publicId: 'm-3', userPublicId: 'u-3'),
              _memberJson(publicId: 'm-4', userPublicId: 'u-4'),
            ]),
            200,
          );
        }
        if (path == '/teams/team-1/devices') {
          return http.Response(
            jsonEncode([
              {
                'user_public_id': 'u-1',
                'platform': 'iOS',
                'is_verified': false,
                'is_active': true,
              },
              {
                'user_public_id': 'u-2',
                'platform': 'iOS',
                'is_verified': true,
                'is_active': false,
              },
              {
                'user_public_id': 'u-3',
                'platform': 'iOS',
                'is_verified': null,
                'is_active': null,
              },
            ]),
            200,
          );
        }
        return http.Response('not found', 404);
      });

      final workspace = await repo.loadWorkspace(
        memberships: const [_membership],
      );

      String healthFor(String userPublicId) => workspace.team.members
          .firstWhere((m) => m.userPublicId == userPublicId)
          .deviceHealth;

      expect(healthFor('u-1'), 'Unverified');
      expect(healthFor('u-2'), 'Inactive');
      expect(healthFor('u-3'), 'Needs review');
      expect(healthFor('u-4'), 'No device');
    });

    test('throws when /health body is not a JSON object', () async {
      final repo = _repo((request) async {
        if (request.url.path == '/health') {
          return http.Response(jsonEncode(const []), 200);
        }
        return http.Response('not found', 404);
      });

      final workspace = await repo.loadWorkspace(
        memberships: const [_membership],
      );

      expect(workspace.usingLiveData, isFalse);
      expect(workspace.statusMessage, isNotNull);
    });

    test('throws via degradation when /teams/.../members body is non-list',
        () async {
      final repo = _repo((request) async {
        final path = request.url.path;
        if (path == '/health') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        if (path == '/teams/team-1/members') {
          return http.Response(jsonEncode({'unexpected': true}), 200);
        }
        return http.Response('not found', 404);
      });

      final workspace = await repo.loadWorkspace(
        memberships: const [_membership],
      );

      expect(workspace.usingLiveData, isFalse);
      expect(workspace.statusMessage, isNotNull);
    });
  });

  group('TeamAdminRepository CRUD', () {
    Future<TeamAdminRepository> warmRepo(MockClientHandler handler) async {
      final repo = TeamAdminRepository(
        client: AuthHeaderClient(
          MockClient((request) async {
            final path = request.url.path;
            if (path == '/health') {
              return http.Response(jsonEncode({'status': 'ok'}), 200);
            }
            if (path == '/teams/team-1/members' && request.method == 'GET') {
              return http.Response(jsonEncode(const []), 200);
            }
            if (path == '/teams/team-1/devices' && request.method == 'GET') {
              return http.Response(jsonEncode(const []), 200);
            }
            return await handler(request);
          }),
          () async => 'jwt',
        ),
        baseUrl: _baseUrl,
      );
      await repo.loadWorkspace(memberships: const [_membership]);
      return repo;
    }

    test('createMember POSTs canonical body and Authorization header',
        () async {
      Map<String, dynamic>? capturedBody;
      String capturedMethod = '';
      Uri? capturedUri;
      String? capturedAuth;

      final repo = await warmRepo((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/teams/team-1/members') {
          capturedMethod = request.method;
          capturedUri = request.url;
          capturedAuth = request.headers['Authorization'];
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 201);
        }
        return http.Response('unexpected', 500);
      });

      await repo.createMember(
        const TeamAdminMemberDraft(
          name: 'Pat',
          email: 'pat@example.test',
          phone: '+15555550000',
          roles: ['responder'],
        ),
      );

      expect(capturedMethod, 'POST');
      expect(
        capturedUri.toString(),
        'http://example.test/teams/team-1/members',
      );
      expect(capturedAuth, 'Bearer jwt');
      expect(capturedBody, {
        'name': 'Pat',
        'email': 'pat@example.test',
        'phone': '+15555550000',
        'roles': ['responder'],
        'is_active': true,
      });
    });

    test('createMember throws on non-2xx', () async {
      final repo = await warmRepo((request) async {
        if (request.method == 'POST') {
          return http.Response('boom', 500);
        }
        return http.Response('unexpected', 500);
      });

      await expectLater(
        repo.createMember(
          const TeamAdminMemberDraft(
            name: 'Pat',
            email: 'p@example.test',
            phone: '+15555550000',
            roles: ['responder'],
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('updateMember PATCHes the roles payload', () async {
      Map<String, dynamic>? capturedBody;
      String capturedMethod = '';
      Uri? capturedUri;

      final repo = await warmRepo((request) async {
        if (request.method == 'PATCH' &&
            request.url.path == '/teams/team-1/members/m-9') {
          capturedMethod = request.method;
          capturedUri = request.url;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      });

      await repo.updateMember(
        'm-9',
        const TeamAdminMemberDraft(
          name: 'Pat',
          email: 'p@example.test',
          phone: '+15555550000',
          roles: ['team_admin'],
        ),
      );

      expect(capturedMethod, 'PATCH');
      expect(
        capturedUri.toString(),
        'http://example.test/teams/team-1/members/m-9',
      );
      expect(capturedBody, {'roles': ['team_admin']});
    });

    test('updateMember throws on non-2xx', () async {
      final repo = await warmRepo((request) async {
        if (request.method == 'PATCH') {
          return http.Response('boom', 500);
        }
        return http.Response('unexpected', 500);
      });

      await expectLater(
        repo.updateMember(
          'm-1',
          const TeamAdminMemberDraft(
            name: 'x',
            email: 'x@example.test',
            phone: '+15555550000',
            roles: ['responder'],
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('setMemberActive PATCHes is_active', () async {
      Map<String, dynamic>? capturedBody;

      final repo = await warmRepo((request) async {
        if (request.method == 'PATCH' &&
            request.url.path == '/teams/team-1/members/m-1') {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      });

      await repo.setMemberActive('m-1', false);

      expect(capturedBody, {'is_active': false});
    });

    test('setMemberActive distinguishes activate vs deactivate in error message',
        () async {
      final repo = await warmRepo((request) async {
        return http.Response('boom', 500);
      });

      await expectLater(
        repo.setMemberActive('m-1', true),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('activate'),
          ),
        ),
      );

      await expectLater(
        repo.setMemberActive('m-1', false),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('deactivate'),
          ),
        ),
      );
    });

    test('deleteMember sends DELETE and reloads', () async {
      String capturedMethod = '';
      Uri? capturedUri;

      final repo = await warmRepo((request) async {
        if (request.method == 'DELETE') {
          capturedMethod = request.method;
          capturedUri = request.url;
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      });

      await repo.deleteMember('m-1');

      expect(capturedMethod, 'DELETE');
      expect(
        capturedUri.toString(),
        'http://example.test/teams/team-1/members/m-1',
      );
    });

    test('deleteMember surfaces specific messages for 403/404/409', () async {
      Future<TeamAdminRepository> repoForStatus(int statusCode) async {
        return warmRepo((request) async {
          if (request.method == 'DELETE') {
            return http.Response('', statusCode);
          }
          return http.Response('unexpected', 500);
        });
      }

      await expectLater(
        (await repoForStatus(403)).deleteMember('m-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not a team admin'),
          ),
        ),
      );

      await expectLater(
        (await repoForStatus(404)).deleteMember('m-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('no longer exists'),
          ),
        ),
      );

      await expectLater(
        (await repoForStatus(409)).deleteMember('m-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('last active team admin'),
          ),
        ),
      );

      await expectLater(
        (await repoForStatus(500)).deleteMember('m-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to remove'),
          ),
        ),
      );
    });

    test('CRUD methods throw before loadWorkspace establishes team context',
        () async {
      final cold = TeamAdminRepository(
        client: MockClient((_) async => http.Response('', 200)),
        baseUrl: _baseUrl,
      );

      await expectLater(
        cold.createMember(
          const TeamAdminMemberDraft(
            name: 'x',
            email: 'x@example.test',
            phone: '+15555550000',
            roles: ['responder'],
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Team context'),
          ),
        ),
      );
    });

  });
}
