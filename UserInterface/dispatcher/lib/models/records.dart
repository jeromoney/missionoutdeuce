import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

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
  final DateTime? time;
  final IconData icon;
  final Color color;

  factory EventRecord.fromDeliveryEvent(DeliveryEvent event) {
    return EventRecord(
      title: event.title,
      detail: event.detail,
      time: event.time,
      icon: _iconFromName(event.iconKey),
      color: _colorFromHex(event.colorHex, const Color(0xFF4F6F95)),
    );
  }

  factory EventRecord.fromJson(Map<String, dynamic> json) =>
      EventRecord.fromDeliveryEvent(DeliveryEvent.fromJson(json));
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
