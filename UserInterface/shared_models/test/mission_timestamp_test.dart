import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('formatMissionTimestamp', () {
    final now = DateTime(2026, 3, 29, 23, 23);

    test('formats recent ISO timestamps within the week as relative time', () {
      expect(
        formatMissionTimestamp(
          '2026-03-29T22:56:00Z',
          now: DateTime.utc(2026, 3, 29, 23),
        ),
        '4 minutes',
      );
    });

    test('formats same-year dates beyond a week as month and day', () {
      expect(
        formatMissionTimestamp('2026-03-10T09:30:00Z', now: now.toUtc()),
        'March 10',
      );
    });

    test('formats prior-year dates with month day and year', () {
      expect(
        formatMissionTimestamp('2025-11-03T18:20:00Z', now: now.toUtc()),
        'November 3, 2025',
      );
    });

    test('returns fallback for blank strings', () {
      expect(
        formatMissionTimestamp('', now: now, fallback: 'Unknown'),
        'Unknown',
      );
    });

    test('returns the raw value when the input is not ISO', () {
      expect(formatMissionTimestamp('March 29', now: now), 'March 29');
    });

    test('returns error when the ISO timestamp is in the future', () {
      expect(
        formatMissionTimestamp(
          '2026-03-30T00:00:00Z',
          now: DateTime.utc(2026, 3, 29, 23, 23),
        ),
        'error',
      );
    });
  });
}
