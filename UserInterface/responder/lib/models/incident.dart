import 'package:shared_models/shared_models.dart';

class ResponderIncident {
  const ResponderIncident({
    required this.id,
    required this.publicId,
    required this.title,
    required this.location,
    required this.teamPublicId,
    required this.timeLabel,
    required this.notes,
    required this.status,
    required this.responses,
    this.priority,
  });

  final int id;
  final String publicId;
  final String title;
  final String location;
  final String teamPublicId;
  final String timeLabel;
  final String notes;
  final String status;
  final List<ResponderIncidentResponse> responses;
  final String? priority;

  factory ResponderIncident.fromJson(
    Map<String, dynamic> json, {
    String? responderPublicId,
  }) {
    final responses = (json['responses'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ResponderIncidentResponse.fromJson)
        .toList();
    ResponderIncidentResponse? responderResponse;
    for (final response in responses) {
      if (response.userPublicId == responderPublicId) {
        responderResponse = response;
        break;
      }
    }

    return ResponderIncident(
      id: json['id'] as int? ?? 0,
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled incident',
      location: json['location'] as String? ?? 'Unknown location',
      teamPublicId: json['team_public_id'] as String? ?? '',
      timeLabel: formatMissionTimestamp(
        json['created'] as String? ?? '',
        fallback: 'Unknown',
      ),
      notes: json['notes'] as String? ?? '',
      status: responderResponse?.status ?? 'Pending',
      responses: responses,
      priority: json['priority'] as String?,
    );
  }
}

class ResponderIncidentResponse {
  const ResponderIncidentResponse({
    required this.userPublicId,
    required this.status,
    required this.rank,
    required this.updated,
  });

  final String userPublicId;
  final String status;
  final int rank;
  final String updated;

  factory ResponderIncidentResponse.fromJson(Map<String, dynamic> json) {
    return ResponderIncidentResponse(
      userPublicId: json['user_public_id'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      rank: json['rank'] as int? ?? 0,
      updated: formatMissionTimestamp(
        json['updated'] as String? ?? '',
        fallback: 'Unknown',
      ),
    );
  }
}
