import 'package:flutter_test/flutter_test.dart';
import 'package:shared_auth/shared_auth.dart';

void main() {
  group('AuthTeamMembership', () {
    test('round-trips through toJson/fromJson', () {
      const original = AuthTeamMembership(
        teamPublicId: 'team-1',
        teamName: 'Alpha team',
        roles: ['responder', 'team_admin'],
      );

      final restored = AuthTeamMembership.fromJson(original.toJson());

      expect(restored.teamPublicId, original.teamPublicId);
      expect(restored.teamName, original.teamName);
      expect(restored.roles, original.roles);
    });

    test('falls back to safe defaults when fields are missing', () {
      final restored = AuthTeamMembership.fromJson(const {});

      expect(restored.teamPublicId, '');
      expect(restored.teamName, 'Unknown Team');
      expect(restored.roles, isEmpty);
    });

    test('drops non-string entries from the roles array', () {
      final restored = AuthTeamMembership.fromJson(const {
        'team_public_id': 'team-1',
        'team_name': 'Alpha team',
        'roles': ['responder', 42, null, 'team_admin'],
      });

      expect(restored.roles, ['responder', 'team_admin']);
    });
  });

  group('AuthUser.fromSessionJson with envelope', () {
    test('parses a full AuthSessionRead envelope', () {
      final user = AuthUser.fromSessionJson({
        'user': {
          'public_id': 'u-1',
          'name': 'Alex Responder',
          'initials': 'AR',
          'role': 'Responder',
          'email': 'alex@example.test',
          'global_permissions': const ['read:incidents'],
          'team_memberships': [
            {
              'team_public_id': 'team-1',
              'team_name': 'Alpha team',
              'roles': ['responder'],
            },
          ],
        },
        'access_token': 'access-jwt',
        'access_token_expires_at': '2026-05-01T12:00:00Z',
        'refresh_token': 'refresh-jwt',
        'refresh_token_expires_at': '2026-06-01T12:00:00Z',
      });

      expect(user.publicId, 'u-1');
      expect(user.name, 'Alex Responder');
      expect(user.initials, 'AR');
      expect(user.role, 'Responder');
      expect(user.email, 'alex@example.test');
      expect(user.globalPermissions, const ['read:incidents']);
      expect(user.teamMemberships, hasLength(1));
      expect(user.teamMemberships.first.teamPublicId, 'team-1');
      expect(user.accessToken, 'access-jwt');
      expect(user.accessTokenExpiresAt, DateTime.utc(2026, 5, 1, 12));
      expect(user.refreshToken, 'refresh-jwt');
      expect(user.refreshTokenExpiresAt, DateTime.utc(2026, 6, 1, 12));
    });

    test('falls back to legacy AuthUserRead-only payloads', () {
      final user = AuthUser.fromSessionJson(const {
        'public_id': 'u-1',
        'name': 'Alex Responder',
        'initials': 'AR',
        'role': 'Responder',
        'email': 'alex@example.test',
      });

      expect(user.publicId, 'u-1');
      expect(user.role, 'Responder');
      expect(user.accessToken, isNull);
      expect(user.accessTokenExpiresAt, isNull);
      expect(user.refreshToken, isNull);
      expect(user.refreshTokenExpiresAt, isNull);
    });

    test('applies safe defaults when user fields are absent', () {
      final user = AuthUser.fromSessionJson(<String, dynamic>{'user': <String, dynamic>{}});

      expect(user.publicId, '');
      expect(user.name, 'Unknown User');
      expect(user.initials, '--');
      expect(user.email, '');
      expect(user.globalPermissions, isEmpty);
      expect(user.teamMemberships, isEmpty);
    });

    test('drops non-string globalPermissions and non-object memberships', () {
      final user = AuthUser.fromSessionJson(const {
        'user': {
          'global_permissions': ['admin', 42, null],
          'team_memberships': [
            {'team_public_id': 'team-1', 'team_name': 'Alpha', 'roles': []},
            'not-an-object',
            42,
          ],
        },
      });

      expect(user.globalPermissions, const ['admin']);
      expect(user.teamMemberships, hasLength(1));
      expect(user.teamMemberships.single.teamPublicId, 'team-1');
    });
  });

  group('AuthUser.fromSessionJson role resolution', () {
    test('explicit role in payload wins over heuristics', () {
      final user = AuthUser.fromSessionJson(const {
        'user': {'role': 'Custom Role'},
      }, requestedClient: 'team_admin');

      expect(user.role, 'Custom Role');
    });

    test('requestedClient maps to the canonical role label', () {
      final teamAdmin = AuthUser.fromSessionJson(
        <String, dynamic>{'user': <String, dynamic>{}},
        requestedClient: 'team_admin',
      );
      final dispatcher = AuthUser.fromSessionJson(
        <String, dynamic>{'user': <String, dynamic>{}},
        requestedClient: 'dispatcher',
      );
      final responder = AuthUser.fromSessionJson(
        <String, dynamic>{'user': <String, dynamic>{}},
        requestedClient: 'responder',
      );

      expect(teamAdmin.role, 'Team Admin');
      expect(dispatcher.role, 'Dispatcher');
      expect(responder.role, 'Responder');
    });

    test('global super_admin permission promotes to Super Admin', () {
      final user = AuthUser.fromSessionJson(const {
        'user': {
          'global_permissions': ['super_admin'],
        },
      });

      expect(user.role, 'Super Admin');
    });

    test('membership roles cascade Team Admin > Dispatcher > Responder', () {
      final teamAdmin = AuthUser.fromSessionJson(const {
        'user': {
          'team_memberships': [
            {'team_public_id': 't', 'team_name': 'A', 'roles': ['responder']},
            {
              'team_public_id': 't2',
              'team_name': 'B',
              'roles': ['team_admin'],
            },
          ],
        },
      });
      final dispatcher = AuthUser.fromSessionJson(const {
        'user': {
          'team_memberships': [
            {
              'team_public_id': 't',
              'team_name': 'A',
              'roles': ['dispatcher', 'responder'],
            },
          ],
        },
      });
      final responder = AuthUser.fromSessionJson(const {
        'user': {
          'team_memberships': [
            {'team_public_id': 't', 'team_name': 'A', 'roles': ['responder']},
          ],
        },
      });

      expect(teamAdmin.role, 'Team Admin');
      expect(dispatcher.role, 'Dispatcher');
      expect(responder.role, 'Responder');
    });

    test('falls back to fallbackRole when nothing else matches', () {
      final user = AuthUser.fromSessionJson(
        <String, dynamic>{'user': <String, dynamic>{}},
        fallbackRole: 'Visitor',
      );

      expect(user.role, 'Visitor');
    });

    test('defaults to Responder when neither client nor fallback is given',
        () {
      final user = AuthUser.fromSessionJson(<String, dynamic>{'user': <String, dynamic>{}});

      expect(user.role, 'Responder');
    });
  });

  group('AuthUser.fromJson', () {
    test('delegates to fromSessionJson', () {
      final user = AuthUser.fromJson(const {
        'user': {'public_id': 'u-1', 'role': 'Dispatcher'},
        'access_token': 'jwt',
      });

      expect(user.publicId, 'u-1');
      expect(user.role, 'Dispatcher');
      expect(user.accessToken, 'jwt');
    });
  });

  group('AuthUser.toJson', () {
    test('emits the full session envelope including timestamps', () {
      final user = AuthUser(
        publicId: 'u-1',
        name: 'Alex',
        initials: 'A',
        role: 'Responder',
        email: 'a@example.test',
        globalPermissions: const ['read:incidents'],
        teamMemberships: const [
          AuthTeamMembership(
            teamPublicId: 'team-1',
            teamName: 'Alpha',
            roles: ['responder'],
          ),
        ],
        accessToken: 'jwt',
        accessTokenExpiresAt: DateTime.utc(2026, 5, 1, 12),
        refreshToken: 'refresh',
        refreshTokenExpiresAt: DateTime.utc(2026, 6, 1, 12),
      );

      final json = user.toJson();
      final innerUser = json['user'] as Map<String, dynamic>;

      expect(innerUser['public_id'], 'u-1');
      expect(innerUser['name'], 'Alex');
      expect(innerUser['initials'], 'A');
      expect(innerUser['email'], 'a@example.test');
      expect(innerUser['global_permissions'], const ['read:incidents']);
      expect(innerUser['team_memberships'], hasLength(1));
      expect(json['access_token'], 'jwt');
      expect(json['access_token_expires_at'], '2026-05-01T12:00:00.000Z');
      expect(json['refresh_token'], 'refresh');
      expect(json['refresh_token_expires_at'], '2026-06-01T12:00:00.000Z');
    });

    test('emits null timestamps when not set', () {
      const user = AuthUser(
        publicId: 'u-1',
        name: 'Alex',
        initials: 'A',
        role: 'Responder',
        email: 'a@example.test',
      );

      final json = user.toJson();

      expect(json['access_token'], isNull);
      expect(json['access_token_expires_at'], isNull);
      expect(json['refresh_token'], isNull);
      expect(json['refresh_token_expires_at'], isNull);
    });
  });

  group('AuthUser.copyWith', () {
    const original = AuthUser(
      publicId: 'u-1',
      name: 'Alex',
      initials: 'A',
      role: 'Responder',
      email: 'a@example.test',
    );

    test('returns identical fields when no overrides are supplied', () {
      final copy = original.copyWith();

      expect(copy.publicId, original.publicId);
      expect(copy.name, original.name);
      expect(copy.initials, original.initials);
      expect(copy.role, original.role);
      expect(copy.email, original.email);
      expect(copy.globalPermissions, original.globalPermissions);
      expect(copy.teamMemberships, original.teamMemberships);
      expect(copy.accessToken, original.accessToken);
      expect(copy.accessTokenExpiresAt, original.accessTokenExpiresAt);
      expect(copy.refreshToken, original.refreshToken);
      expect(copy.refreshTokenExpiresAt, original.refreshTokenExpiresAt);
    });

    test('overrides only the supplied fields', () {
      final renamed = original.copyWith(name: 'Pat', role: 'Dispatcher');

      expect(renamed.name, 'Pat');
      expect(renamed.role, 'Dispatcher');
      expect(renamed.publicId, original.publicId);
      expect(renamed.email, original.email);
    });
  });

  group('AuthUser._parseDate', () {
    test('normalizes timezone offsets to UTC', () {
      final user = AuthUser.fromSessionJson(<String, dynamic>{
        'user': <String, dynamic>{},
        'access_token_expires_at': '2026-05-01T08:00:00-04:00',
      });

      expect(user.accessTokenExpiresAt, DateTime.utc(2026, 5, 1, 12));
      expect(user.accessTokenExpiresAt!.isUtc, isTrue);
    });

    test('returns null for empty timestamp strings', () {
      final user = AuthUser.fromSessionJson(<String, dynamic>{
        'user': <String, dynamic>{},
        'access_token_expires_at': '',
      });

      expect(user.accessTokenExpiresAt, isNull);
    });

    test('returns null for non-string timestamp values', () {
      final user = AuthUser.fromSessionJson(<String, dynamic>{
        'user': <String, dynamic>{},
        'access_token_expires_at': 12345,
      });

      expect(user.accessTokenExpiresAt, isNull);
    });
  });
}
