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
  String inputDate, {
  DateTime? now,
  String fallback = 'Unknown',
}) {
  try {
    final value = inputDate.trim();
    if (value.isEmpty) {
      return fallback;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    final effectiveNow = (now ?? DateTime.now()).toLocal();
    final localParsed = parsed.toLocal();
    final difference = effectiveNow.difference(localParsed);

    if (difference.isNegative) {
      throw FormatException('Mission timestamp cannot be in the future.', value);
    }

    if (difference < const Duration(days: 7)) {
      return _formatRecentDuration(difference);
    }

    if (localParsed.year == effectiveNow.year) {
      return '${_monthNames[localParsed.month - 1]} ${localParsed.day}';
    }

    return '${_monthNames[localParsed.month - 1]} ${localParsed.day}, ${localParsed.year}';
  } on FormatException {
    return 'error';
  }
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
