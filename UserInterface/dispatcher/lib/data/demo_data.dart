import 'package:flutter/material.dart';

import '../models/records.dart';

const demoIncidents = [
  Incident(
    id: 1,
    publicId: 'incident_injured_climber_demo',
    title: 'Injured Climber Extraction',
    teamPublicId: 'team_chaffee_sar_demo',
    location: 'Mt. Princeton Southwest Gully',
    created: '8 min ago',
    notes:
        'Subject reports lower-leg injury above treeline. Snowpack stable but wind increasing. Air asset on standby if ground extraction stalls.',
    responses: [
      ResponseRecord(
        userPublicId: 'user_justin_demo',
        status: 'Responding',
        rank: 0,
        updated: '8 minutes',
      ),
      ResponseRecord(
        userPublicId: 'user_sarah_demo',
        status: 'Responding',
        rank: 0,
        updated: '7 minutes',
      ),
      ResponseRecord(
        userPublicId: 'user_mike_demo',
        status: 'Pending',
        rank: 1,
        updated: '5 minutes',
      ),
      ResponseRecord(
        userPublicId: 'user_alex_demo',
        status: 'Not Available',
        rank: 2,
        updated: '3 minutes',
      ),
    ],
  ),
  Incident(
    id: 2,
    publicId: 'incident_overdue_snowmobiler_demo',
    title: 'Overdue Snowmobiler',
    teamPublicId: 'team_summit_county_rescue_demo',
    location: 'Georgia Pass East Approach',
    created: '21 min ago',
    notes:
        'Family lost contact after sunset. Last device ping near the pass. Team requested beacon cache and UTV support for rapid sweep.',
    responses: [
      ResponseRecord(
        userPublicId: 'user_taylor_demo',
        status: 'Responding',
        rank: 0,
        updated: '20 minutes',
      ),
      ResponseRecord(
        userPublicId: 'user_chris_demo',
        status: 'Pending',
        rank: 1,
        updated: '18 minutes',
      ),
      ResponseRecord(
        userPublicId: 'user_jordan_demo',
        status: 'Pending',
        rank: 1,
        updated: '16 minutes',
      ),
    ],
  ),
  Incident(
    id: 3,
    publicId: 'incident_avalanche_report_demo',
    title: 'Avalanche Witness Report',
    teamPublicId: 'team_alpine_rescue_demo',
    location: 'Monarch Crest Sector 4',
    created: '42 min ago',
    notes:
        'Witness reported slide path crossing summer route. No confirmed victim yet. Dispatcher holding team in advisory mode pending sheriff update.',
    active: false,
    responses: [
      ResponseRecord(
        userPublicId: 'user_casey_demo',
        status: 'Responding',
        rank: 0,
        updated: '41 minutes',
      ),
      ResponseRecord(
        userPublicId: 'user_riley_demo',
        status: 'Not Available',
        rank: 2,
        updated: '37 minutes',
      ),
      ResponseRecord(
        userPublicId: 'user_morgan_demo',
        status: 'Pending',
        rank: 1,
        updated: '35 minutes',
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
