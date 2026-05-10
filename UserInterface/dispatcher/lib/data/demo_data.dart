import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../models/records.dart';

final DateTime _now = DateTime.now();

final demoIncidents = <Incident>[
  Incident(
    publicId: 'incident_injured_climber_demo',
    title: 'Injured Climber Extraction',
    teamPublicId: 'team_chaffee_sar_demo',
    location: 'Mt. Princeton Southwest Gully',
    created: _now.subtract(const Duration(minutes: 8)),
    notes:
        'Subject reports lower-leg injury above treeline. Snowpack stable but wind increasing. Air asset on standby if ground extraction stalls.',
    responses: [
      ResponseRecord(
        userPublicId: 'user_justin_demo',
        status: ResponseStatus.responding,
        rank: 0,
        updated: _now.subtract(const Duration(minutes: 8)),
      ),
      ResponseRecord(
        userPublicId: 'user_sarah_demo',
        status: ResponseStatus.responding,
        rank: 0,
        updated: _now.subtract(const Duration(minutes: 7)),
      ),
      ResponseRecord(
        userPublicId: 'user_mike_demo',
        status: ResponseStatus.pending,
        rank: 1,
        updated: _now.subtract(const Duration(minutes: 5)),
      ),
      ResponseRecord(
        userPublicId: 'user_alex_demo',
        status: ResponseStatus.notAvailable,
        rank: 2,
        updated: _now.subtract(const Duration(minutes: 3)),
      ),
    ],
  ),
  Incident(
    publicId: 'incident_overdue_snowmobiler_demo',
    title: 'Overdue Snowmobiler',
    teamPublicId: 'team_summit_county_rescue_demo',
    location: 'Georgia Pass East Approach',
    created: _now.subtract(const Duration(minutes: 21)),
    notes:
        'Family lost contact after sunset. Last device ping near the pass. Team requested beacon cache and UTV support for rapid sweep.',
    responses: [
      ResponseRecord(
        userPublicId: 'user_taylor_demo',
        status: ResponseStatus.responding,
        rank: 0,
        updated: _now.subtract(const Duration(minutes: 20)),
      ),
      ResponseRecord(
        userPublicId: 'user_chris_demo',
        status: ResponseStatus.pending,
        rank: 1,
        updated: _now.subtract(const Duration(minutes: 18)),
      ),
      ResponseRecord(
        userPublicId: 'user_jordan_demo',
        status: ResponseStatus.pending,
        rank: 1,
        updated: _now.subtract(const Duration(minutes: 16)),
      ),
    ],
  ),
  Incident(
    publicId: 'incident_avalanche_report_demo',
    title: 'Avalanche Witness Report',
    teamPublicId: 'team_alpine_rescue_demo',
    location: 'Monarch Crest Sector 4',
    created: _now.subtract(const Duration(minutes: 42)),
    notes:
        'Witness reported slide path crossing summer route. No confirmed victim yet. Dispatcher holding team in advisory mode pending sheriff update.',
    active: false,
    responses: [
      ResponseRecord(
        userPublicId: 'user_casey_demo',
        status: ResponseStatus.responding,
        rank: 0,
        updated: _now.subtract(const Duration(minutes: 41)),
      ),
      ResponseRecord(
        userPublicId: 'user_riley_demo',
        status: ResponseStatus.notAvailable,
        rank: 2,
        updated: _now.subtract(const Duration(minutes: 37)),
      ),
      ResponseRecord(
        userPublicId: 'user_morgan_demo',
        status: ResponseStatus.pending,
        rank: 1,
        updated: _now.subtract(const Duration(minutes: 35)),
      ),
    ],
  ),
];

const List<Incident> demoIncidentsNull = [];

final demoEvents = <EventRecord>[
  EventRecord(
    title: 'Primary FCM burst completed',
    detail:
        '12 Android devices received the first-wave push for Injured Climber Extraction.',
    time: _now.subtract(const Duration(minutes: 2)),
    icon: Icons.notifications_active_rounded,
    color: const Color(0xFF4F6F95),
  ),
  EventRecord(
    title: 'Responder acknowledged on lock screen',
    detail:
        'Sarah K. marked Responding from the native alert screen before opening the app.',
    time: _now.subtract(const Duration(minutes: 4)),
    icon: Icons.task_alt_rounded,
    color: const Color(0xFF3F6D91),
  ),
  EventRecord(
    title: 'SMS escalation armed',
    detail:
        'Chris E. remains pending. Twilio fallback will send in 4 minutes if status does not change.',
    time: _now.subtract(const Duration(minutes: 6)),
    icon: Icons.call_rounded,
    color: const Color(0xFF6D87A3),
  ),
  EventRecord(
    title: 'APNs critical token healthy',
    detail:
        'iOS delivery checks passed for 7 active responder devices in Summit County Rescue.',
    time: _now.subtract(const Duration(minutes: 11)),
    icon: Icons.notifications_active_rounded,
    color: const Color(0xFF4F6F95),
  ),
];
