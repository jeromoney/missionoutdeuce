import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('Incident.fromJson', () {
    test('parses canonical incident and response fields', () {
      final incident = Incident.fromJson({
        'id': 12,
        'public_id': 'incident-public-id',
        'team_public_id': 'team-public-id',
        'title': 'Field mission',
        'location': 'North ridge',
        'created': '2020-01-01T12:00:00Z',
        'notes': 'Steep terrain.',
        'priority': 'high',
        'active': true,
        'responses': [
          {
            'user_public_id': 'user-public-id',
            'status': 'Responding',
            'rank': 0,
            'updated': '2020-01-02T12:00:00Z',
          },
        ],
      });

      expect(incident.publicId, 'incident-public-id');
      expect(incident.teamPublicId, 'team-public-id');
      expect(incident.priority, 'high');
      expect(incident.created, DateTime.utc(2020, 1, 1, 12));
      expect(incident.responses, hasLength(1));
      expect(incident.responses.first.userPublicId, 'user-public-id');
      expect(incident.responses.first.status, ResponseStatus.responding);
      expect(incident.responses.first.updated, DateTime.utc(2020, 1, 2, 12));
    });

    test('yields null for missing or malformed timestamps', () {
      final incident = Incident.fromJson({
        'public_id': 'incident-public-id',
        'team_public_id': 'team-public-id',
        'title': 'Field mission',
        'location': 'North ridge',
        'created': '',
        'notes': '',
        'active': true,
        'responses': [
          {
            'user_public_id': 'user-public-id',
            'status': 'Pending',
            'rank': 1,
            'updated': 'not a date',
          },
        ],
      });

      expect(incident.created, isNull);
      expect(incident.responses.first.updated, isNull);
    });

    test('yields null status for unknown labels', () {
      final incident = Incident.fromJson({
        'public_id': 'incident-public-id',
        'team_public_id': 'team-public-id',
        'title': 'Field mission',
        'location': 'North ridge',
        'created': '2020-01-01T12:00:00Z',
        'notes': '',
        'active': true,
        'responses': [
          {
            'user_public_id': 'user-public-id',
            'status': 'Mobilizing',
            'rank': 0,
            'updated': '2020-01-02T12:00:00Z',
          },
        ],
      });

      expect(incident.responses.first.status, isNull);
    });
  });
}
