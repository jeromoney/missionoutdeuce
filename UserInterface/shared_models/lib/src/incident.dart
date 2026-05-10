import 'response_status.dart';

class Incident {
  const Incident({
    required this.publicId,
    required this.title,
    required this.teamPublicId,
    required this.location,
    required this.created,
    required this.notes,
    required this.responses,
    this.priority,
    this.active = true,
  });

  final String publicId;
  final String title;
  final String teamPublicId;
  final String location;
  final DateTime? created;
  final String notes;
  final List<ResponseRecord> responses;
  final String? priority;
  final bool active;

  Incident copyWith({
    String? publicId,
    String? title,
    String? teamPublicId,
    String? location,
    DateTime? created,
    String? notes,
    List<ResponseRecord>? responses,
    String? priority,
    bool? active,
  }) {
    return Incident(
      publicId: publicId ?? this.publicId,
      title: title ?? this.title,
      teamPublicId: teamPublicId ?? this.teamPublicId,
      location: location ?? this.location,
      created: created ?? this.created,
      notes: notes ?? this.notes,
      responses: responses ?? this.responses,
      priority: priority ?? this.priority,
      active: active ?? this.active,
    );
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    final responsesJson = (json['responses'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ResponseRecord.fromJson)
        .toList();

    return Incident(
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled incident',
      teamPublicId: json['team_public_id'] as String? ?? '',
      location: json['location'] as String? ?? 'Unknown location',
      created: DateTime.tryParse(json['created'] as String? ?? ''),
      notes: json['notes'] as String? ?? '',
      responses: responsesJson,
      priority: json['priority'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}

class ResponseRecord {
  const ResponseRecord({
    required this.userPublicId,
    required this.status,
    required this.rank,
    required this.updated,
  });

  final String userPublicId;
  final ResponseStatus? status;
  final int rank;
  final DateTime? updated;

  factory ResponseRecord.fromJson(Map<String, dynamic> json) {
    final status = ResponseStatus.fromLabel(json['status'] as String?);
    return ResponseRecord(
      userPublicId: json['user_public_id'] as String? ?? '',
      status: status,
      rank: json['rank'] as int? ?? _defaultRank(status),
      updated: DateTime.tryParse(json['updated'] as String? ?? ''),
    );
  }
}

int _defaultRank(ResponseStatus? status) {
  switch (status) {
    case ResponseStatus.responding:
      return 0;
    case ResponseStatus.pending:
      return 1;
    case ResponseStatus.notAvailable:
    case null:
      return 2;
  }
}
