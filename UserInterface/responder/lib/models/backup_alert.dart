class BackupAlert {
  const BackupAlert({
    required this.incidentPublicId,
    required this.title,
    required this.body,
  });

  final String incidentPublicId;
  final String title;
  final String body;
}
