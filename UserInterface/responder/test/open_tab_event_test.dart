import 'package:flutter_test/flutter_test.dart';
import 'package:missionout_responder/models/open_tab_event.dart';

void main() {
  group('OpenTabEvent.fromPayload', () {
    test('parses a fully populated incident.created payload', () {
      final event = OpenTabEvent.fromPayload(
        type: 'incident.created',
        data:
            '{"title":"New mission","incident_public_id":"incident-1","team_public_id":"team-1","created":"2026-05-01T12:00:00Z"}',
      );

      expect(event.type, 'incident.created');
      expect(event.title, 'New mission');
      expect(event.incidentPublicId, 'incident-1');
      expect(event.teamPublicId, 'team-1');
      expect(event.created, DateTime.utc(2026, 5, 1, 12));
      expect(event.isIncidentCreated, isTrue);
    });

    test('falls back to a default title when title is missing', () {
      final event = OpenTabEvent.fromPayload(
        type: 'incident.created',
        data: '{}',
      );

      expect(event.title, 'Mission update');
      expect(event.incidentPublicId, isNull);
      expect(event.teamPublicId, isNull);
      expect(event.created, isNull);
    });

    test('returns null created when the timestamp is unparseable', () {
      final event = OpenTabEvent.fromPayload(
        type: 'incident.created',
        data: '{"title":"x","created":"not a date"}',
      );

      expect(event.created, isNull);
    });

    test('returns null created when the timestamp is missing entirely', () {
      final event = OpenTabEvent.fromPayload(
        type: 'incident.created',
        data: '{"title":"x"}',
      );

      expect(event.created, isNull);
    });

    test('throws FormatException when the payload is not a JSON object', () {
      expect(
        () => OpenTabEvent.fromPayload(
          type: 'incident.created',
          data: '[]',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when the payload is a JSON string', () {
      expect(
        () => OpenTabEvent.fromPayload(
          type: 'incident.created',
          data: '"hello"',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rethrows FormatException for invalid JSON', () {
      expect(
        () => OpenTabEvent.fromPayload(
          type: 'incident.created',
          data: 'not json',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OpenTabEvent.isIncidentCreated', () {
    test('is true only for the canonical incident.created event type', () {
      final created = OpenTabEvent.fromPayload(
        type: 'incident.created',
        data: '{"title":"x"}',
      );
      final updated = OpenTabEvent.fromPayload(
        type: 'incident.updated',
        data: '{"title":"x"}',
      );

      expect(created.isIncidentCreated, isTrue);
      expect(updated.isIncidentCreated, isFalse);
    });
  });
}
