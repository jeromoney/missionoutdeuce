import '../data/demo_team_admin_data.dart';
import '../models/team_admin_models.dart';

class TeamAdminRepository {
  TeamAdminRepository() : _team = demoManagedTeam;

  TeamAdminTeam _team;
  int _nextMemberId = 1000;

  TeamAdminTeam loadTeam() => _team;

  TeamAdminTeam createMember(TeamAdminMemberDraft draft) {
    _team = _team.copyWith(
      members: [
        ..._team.members,
        TeamAdminMember(
          id: _nextMemberId++,
          name: draft.name,
          email: draft.email,
          phone: draft.phone,
          roles: draft.roles,
          status: draft.status,
          lastSeen: draft.lastSeen,
          devicePlatform: draft.devicePlatform,
          deviceHealth: draft.deviceHealth,
          isActive: draft.isActive,
        ),
      ],
    );
    return _team;
  }

  TeamAdminTeam updateMember(int memberId, TeamAdminMemberDraft draft) {
    _team = _team.copyWith(
      members: [
        for (final member in _team.members)
          if (member.id == memberId)
            member.copyWith(
              name: draft.name,
              email: draft.email,
              phone: draft.phone,
              roles: draft.roles,
              status: draft.status,
              lastSeen: draft.lastSeen,
              devicePlatform: draft.devicePlatform,
              deviceHealth: draft.deviceHealth,
              isActive: draft.isActive,
            )
          else
            member,
      ],
    );
    return _team;
  }

  TeamAdminTeam setMemberActive(int memberId, bool isActive) {
    _team = _team.copyWith(
      members: [
        for (final member in _team.members)
          if (member.id == memberId)
            member.copyWith(isActive: isActive)
          else
            member,
      ],
    );
    return _team;
  }
}
