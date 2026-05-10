import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('formatMissionTimestamp', () {
    final now = DateTime(2026, 3, 29, 23, 23);

    test('formats recent timestamps within the week as relative time', () {
      expect(
        formatMissionTimestamp(
          DateTime.utc(2026, 3, 29, 22, 56),
          now: DateTime.utc(2026, 3, 29, 23),
        ),
        '4 minutes ago',
      );
    });

    test('formats same-year dates beyond a week as month and day', () {
      expect(
        formatMissionTimestamp(
          DateTime.utc(2026, 3, 10, 9, 30),
          now: now.toUtc(),
        ),
        'March 10',
      );
    });

    test('formats prior-year dates with month day and year', () {
      expect(
        formatMissionTimestamp(
          DateTime.utc(2025, 11, 3, 18, 20),
          now: now.toUtc(),
        ),
        'November 3, 2025',
      );
    });

    test('returns fallback for null', () {
      expect(
        formatMissionTimestamp(null, now: now, fallback: 'Unknown'),
        'Unknown',
      );
    });

    test('returns fallback when the timestamp is in the future', () {
      expect(
        formatMissionTimestamp(
          DateTime.utc(2026, 3, 30),
          now: DateTime.utc(2026, 3, 29, 23, 23),
          fallback: 'Unknown',
        ),
        'Unknown',
      );
    });
  });
}
