import 'records.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.incidents,
    required this.events,
    required this.usingFallback,
    required this.baseUrl,
    required this.connectionLabel,
    this.errorMessage,
  });

  final List<Incident> incidents;
  final List<EventRecord> events;
  final bool usingFallback;
  final String baseUrl;
  final String connectionLabel;
  final String? errorMessage;
}
