const _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatMissionTimestamp(
  DateTime? value, {
  DateTime? now,
  String fallback = 'Unknown',
}) {
  if (value == null) {
    return fallback;
  }

  final effectiveNow = (now ?? DateTime.now()).toLocal();
  final localValue = value.toLocal();
  final difference = effectiveNow.difference(localValue);

  if (difference.isNegative) {
    return fallback;
  }

  if (difference < const Duration(days: 7)) {
    return _formatRecentDuration(difference);
  }

  if (localValue.year == effectiveNow.year) {
    return '${_monthNames[localValue.month - 1]} ${localValue.day}';
  }

  return '${_monthNames[localValue.month - 1]} ${localValue.day}, ${localValue.year}';
}

String _formatRecentDuration(Duration duration) {
  if (duration.inMinutes < 1) {
    return 'Just now';
  }
  if (duration.inHours < 1) {
    final minutes = duration.inMinutes;
    return '$minutes ${minutes == 1 ? 'minute ago' : 'minutes ago'}';
  }
  if (duration.inDays < 1) {
    final hours = duration.inHours;
    return '$hours ${hours == 1 ? 'hour ago' : 'hours ago'}';
  }
  final days = duration.inDays;
  return '$days ${days == 1 ? 'day ago' : 'days ago'}';
}
