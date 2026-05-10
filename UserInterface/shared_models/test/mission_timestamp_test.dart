import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('formatMissionAbsoluteDate', () {
    final now = DateTime(2026, 3, 29, 23, 23);

    test('formats same-year dates as month and day', () {
      expect(
        formatMissionAbsoluteDate(
          DateTime.utc(2026, 3, 10, 9, 30),
          now: now.toUtc(),
        ),
        'March 10',
      );
    });

    test('formats prior-year dates with month day and year', () {
      expect(
        formatMissionAbsoluteDate(
          DateTime.utc(2025, 11, 3, 18, 20),
          now: now.toUtc(),
        ),
        'November 3, 2025',
      );
    });

    test('returns fallback for null', () {
      expect(
        formatMissionAbsoluteDate(null, now: now, fallback: 'Unknown'),
        'Unknown',
      );
    });

    test('returns fallback when the timestamp is in the future', () {
      expect(
        formatMissionAbsoluteDate(
          DateTime.utc(2026, 3, 30),
          now: DateTime.utc(2026, 3, 29, 23, 23),
          fallback: 'Unknown',
        ),
        'Unknown',
      );
    });
  });
}
