import '../models/team_admin_models.dart';

const demoManagedTeam = TeamAdminTeam(
  id: 1,
  name: 'Chaffee SAR',
  organization: 'Central Colorado SAR',
  region: 'South Central',
  dispatchChannel: 'SAR-2',
  notes:
      'Team Admin manages memberships, roles, and device readiness for one existing operational team. Use deactivation instead of destructive deletion so incident history remains auditable.',
  members: [
    TeamAdminMember(
      id: 101,
      name: 'Justin Mercer',
      email: 'justin@missionout.test',
      phone: '(719) 555-0110',
      roles: ['team_admin', 'dispatcher'],
      status: 'Available',
      lastSeen: '2 min ago',
      devicePlatform: 'iPhone',
      deviceHealth: 'Healthy',
      isActive: true,
    ),
    TeamAdminMember(
      id: 102,
      name: 'Sarah Kent',
      email: 'sarah@missionout.test',
      phone: '(719) 555-0133',
      roles: ['responder'],
      status: 'Responding',
      lastSeen: 'Just now',
      devicePlatform: 'Android',
      deviceHealth: 'Healthy',
      isActive: true,
    ),
    TeamAdminMember(
      id: 103,
      name: 'Mike Dawson',
      email: 'mike@missionout.test',
      phone: '(719) 555-0175',
      roles: ['responder'],
      status: 'Unavailable',
      lastSeen: '48 min ago',
      devicePlatform: 'Android',
      deviceHealth: 'Stale token',
      isActive: false,
    ),
  ],
  incidents: [
    TeamIncidentSummary(
      title: 'Injured Climber Extraction',
      location: 'Mt. Princeton Southwest Gully',
      state: 'Active',
      time: '8 min ago',
    ),
    TeamIncidentSummary(
      title: 'Overdue Hiker Assist',
      location: 'Browns Canyon Trailhead',
      state: 'Resolved',
      time: 'Yesterday',
    ),
  ],
  responses: [
    TeamResponseSummary(
      memberName: 'Sarah Kent',
      incidentTitle: 'Injured Climber Extraction',
      status: 'Responding',
      time: '2 min ago',
    ),
    TeamResponseSummary(
      memberName: 'Mike Dawson',
      incidentTitle: 'Overdue Hiker Assist',
      status: 'Not Available',
      time: 'Yesterday',
    ),
    TeamResponseSummary(
      memberName: 'Justin Mercer',
      incidentTitle: 'Injured Climber Extraction',
      status: 'Assigned Dispatcher',
      time: '8 min ago',
    ),
  ],
);
