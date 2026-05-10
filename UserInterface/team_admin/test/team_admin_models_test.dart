import 'package:flutter_test/flutter_test.dart';
import 'package:missionout_team_admin/models/team_admin_models.dart';

TeamAdminMember _member({
  String publicId = 'm-1',
  String userPublicId = 'u-1',
  String teamPublicId = 't-1',
  String name = 'Alex Responder',
  String email = 'alex@example.test',
  String phone = '+15555550000',
  List<String> roles = const ['responder'],
  String status = 'Available',
  DateTime? lastSeenAt,
  String devicePlatform = 'iOS',
  String deviceHealth = 'Healthy',
  bool isActive = true,
  String? revokedAt,
}) {
  return TeamAdminMember(
    publicId: publicId,
    userPublicId: userPublicId,
    teamPublicId: teamPublicId,
    name: name,
    email: email,
    phone: phone,
    roles: roles,
    status: status,
    lastSeenAt: lastSeenAt,
    devicePlatform: devicePlatform,
    deviceHealth: deviceHealth,
    isActive: isActive,
    revokedAt: revokedAt,
  );
}

TeamAdminTeam _team({List<TeamAdminMember> members = const []}) {
  return TeamAdminTeam(
    publicId: 'team-1',
    name: 'Alpha team',
    organization: 'MissionOut',
    region: 'Pacific NW',
    dispatchChannel: 'Slack',
    notes: 'On call this week.',
    members: members,
  );
}

void main() {
  group('TeamAdminTeam.copyWith', () {
    test('returns an identical instance when no overrides are supplied', () {
      final original = _team(members: [_member()]);
      final copy = original.copyWith();

      expect(copy.publicId, original.publicId);
      expect(copy.name, original.name);
      expect(copy.organization, original.organization);
      expect(copy.region, original.region);
      expect(copy.dispatchChannel, original.dispatchChannel);
      expect(copy.notes, original.notes);
      expect(copy.members, same(original.members));
    });

    test('overrides only the supplied fields', () {
      final original = _team();

      expect(original.copyWith(publicId: 'team-2').publicId, 'team-2');
      expect(original.copyWith(name: 'Bravo').name, 'Bravo');
      expect(
        original.copyWith(organization: 'Other').organization,
        'Other',
      );
      expect(original.copyWith(region: 'Atlantic').region, 'Atlantic');
      expect(
        original.copyWith(dispatchChannel: 'PagerDuty').dispatchChannel,
        'PagerDuty',
      );
      expect(original.copyWith(notes: 'New notes').notes, 'New notes');

      final newMembers = [_member(publicId: 'm-2')];
      expect(original.copyWith(members: newMembers).members, newMembers);
    });

    test('leaves untouched fields equal to the original', () {
      final original = _team();
      final renamed = original.copyWith(name: 'Bravo');

      expect(renamed.publicId, original.publicId);
      expect(renamed.organization, original.organization);
      expect(renamed.region, original.region);
      expect(renamed.dispatchChannel, original.dispatchChannel);
      expect(renamed.notes, original.notes);
      expect(renamed.members, original.members);
    });
  });

  group('TeamAdminMember.copyWith', () {
    test('returns an identical instance when no overrides are supplied', () {
      final original = _member(revokedAt: '2026-01-01T00:00:00Z');
      final copy = original.copyWith();

      expect(copy.publicId, original.publicId);
      expect(copy.userPublicId, original.userPublicId);
      expect(copy.teamPublicId, original.teamPublicId);
      expect(copy.name, original.name);
      expect(copy.email, original.email);
      expect(copy.phone, original.phone);
      expect(copy.roles, same(original.roles));
      expect(copy.status, original.status);
      expect(copy.lastSeenAt, original.lastSeenAt);
      expect(copy.devicePlatform, original.devicePlatform);
      expect(copy.deviceHealth, original.deviceHealth);
      expect(copy.isActive, original.isActive);
      expect(copy.revokedAt, original.revokedAt);
    });

    test('overrides only the supplied fields', () {
      final original = _member();

      expect(original.copyWith(publicId: 'm-9').publicId, 'm-9');
      expect(
        original.copyWith(userPublicId: 'u-9').userPublicId,
        'u-9',
      );
      expect(
        original.copyWith(teamPublicId: 't-9').teamPublicId,
        't-9',
      );
      expect(original.copyWith(name: 'Pat').name, 'Pat');
      expect(
        original.copyWith(email: 'pat@example.test').email,
        'pat@example.test',
      );
      expect(original.copyWith(phone: '+15555550001').phone, '+15555550001');
      expect(
        original.copyWith(roles: const ['team_admin']).roles,
        const ['team_admin'],
      );
      expect(original.copyWith(status: 'Inactive').status, 'Inactive');
      final seenAt = DateTime.utc(2026, 5, 1, 12);
      expect(original.copyWith(lastSeenAt: seenAt).lastSeenAt, seenAt);
      expect(
        original.copyWith(devicePlatform: 'Android').devicePlatform,
        'Android',
      );
      expect(
        original.copyWith(deviceHealth: 'Unverified').deviceHealth,
        'Unverified',
      );
      expect(original.copyWith(isActive: false).isActive, isFalse);
      expect(
        original
            .copyWith(revokedAt: '2026-05-01T12:00:00Z')
            .revokedAt,
        '2026-05-01T12:00:00Z',
      );
    });

    test('preserves untouched fields when one field is replaced', () {
      final original = _member();
      final renamed = original.copyWith(name: 'Pat');

      expect(renamed.publicId, original.publicId);
      expect(renamed.email, original.email);
      expect(renamed.phone, original.phone);
      expect(renamed.roles, original.roles);
      expect(renamed.isActive, original.isActive);
    });
  });

  group('TeamAdminMemberDraft', () {
    test('preserves required fields on construction', () {
      const draft = TeamAdminMemberDraft(
        name: 'Pat',
        email: 'pat@example.test',
        phone: '+15555550000',
        roles: ['responder'],
      );

      expect(draft.name, 'Pat');
      expect(draft.email, 'pat@example.test');
      expect(draft.phone, '+15555550000');
      expect(draft.roles, const ['responder']);
    });
  });

  group('TeamAdminWorkspace', () {
    test('preserves required fields and optional statusMessage', () {
      final team = _team();
      final workspace = TeamAdminWorkspace(
        team: team,
        memberCrudSupported: true,
        usingLiveData: false,
        statusMessage: 'Backend unreachable.',
      );

      expect(workspace.team, same(team));
      expect(workspace.memberCrudSupported, isTrue);
      expect(workspace.usingLiveData, isFalse);
      expect(workspace.statusMessage, 'Backend unreachable.');
    });

    test('allows null statusMessage', () {
      final workspace = TeamAdminWorkspace(
        team: _team(),
        memberCrudSupported: true,
        usingLiveData: true,
      );

      expect(workspace.statusMessage, isNull);
    });
  });
}
