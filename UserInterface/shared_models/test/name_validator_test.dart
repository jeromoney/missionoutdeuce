import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('NameValidator.isValid', () {
    final validNames = <String>[
      'John',
      'John Doe',
      'Mary Jane Watson',
      "O'Brien",
      'Mary-Jane',
      'Dr.Smith',
      'Jean-Paul Sartre',
      'José',
      'Müller',
      'François',
      "Renée O'Connor",
      '李',
      '山田 太郎',
      'Николай',
    ];

    for (final name in validNames) {
      test('accepts "$name"', () {
        expect(NameValidator.isValid(name), isTrue);
      });
    }

    final invalidNames = <String>[
      '',
      'John123',
      'John!',
      'John@Doe',
      'John😀',
      '-John',
      'John-',
      '.John',
      'John ',
      'John  Doe',
      'John--Doe',
      'Dr. Smith',
      'John_Doe',
      '123',
    ];

    for (final name in invalidNames) {
      test('rejects "$name"', () {
        expect(NameValidator.isValid(name), isFalse);
      });
    }
  });

  group('NameValidator.validate', () {
    test('returns prompt for null', () {
      expect(NameValidator.validate(null), 'Enter a name.');
    });

    test('returns prompt for empty string', () {
      expect(NameValidator.validate(''), 'Enter a name.');
    });

    test('returns prompt for whitespace-only string', () {
      expect(NameValidator.validate('   '), 'Enter a name.');
    });

    test('trims surrounding whitespace before validating', () {
      expect(NameValidator.validate('  John Doe  '), isNull);
    });

    test('returns null for a valid name', () {
      expect(NameValidator.validate('John Doe'), isNull);
    });

    test('returns invalid message for digits', () {
      expect(NameValidator.validate('John123'), 'Enter a valid name.');
    });
  });
}
