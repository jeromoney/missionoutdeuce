import 'package:shared_models/shared_models.dart';

import '../models/incident.dart';

const _responderPublicId = 'user_justin_demo';
final DateTime _now = DateTime.now();

final responderIncidents = <ResponderIncident>[
  ResponderIncident.fromIncident(
    Incident(
      publicId: 'incident_injured_climber_demo',
      title: 'Injured Climber Extraction',
      location: 'Mt. Princeton Southwest Gully',
      teamPublicId: 'team_chaffee_sar_demo',
      created: _now.subtract(const Duration(minutes: 8)),
      notes:
          'Subject reports lower-leg injury above treeline. Wind increasing. Ground extraction underway.',
      responses: [
        ResponseRecord(
          userPublicId: _responderPublicId,
          status: ResponseStatus.responding,
          rank: 0,
          updated: _now.subtract(const Duration(minutes: 8)),
        ),
      ],
    ),
    responderPublicId: _responderPublicId,
  ),
  ResponderIncident.fromIncident(
    Incident(
      publicId: 'incident_overdue_snowmobiler_demo',
      title: 'Overdue Snowmobiler',
      location: 'Georgia Pass East Approach',
      teamPublicId: 'team_chaffee_sar_demo',
      created: _now.subtract(const Duration(minutes: 21)),
      notes:
          'Last device ping near the pass. Rapid sweep requested with snow access support and trailhead staging.',
      responses: [
        ResponseRecord(
          userPublicId: _responderPublicId,
          status: ResponseStatus.pending,
          rank: 1,
          updated: _now.subtract(const Duration(minutes: 21)),
        ),
      ],
    ),
    responderPublicId: _responderPublicId,
  ),
  ResponderIncident.fromIncident(
    Incident(
      publicId: 'incident_search_reassignment_demo',
      title: 'Search Area Reassignment',
      location: 'Cottonwood Creek Drainage',
      teamPublicId: 'team_chaffee_sar_demo',
      created: _now.subtract(const Duration(minutes: 33)),
      notes:
          'Operations wants an additional responder for flank coverage after radio contact was lost with the western grid.',
      responses: [
        ResponseRecord(
          userPublicId: _responderPublicId,
          status: ResponseStatus.pending,
          rank: 1,
          updated: _now.subtract(const Duration(minutes: 33)),
        ),
      ],
    ),
    responderPublicId: _responderPublicId,
  ),
];
