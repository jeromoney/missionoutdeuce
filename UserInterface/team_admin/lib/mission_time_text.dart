import 'package:flutter/widgets.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timeago/timeago.dart' as timeago;

String formatMissionTime(
  DateTime? dt,
  BuildContext context, {
  String fallback = 'Unknown',
}) {
  if (dt == null) return fallback;
  final local = dt.toLocal();
  final age = DateTime.now().difference(local);
  if (age.isNegative) return fallback;
  if (age < const Duration(days: 7)) {
    return timeago.format(
      local,
      locale: Localizations.localeOf(context).languageCode,
    );
  }
  return formatMissionAbsoluteDate(local);
}

String formatMissionTimeNoContext(DateTime? dt, {String fallback = 'Unknown'}) {
  if (dt == null) return fallback;
  final local = dt.toLocal();
  final age = DateTime.now().difference(local);
  if (age.isNegative) return fallback;
  if (age < const Duration(days: 7)) return timeago.format(local);
  return formatMissionAbsoluteDate(local);
}
