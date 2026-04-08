import '../models/incident.dart';

const responderIncidents = [
  ResponderIncident(
    id: 1234,
    publicId: 'incident_injured_climber_demo',
    title: 'Injured Climber Extraction',
    location: 'Mt. Princeton Southwest Gully',
    team: 'Chaffee SAR',
    teamPublicId: 'team_chaffee_sar_demo',
    timeLabel: '8 min ago',
    notes:
        'Subject reports lower-leg injury above treeline. Wind increasing. Ground extraction underway.',
    status: 'Responding',
  ),
  ResponderIncident(
    id: 5678,
    publicId: 'incident_overdue_snowmobiler_demo',
    title: 'Overdue Snowmobiler',
    location: 'Georgia Pass East Approach',
    team: 'Chaffee SAR',
    teamPublicId: 'team_chaffee_sar_demo',
    timeLabel: '21 min ago',
    notes:
        'Last device ping near the pass. Rapid sweep requested with snow access support and trailhead staging.',
    status: 'Pending',
  ),
  ResponderIncident(
    id: 9012,
    publicId: 'incident_search_reassignment_demo',
    title: 'Search Area Reassignment',
    location: 'Cottonwood Creek Drainage',
    team: 'Chaffee SAR',
    teamPublicId: 'team_chaffee_sar_demo',
    timeLabel: '33 min ago',
    notes:
        'Operations wants an additional responder for flank coverage after radio contact was lost with the western grid.',
    status: 'Pending',
  ),
];
