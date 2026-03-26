import 'package:flutter/material.dart';

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.team,
    required this.location,
    required this.created,
    required this.notes,
    required this.responses,
    this.active = true,
  });

  final int id;
  final String title;
  final String team;
  final String location;
  final String created;
  final String notes;
  final List<ResponseRecord> responses;
  final bool active;

  Incident copyWith({
    int? id,
    String? title,
    String? team,
    String? location,
    String? created,
    String? notes,
    List<ResponseRecord>? responses,
    bool? active,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      team: team ?? this.team,
      location: location ?? this.location,
      created: created ?? this.created,
      notes: notes ?? this.notes,
      responses: responses ?? this.responses,
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
      title: json['title'] as String? ?? 'Untitled incident',
      team: json['team'] as String? ?? 'Unknown team',
      location: json['location'] as String? ?? 'Unknown location',
      created: json['created'] as String? ?? 'Just now',
      notes: json['notes'] as String? ?? '',
      responses: responsesJson,
      active: json['active'] as bool? ?? true,
    );
  }
}

class ResponseRecord {
  const ResponseRecord({
    required this.name,
    required this.status,
    required this.detail,
    required this.rank,
  });

  final String name;
  final String status;
  final String detail;
  final int rank;

  factory ResponseRecord.fromJson(Map<String, dynamic> json) {
    return ResponseRecord(
      name: json['name'] as String? ?? 'Unknown responder',
      status: json['status'] as String? ?? 'Pending',
      detail: json['detail'] as String? ?? '',
      rank: json['rank'] as int? ?? _defaultRank(json['status'] as String?),
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
      time: json['time'] as String? ?? 'now',
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
