import 'package:flutter_test/flutter_test.dart';
import 'package:missionout_responder/models/incident.dart';
import 'package:shared_models/shared_models.dart';

Incident _buildIncident({List<ResponseRecord> responses = const []}) {
  return Incident(
    publicId: 'incident-public-id',
    title: 'Field mission',
    teamPublicId: 'team-public-id',
    location: 'North ridge',
    created: DateTime.utc(2026, 5, 1, 12),
    notes: 'Steep terrain.',
    responses: responses,
  );
}

ResponseRecord _response({
  required String userPublicId,
  ResponseStatus? status = ResponseStatus.pending,
  int rank = 1,
  DateTime? updated,
}) {
  return ResponseRecord(
    userPublicId: userPublicId,
    status: status,
    rank: rank,
    updated: updated ?? DateTime.utc(2026, 5, 1, 12),
  );
}

void main() {
  group('ResponderIncident.fromIncident', () {
    test('resolves status from the matching response by user_public_id', () {
      final incident = _buildIncident(
        responses: [
          _response(userPublicId: 'other-user', status: ResponseStatus.pending),
          _response(
            userPublicId: 'responder-user',
            status: ResponseStatus.responding,
          ),
        ],
      );

      final wrapped = ResponderIncident.fromIncident(
        incident,
        responderPublicId: 'responder-user',
      );

      expect(wrapped.responderStatus, ResponseStatus.responding);
      expect(wrapped.status, ResponseStatus.responding);
      expect(wrapped.publicId, 'incident-public-id');
      expect(wrapped.responses, hasLength(2));
    });

    test('yields null status when responderPublicId is null', () {
      final incident = _buildIncident(
        responses: [
          _response(
            userPublicId: 'responder-user',
            status: ResponseStatus.responding,
          ),
        ],
      );

      final wrapped = ResponderIncident.fromIncident(incident);

      expect(wrapped.responderStatus, isNull);
      expect(wrapped.status, isNull);
    });

    test('yields null status when responderPublicId is absent from responses',
        () {
      final incident = _buildIncident(
        responses: [
          _response(userPublicId: 'someone-else'),
        ],
      );

      final wrapped = ResponderIncident.fromIncident(
        incident,
        responderPublicId: 'responder-user',
      );

      expect(wrapped.responderStatus, isNull);
    });

    test('exposes incident pass-through getters', () {
      final incident = _buildIncident();

      final wrapped = ResponderIncident.fromIncident(
        incident,
        responderPublicId: 'responder-user',
      );

      expect(wrapped.title, 'Field mission');
      expect(wrapped.location, 'North ridge');
      expect(wrapped.teamPublicId, 'team-public-id');
      expect(wrapped.notes, 'Steep terrain.');
      expect(wrapped.created, DateTime.utc(2026, 5, 1, 12));
      expect(wrapped.active, isTrue);
      expect(wrapped.priority, isNull);
    });
  });

  group('ResponderIncident.fromJson', () {
    test('delegates to Incident.fromJson and resolves responder status', () {
      final wrapped = ResponderIncident.fromJson(
        {
          'public_id': 'incident-public-id',
          'team_public_id': 'team-public-id',
          'title': 'Field mission',
          'location': 'North ridge',
          'created': '2026-05-01T12:00:00Z',
          'notes': '',
          'active': true,
          'responses': [
            {
              'user_public_id': 'responder-user',
              'status': 'Responding',
              'rank': 0,
              'updated': '2026-05-01T13:00:00Z',
            },
          ],
        },
        responderPublicId: 'responder-user',
      );

      expect(wrapped.responderStatus, ResponseStatus.responding);
      expect(wrapped.publicId, 'incident-public-id');
    });
  });

  group('ResponderIncident.withResponderResponse', () {
    test('replaces an existing response for the same user_public_id', () {
      final incident = _buildIncident(
        responses: [
          _response(userPublicId: 'other-user', status: ResponseStatus.pending),
          _response(
            userPublicId: 'responder-user',
            status: ResponseStatus.pending,
          ),
        ],
      );
      final wrapped = ResponderIncident.fromIncident(
        incident,
        responderPublicId: 'responder-user',
      );

      final updated = wrapped.withResponderResponse(
        _response(
          userPublicId: 'responder-user',
          status: ResponseStatus.responding,
          rank: 0,
          updated: DateTime.utc(2026, 5, 2, 9),
        ),
      );

      expect(updated.responses, hasLength(2));
      expect(updated.responderStatus, ResponseStatus.responding);
      final mine = updated.responses
          .where((r) => r.userPublicId == 'responder-user')
          .single;
      expect(mine.status, ResponseStatus.responding);
      expect(mine.updated, DateTime.utc(2026, 5, 2, 9));
    });

    test('appends a new response when the responder has not responded yet', () {
      final incident = _buildIncident(
        responses: [
          _response(userPublicId: 'other-user'),
        ],
      );
      final wrapped = ResponderIncident.fromIncident(
        incident,
        responderPublicId: 'responder-user',
      );

      final updated = wrapped.withResponderResponse(
        _response(
          userPublicId: 'responder-user',
          status: ResponseStatus.responding,
          rank: 0,
        ),
      );

      expect(updated.responses, hasLength(2));
      expect(updated.responderStatus, ResponseStatus.responding);
    });

    test('preserves the original responder context across updates', () {
      final incident = _buildIncident(
        responses: [
          _response(userPublicId: 'responder-user'),
        ],
      );
      final wrapped = ResponderIncident.fromIncident(
        incident,
        responderPublicId: 'responder-user',
      );

      final next = wrapped
          .withResponderResponse(
            _response(
              userPublicId: 'responder-user',
              status: ResponseStatus.notAvailable,
              rank: 2,
            ),
          )
          .withResponderResponse(
            _response(
              userPublicId: 'responder-user',
              status: ResponseStatus.responding,
              rank: 0,
            ),
          );

      expect(next.responses, hasLength(1));
      expect(next.responderStatus, ResponseStatus.responding);
    });
  });
}
