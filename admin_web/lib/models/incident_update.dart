class IncidentUpdate {
  const IncidentUpdate({
    required this.title,
    required this.location,
    required this.notes,
    required this.active,
  });

  final String title;
  final String location;
  final String notes;
  final bool active;
}
