import 'package:flutter_test/flutter_test.dart';
import 'package:missionout/models/records.dart';

void main() {
  test('Incident.fromJson parses canonical incident and response fields', () {
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
    expect(incident.created, 'January 1, 2020');
    expect(incident.responses, hasLength(1));
    expect(incident.responses.first.userPublicId, 'user-public-id');
    expect(incident.responses.first.status, 'Responding');
    expect(incident.responses.first.updated, 'January 2, 2020');
  });
}
