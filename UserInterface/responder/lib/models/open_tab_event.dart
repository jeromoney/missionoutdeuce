import 'dart:convert';

class OpenTabEvent {
  const OpenTabEvent({
    required this.type,
    required this.title,
    this.incidentId,
    this.teamId,
    this.created,
  });

  final String type;
  final String title;
  final int? incidentId;
  final int? teamId;
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
      incidentId: decoded['incident_id'] as int?,
      teamId: decoded['team_id'] as int?,
      created: DateTime.tryParse(decoded['created'] as String? ?? ''),
    );
  }
}
