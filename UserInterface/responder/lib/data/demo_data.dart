import '../models/incident.dart';

const responderIncidents = [
  ResponderIncident(
    title: 'Injured Climber Extraction',
    location: 'Mt. Princeton Southwest Gully',
    team: 'Chaffee SAR',
    timeLabel: '8 min ago',
    notes:
        'Subject reports lower-leg injury above treeline. Wind increasing. Ground extraction underway.',
    status: 'Responding',
  ),
  ResponderIncident(
    title: 'Overdue Snowmobiler',
    location: 'Georgia Pass East Approach',
    team: 'Chaffee SAR',
    timeLabel: '21 min ago',
    notes:
        'Last device ping near the pass. Rapid sweep requested with snow access support and trailhead staging.',
    status: 'Pending',
  ),
  ResponderIncident(
    title: 'Search Area Reassignment',
    location: 'Cottonwood Creek Drainage',
    team: 'Chaffee SAR',
    timeLabel: '33 min ago',
    notes:
        'Operations wants an additional responder for flank coverage after radio contact was lost with the western grid.',
    status: 'Pending',
  ),
];
