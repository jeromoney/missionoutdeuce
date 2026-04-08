import 'dart:convert';

class OpenTabEvent {
  const OpenTabEvent({
    required this.type,
    required this.title,
    this.incidentPublicId,
    this.teamPublicId,
    this.created,
  });

  final String type;
  final String title;
  final String? incidentPublicId;
  final String? teamPublicId;
  final DateTime? created;

  bool get isIncidentCreated => type == 'incident.created';

  factory OpenTabEvent.fromPayload({
    required String type,
    required String data,
  }) {
    final decoded = jsonDecode(data);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Realtime event payload must be a JSON object.',
      );
    }

    return OpenTabEvent(
      type: type,
      title: decoded['title'] as String? ?? 'Mission update',
      incidentPublicId: decoded['incident_public_id'] as String?,
      teamPublicId: decoded['team_public_id'] as String?,
      created: DateTime.tryParse(decoded['created'] as String? ?? ''),
    );
  }
}
