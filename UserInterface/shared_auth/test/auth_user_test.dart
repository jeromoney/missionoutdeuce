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

  group('AuthUser.fromJson', () {
    test('parses a full AuthUserRead payload', () {
      final user = AuthUser.fromJson({
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
      });

      expect(user.publicId, 'u-1');
      expect(user.name, 'Alex Responder');
      expect(user.initials, 'AR');
      expect(user.role, 'Responder');
      expect(user.email, 'alex@example.test');
      expect(user.globalPermissions, const ['read:incidents']);
      expect(user.teamMemberships, hasLength(1));
      expect(user.teamMemberships.first.teamPublicId, 'team-1');
    });

    test('applies safe defaults when fields are absent', () {
      final user = AuthUser.fromJson(const {});

      expect(user.publicId, '');
      expect(user.name, 'Unknown User');
      expect(user.initials, '--');
      expect(user.email, '');
      expect(user.globalPermissions, isEmpty);
      expect(user.teamMemberships, isEmpty);
    });

    test('drops non-string globalPermissions and non-object memberships', () {
      final user = AuthUser.fromJson(const {
        'global_permissions': ['admin', 42, null],
        'team_memberships': [
          {'team_public_id': 'team-1', 'team_name': 'Alpha', 'roles': []},
          'not-an-object',
          42,
        ],
      });

      expect(user.globalPermissions, const ['admin']);
      expect(user.teamMemberships, hasLength(1));
      expect(user.teamMemberships.single.teamPublicId, 'team-1');
    });
  });

  group('AuthUser.fromJson role resolution', () {
    test('explicit role in payload wins over heuristics', () {
      final user = AuthUser.fromJson(
        const {'role': 'Custom Role'},
        requestedClient: 'team_admin',
      );

      expect(user.role, 'Custom Role');
    });

    test('requestedClient maps to the canonical role label', () {
      final teamAdmin =
          AuthUser.fromJson(const {}, requestedClient: 'team_admin');
      final dispatcher =
          AuthUser.fromJson(const {}, requestedClient: 'dispatcher');
      final responder =
          AuthUser.fromJson(const {}, requestedClient: 'responder');

      expect(teamAdmin.role, 'Team Admin');
      expect(dispatcher.role, 'Dispatcher');
      expect(responder.role, 'Responder');
    });

    test('global super_admin permission promotes to Super Admin', () {
      final user = AuthUser.fromJson(const {
        'global_permissions': ['super_admin'],
      });

      expect(user.role, 'Super Admin');
    });

    test('membership roles cascade Team Admin > Dispatcher > Responder', () {
      final teamAdmin = AuthUser.fromJson(const {
        'team_memberships': [
          {'team_public_id': 't', 'team_name': 'A', 'roles': ['responder']},
          {
            'team_public_id': 't2',
            'team_name': 'B',
            'roles': ['team_admin'],
          },
        ],
      });
      final dispatcher = AuthUser.fromJson(const {
        'team_memberships': [
          {
            'team_public_id': 't',
            'team_name': 'A',
            'roles': ['dispatcher', 'responder'],
          },
        ],
      });
      final responder = AuthUser.fromJson(const {
        'team_memberships': [
          {'team_public_id': 't', 'team_name': 'A', 'roles': ['responder']},
        ],
      });

      expect(teamAdmin.role, 'Team Admin');
      expect(dispatcher.role, 'Dispatcher');
      expect(responder.role, 'Responder');
    });

    test('falls back to fallbackRole when nothing else matches', () {
      final user = AuthUser.fromJson(
        const {},
        fallbackRole: 'Visitor',
      );

      expect(user.role, 'Visitor');
    });

    test('defaults to Responder when neither client nor fallback is given', () {
      final user = AuthUser.fromJson(const {});

      expect(user.role, 'Responder');
    });
  });

  group('AuthUser.toJson', () {
    test('round-trips through toJson/fromJson', () {
      const user = AuthUser(
        publicId: 'u-1',
        name: 'Alex',
        initials: 'A',
        role: 'Responder',
        email: 'a@example.test',
        globalPermissions: ['read:incidents'],
        teamMemberships: [
          AuthTeamMembership(
            teamPublicId: 'team-1',
            teamName: 'Alpha',
            roles: ['responder'],
          ),
        ],
      );

      final restored = AuthUser.fromJson(user.toJson());

      expect(restored.publicId, user.publicId);
      expect(restored.name, user.name);
      expect(restored.initials, user.initials);
      expect(restored.email, user.email);
      expect(restored.globalPermissions, user.globalPermissions);
      expect(restored.teamMemberships, hasLength(1));
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
    });

    test('overrides only the supplied fields', () {
      final renamed = original.copyWith(name: 'Pat', role: 'Dispatcher');

      expect(renamed.name, 'Pat');
      expect(renamed.role, 'Dispatcher');
      expect(renamed.publicId, original.publicId);
      expect(renamed.email, original.email);
    });
  });
}
