import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

class Incident {
  const Incident({
    required this.id,
    required this.publicId,
    required this.title,
    required this.teamPublicId,
    required this.location,
    required this.created,
    required this.notes,
    required this.responses,
    this.priority,
    this.active = true,
  });

  final int id;
  final String publicId;
  final String title;
  final String teamPublicId;
  final String location;
  final String created;
  final String notes;
  final List<ResponseRecord> responses;
  final String? priority;
  final bool active;

  Incident copyWith({
    int? id,
    String? publicId,
    String? title,
    String? teamPublicId,
    String? location,
    String? created,
    String? notes,
    List<ResponseRecord>? responses,
    String? priority,
    bool? active,
  }) {
    return Incident(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      title: title ?? this.title,
      teamPublicId: teamPublicId ?? this.teamPublicId,
      location: location ?? this.location,
      created: created ?? this.created,
      notes: notes ?? this.notes,
      responses: responses ?? this.responses,
      priority: priority ?? this.priority,
      active: active ?? this.active,
    );
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    final responsesJson = (json['responses'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ResponseRecord.fromJson)
        .toList();

    return Incident(
      id: json['id'] as int? ?? 0,
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled incident',
      teamPublicId: json['team_public_id'] as String? ?? '',
      location: json['location'] as String? ?? 'Unknown location',
      created: formatMissionTimestamp(
        json['created'] as String? ?? '',
        fallback: 'Just now',
      ),
      notes: json['notes'] as String? ?? '',
      responses: responsesJson,
      priority: json['priority'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}

class ResponseRecord {
  const ResponseRecord({
    required this.userPublicId,
    required this.status,
    required this.rank,
    required this.updated,
  });

  final String userPublicId;
  final String status;
  final int rank;
  final String updated;

  factory ResponseRecord.fromJson(Map<String, dynamic> json) {
    return ResponseRecord(
      userPublicId: json['user_public_id'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      rank: json['rank'] as int? ?? _defaultRank(json['status'] as String?),
      updated: formatMissionTimestamp(
        json['updated'] as String? ?? '',
        fallback: 'Unknown',
      ),
    );
  }
}

class EventRecord {
  const EventRecord({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final String time;
  final IconData icon;
  final Color color;

  factory EventRecord.fromJson(Map<String, dynamic> json) {
    return EventRecord(
      title: json['title'] as String? ?? 'Event',
      detail: json['detail'] as String? ?? '',
      time: formatMissionTimestamp(
        json['time'] as String? ?? '',
        fallback: 'Now',
      ),
      icon: _iconFromName(json['icon'] as String?),
      color: _colorFromHex(json['color'] as String?, const Color(0xFF4F6F95)),
    );
  }
}

Color _colorFromHex(String? value, Color fallback) {
  if (value == null || value.isEmpty) {
    return fallback;
  }

  final cleaned = value.replaceFirst('#', '');
  final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    return fallback;
  }
  return Color(parsed);
}

int _defaultRank(String? status) {
  switch (status) {
    case 'Responding':
      return 0;
    case 'Pending':
      return 1;
    default:
      return 2;
  }
}

IconData _iconFromName(String? name) {
  switch (name) {
    case 'task_alt':
      return Icons.task_alt_rounded;
    case 'call':
      return Icons.call_rounded;
    default:
      return Icons.notifications_active_rounded;
  }
}
