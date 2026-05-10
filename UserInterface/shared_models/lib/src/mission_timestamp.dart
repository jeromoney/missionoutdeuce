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

/// Renders [value] as an absolute calendar date in English, e.g. "March 10"
/// for same-year and "November 3, 2025" otherwise. Returns [fallback] when
/// [value] is null or in the future.
///
/// Recent / relative-time rendering ("3 minutes ago") lives at call sites,
/// which use the `timeago` package directly so they can pass a locale.
String formatMissionAbsoluteDate(
  DateTime? value, {
  DateTime? now,
  String fallback = 'Unknown',
}) {
  if (value == null) {
    return fallback;
  }

  final effectiveNow = (now ?? DateTime.now()).toLocal();
  final localValue = value.toLocal();

  if (effectiveNow.difference(localValue).isNegative) {
    return fallback;
  }

  if (localValue.year == effectiveNow.year) {
    return '${_monthNames[localValue.month - 1]} ${localValue.day}';
  }

  return '${_monthNames[localValue.month - 1]} ${localValue.day}, ${localValue.year}';
}
