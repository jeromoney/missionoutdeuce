import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:missionout/models/records.dart';

void main() {
  const fallbackColor = Color(0xFF4F6F95);

  Map<String, dynamic> payload({
    String? icon,
    String? color,
    String time = '2026-05-01T12:00:00Z',
  }) {
    return {
      'title': 'Delivered',
      'detail': 'Pager delivered to responder',
      'time': time,
      'icon': icon,
      'color': color,
    };
  }

  group('EventRecord.fromJson icon mapping', () {
    test('maps task_alt to Icons.task_alt_rounded', () {
      final record = EventRecord.fromJson(payload(icon: 'task_alt'));
      expect(record.icon, Icons.task_alt_rounded);
    });

    test('maps call to Icons.call_rounded', () {
      final record = EventRecord.fromJson(payload(icon: 'call'));
      expect(record.icon, Icons.call_rounded);
    });

    test('falls back to notifications_active for unknown icon keys', () {
      final record = EventRecord.fromJson(payload(icon: 'mystery_icon'));
      expect(record.icon, Icons.notifications_active_rounded);
    });

    test('falls back to notifications_active when icon is null', () {
      final record = EventRecord.fromJson(payload(icon: null));
      expect(record.icon, Icons.notifications_active_rounded);
    });
  });

  group('EventRecord.fromJson color parsing', () {
    test('parses a 6-digit hex with leading hash', () {
      final record = EventRecord.fromJson(payload(color: '#FF8800'));
      expect(record.color, const Color(0xFFFF8800));
    });

    test('parses a 6-digit hex without leading hash', () {
      final record = EventRecord.fromJson(payload(color: 'FF8800'));
      expect(record.color, const Color(0xFFFF8800));
    });

    test('parses an 8-digit hex with alpha channel', () {
      final record = EventRecord.fromJson(payload(color: '#80FF8800'));
      expect(record.color, const Color(0x80FF8800));
    });

    test('falls back when color is null', () {
      final record = EventRecord.fromJson(payload(color: null));
      expect(record.color, fallbackColor);
    });

    test('falls back when color is empty', () {
      final record = EventRecord.fromJson(payload(color: ''));
      expect(record.color, fallbackColor);
    });

    test('falls back when color is unparseable garbage', () {
      final record = EventRecord.fromJson(payload(color: 'not-hex'));
      expect(record.color, fallbackColor);
    });
  });

  group('EventRecord.fromJson field passthrough', () {
    test('preserves title, detail, and parsed time', () {
      final record = EventRecord.fromJson({
        'title': 'Delivered',
        'detail': 'Pager delivered to responder',
        'time': '2026-05-01T12:00:00Z',
        'icon': 'call',
        'color': '#FF8800',
      });

      expect(record.title, 'Delivered');
      expect(record.detail, 'Pager delivered to responder');
      expect(record.time, DateTime.utc(2026, 5, 1, 12));
    });

    test('yields null time when timestamp is missing or unparseable', () {
      final record = EventRecord.fromJson(payload(time: 'not a date'));
      expect(record.time, isNull);
    });
  });
}
