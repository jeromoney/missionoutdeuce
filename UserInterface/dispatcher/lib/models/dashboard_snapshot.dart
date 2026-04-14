import 'records.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.incidents,
    required this.events,
    required this.baseUrl,
    required this.teamNamesByPublicId,
    required this.responderNamesByPublicId,
  });

  final List<Incident> incidents;
  final List<EventRecord> events;
  final String baseUrl;
  final Map<String, String> teamNamesByPublicId;
  final Map<String, String> responderNamesByPublicId;
}
