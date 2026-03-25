import 'package:flutter/material.dart';

import '../models/records.dart';

const demoIncidents = [
  Incident(
    id: 1,
    title: 'Injured Climber Extraction',
    team: 'Chaffee SAR',
    location: 'Mt. Princeton Southwest Gully',
    created: '8 min ago',
    notes:
        'Subject reports lower-leg injury above treeline. Snowpack stable but wind increasing. Air asset on standby if ground extraction stalls.',
    responses: [
      ResponseRecord(
        name: 'Justin M.',
        status: 'Responding',
        detail: 'En route from Buena Vista with litter trailer.',
        rank: 0,
      ),
      ResponseRecord(
        name: 'Sarah K.',
        status: 'Responding',
        detail: 'Switching to radio channel SAR-2 at trailhead.',
        rank: 0,
      ),
      ResponseRecord(
        name: 'Mike D.',
        status: 'Pending',
        detail: 'Push delivered to Android device, no acknowledgement yet.',
        rank: 1,
      ),
      ResponseRecord(
        name: 'Alex R.',
        status: 'Not Available',
        detail: 'Marked unavailable for overnight duty cycle.',
        rank: 2,
      ),
    ],
  ),
  Incident(
    id: 2,
    title: 'Overdue Snowmobiler',
    team: 'Summit County Rescue',
    location: 'Georgia Pass East Approach',
    created: '21 min ago',
    notes:
        'Family lost contact after sunset. Last device ping near the pass. Team requested beacon cache and UTV support for rapid sweep.',
    responses: [
      ResponseRecord(
        name: 'Taylor P.',
        status: 'Responding',
        detail: 'Trailer loaded and meeting command at lot B.',
        rank: 0,
      ),
      ResponseRecord(
        name: 'Chris E.',
        status: 'Pending',
        detail: 'Primary push sent, SMS escalation queued in 4 minutes.',
        rank: 1,
      ),
      ResponseRecord(
        name: 'Jordan W.',
        status: 'Pending',
        detail: 'iPhone critical alert token valid, awaiting acknowledgement.',
        rank: 1,
      ),
    ],
  ),
  Incident(
    id: 3,
    title: 'Avalanche Witness Report',
    team: 'Alpine Rescue',
    location: 'Monarch Crest Sector 4',
    created: '42 min ago',
    notes:
        'Witness reported slide path crossing summer route. No confirmed victim yet. Dispatcher holding team in advisory mode pending sheriff update.',
    active: false,
    responses: [
      ResponseRecord(
        name: 'Casey L.',
        status: 'Responding',
        detail: 'Monitoring and staged for recon if upgraded.',
        rank: 0,
      ),
      ResponseRecord(
        name: 'Riley T.',
        status: 'Not Available',
        detail: 'No overnight coverage due to out-of-county travel.',
        rank: 2,
      ),
      ResponseRecord(
        name: 'Morgan F.',
        status: 'Pending',
        detail: 'Web-visible only, not currently on a registered device.',
        rank: 1,
      ),
    ],
  ),
];

const List<Incident> demoIncidentsNull = [];

const demoEvents = [
  EventRecord(
    title: 'Primary FCM burst completed',
    detail:
        '12 Android devices received the first-wave push for Injured Climber Extraction.',
    time: '2m',
    icon: Icons.notifications_active_rounded,
    color: Color(0xFF4F6F95),
  ),
  EventRecord(
    title: 'Responder acknowledged on lock screen',
    detail:
        'Sarah K. marked Responding from the native alert screen before opening the app.',
    time: '4m',
    icon: Icons.task_alt_rounded,
    color: Color(0xFF3F6D91),
  ),
  EventRecord(
    title: 'SMS escalation armed',
    detail:
        'Chris E. remains pending. Twilio fallback will send in 4 minutes if status does not change.',
    time: '6m',
    icon: Icons.call_rounded,
    color: Color(0xFF6D87A3),
  ),
  EventRecord(
    title: 'APNs critical token healthy',
    detail:
        'iOS delivery checks passed for 7 active responder devices in Summit County Rescue.',
    time: '11m',
    icon: Icons.notifications_active_rounded,
    color: Color(0xFF4F6F95),
  ),
];
