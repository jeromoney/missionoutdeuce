import 'records.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.incidents,
    required this.events,
    required this.baseUrl,
  });

  final List<Incident> incidents;
  final List<EventRecord> events;
  final String baseUrl;
}
