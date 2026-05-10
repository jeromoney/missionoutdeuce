import 'package:shared_models/shared_models.dart';

class ResponderIncident {
  const ResponderIncident._({
    required this.incident,
    required this.responderStatus,
    required String? responderPublicId,
  }) : _responderPublicId = responderPublicId;

  final Incident incident;
  final ResponseStatus? responderStatus;
  final String? _responderPublicId;

  String get publicId => incident.publicId;
  String get title => incident.title;
  String get location => incident.location;
  String get teamPublicId => incident.teamPublicId;
  DateTime? get created => incident.created;
  String get notes => incident.notes;
  String? get priority => incident.priority;
  bool get active => incident.active;
  List<ResponseRecord> get responses => incident.responses;

  ResponseStatus? get status => responderStatus;

  factory ResponderIncident.fromIncident(
    Incident incident, {
    String? responderPublicId,
  }) {
    ResponseStatus? mine;
    if (responderPublicId != null) {
      for (final response in incident.responses) {
        if (response.userPublicId == responderPublicId) {
          mine = response.status;
          break;
        }
      }
    }
    return ResponderIncident._(
      incident: incident,
      responderStatus: mine,
      responderPublicId: responderPublicId,
    );
  }

  factory ResponderIncident.fromJson(
    Map<String, dynamic> json, {
    String? responderPublicId,
  }) =>
      ResponderIncident.fromIncident(
        Incident.fromJson(json),
        responderPublicId: responderPublicId,
      );

  ResponderIncident withResponderResponse(ResponseRecord newResponse) {
    final updated = <ResponseRecord>[];
    var replaced = false;
    for (final existing in incident.responses) {
      if (existing.userPublicId == newResponse.userPublicId) {
        updated.add(newResponse);
        replaced = true;
      } else {
        updated.add(existing);
      }
    }
    if (!replaced) {
      updated.add(newResponse);
    }

    return ResponderIncident.fromIncident(
      incident.copyWith(responses: updated),
      responderPublicId: _responderPublicId,
    );
  }
}
