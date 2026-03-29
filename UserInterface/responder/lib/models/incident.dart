import 'package:shared_models/shared_models.dart';

class ResponderIncident {
  const ResponderIncident({
    required this.id,
    required this.title,
    required this.location,
    required this.team,
    required this.timeLabel,
    required this.notes,
    required this.status,
  });

  final int id;
  final String title;
  final String location;
  final String team;
  final String timeLabel;
  final String notes;
  final String status;

  factory ResponderIncident.fromJson(
    Map<String, dynamic> json, {
    String? responderName,
  }) {
    final responses = (json['responses'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    Map<String, dynamic>? responderResponse;
    for (final response in responses) {
      if (response['name'] == responderName) {
        responderResponse = response;
        break;
      }
    }

    return ResponderIncident(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled incident',
      location: json['location'] as String? ?? 'Unknown location',
      team: json['team'] as String? ?? 'Unknown team',
      timeLabel: formatMissionTimestamp(
        json['created'] as String? ?? '',
        fallback: 'Unknown',
      ),
      notes: json['notes'] as String? ?? '',
      status: responderResponse?['status'] as String? ?? 'Pending',
    );
  }
}
