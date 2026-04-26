import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('PhoneValidator.isValid', () {
    final validPhones = <String>[
      '+12024561414',
      '+14089961010',
      '+16502530000',
      '+18002752273',
      '(202) 456-1414',
      '202-456-1414',
      '202.456.1414',
      '202 456 1414',
      '2024561414',
      '+1 202 456 1414',
      '+442079460000',
      '+33140205050',
      '+81335811111',
    ];

    for (final phone in validPhones) {
      test('accepts "$phone"', () {
        expect(PhoneValidator.isValid(phone), isTrue);
      });
    }

    test('accepts a national number when isoCode is provided', () {
      expect(PhoneValidator.isValid('2079460000', isoCode: IsoCode.GB), isTrue);
    });

    final invalidPhones = <String>[
      '',
      '   ',
      'abcdefghij',
      '12345',
      '+',
      '0000000000',
      '4554554544',
      '+1234',
      '+99999999999999999',
      'not a number',
    ];

    for (final phone in invalidPhones) {
      test('rejects "$phone"', () {
        expect(PhoneValidator.isValid(phone), isFalse);
      });
    }
  });

  group('PhoneValidator.validate', () {
    test('returns prompt for null', () {
      expect(PhoneValidator.validate(null), 'Enter a phone number.');
    });

    test('returns prompt for empty string', () {
      expect(PhoneValidator.validate(''), 'Enter a phone number.');
    });

    test('returns prompt for whitespace-only string', () {
      expect(PhoneValidator.validate('   '), 'Enter a phone number.');
    });

    test('trims surrounding whitespace before validating', () {
      expect(PhoneValidator.validate('  +12024561414  '), isNull);
    });

    test('returns null for a valid phone', () {
      expect(PhoneValidator.validate('+12024561414'), isNull);
    });

    test('returns invalid message for unassigned NANP area code', () {
      expect(PhoneValidator.validate('4554554544'), 'Enter a valid phone number.');
    });
  });

  group('PhoneValidator.toE164', () {
    test('normalizes US formatted input to E.164', () {
      expect(PhoneValidator.toE164('(202) 456-1414'), '+12024561414');
    });

    test('normalizes hyphenated US input to E.164', () {
      expect(PhoneValidator.toE164('202-456-1414'), '+12024561414');
    });

    test('returns E.164 form unchanged for already-normalized US input', () {
      expect(PhoneValidator.toE164('+14089961010'), '+14089961010');
    });

    test('preserves international E.164 input', () {
      expect(PhoneValidator.toE164('+442079460000'), '+442079460000');
    });

    test('normalizes a national number when isoCode is provided', () {
      expect(
        PhoneValidator.toE164('2079460000', isoCode: IsoCode.GB),
        '+442079460000',
      );
    });

    test('returns null for an invalid number', () {
      expect(PhoneValidator.toE164('4554554544'), isNull);
    });

    test('returns null for unparseable garbage', () {
      expect(PhoneValidator.toE164('garbage'), isNull);
    });

    test('returns null for an empty string', () {
      expect(PhoneValidator.toE164(''), isNull);
    });
  });
}
