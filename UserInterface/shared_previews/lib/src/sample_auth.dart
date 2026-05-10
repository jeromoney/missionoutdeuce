import 'package:shared_auth/shared_auth.dart';

class SamplePreviewUser {
  static const dispatcher = AuthUser(
    publicId: 'user_dispatcher_demo',
    name: 'Avery Dispatcher',
    initials: 'AD',
    role: 'Dispatcher',
    email: 'avery@missionout.example',
    teamMemberships: [
      AuthTeamMembership(
        teamPublicId: 'team_demo_alpha',
        teamName: 'Alpha Team',
        roles: ['dispatcher'],
      ),
    ],
  );

  static const responder = AuthUser(
    publicId: 'user_responder_demo',
    name: 'Riley Responder',
    initials: 'RR',
    role: 'Responder',
    email: 'riley@missionout.example',
    teamMemberships: [
      AuthTeamMembership(
        teamPublicId: 'team_demo_alpha',
        teamName: 'Alpha Team',
        roles: ['responder'],
      ),
    ],
  );

  static const teamAdmin = AuthUser(
    publicId: 'user_admin_demo',
    name: 'Tana Admin',
    initials: 'TA',
    role: 'Team Admin',
    email: 'tana@missionout.example',
    teamMemberships: [
      AuthTeamMembership(
        teamPublicId: 'team_demo_alpha',
        teamName: 'Alpha Team',
        roles: ['team_admin'],
      ),
    ],
  );
}
