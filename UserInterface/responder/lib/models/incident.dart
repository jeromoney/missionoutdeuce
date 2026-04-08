import 'package:shared_models/shared_models.dart';

class ResponderIncident {
  const ResponderIncident({
    required this.id,
    required this.publicId,
    required this.title,
    required this.location,
    required this.team,
    required this.teamPublicId,
    required this.timeLabel,
    required this.notes,
    required this.status,
  });

  final int id;
  final String publicId;
  final String title;
  final String location;
  final String team;
  final String? teamPublicId;
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
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled incident',
      location: json['location'] as String? ?? 'Unknown location',
      team: json['team'] as String? ?? 'Unknown team',
      teamPublicId: json['team_public_id'] as String?,
      timeLabel: formatMissionTimestamp(
        json['created'] as String? ?? '',
        fallback: 'Unknown',
      ),
      notes: json['notes'] as String? ?? '',
      status: responderResponse?['status'] as String? ?? 'Pending',
    );
  }
}
