import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('EmailValidator.isValid', () {
    final validEmails = <String>[
      'user@example.com',
      'firstname.lastname@example.com',
      'user+tag@example.com',
      'user@mail.sub.example.com',
      'user123@example123.com',
      'USER@EXAMPLE.COM',
      'a@b.co',
      "!#\$%&'*+/=?^_`{|}~-@example.com",
      '"hello.world"@example.com',
      'user@my-domain.com',
      'user@[192.168.1.1]',
    ];

    for (final email in validEmails) {
      test('accepts "$email"', () {
        expect(EmailValidator.isValid(email), isTrue);
      });
    }

    final invalidEmails = <String>[
      '',
      'plainaddress',
      '@no-local.org',
      'no-at-sign.com',
      'user@',
      'user@@double.com',
      'user name@example.com',
      'user@exa mple.com',
      'user@-leadinghyphen.com',
      'user@trailinghyphen-.com',
      'user@example.',
      'user@.example.com',
    ];

    for (final email in invalidEmails) {
      test('rejects "$email"', () {
        expect(EmailValidator.isValid(email), isFalse);
      });
    }
  });

  group('EmailValidator.validate', () {
    test('returns prompt for null', () {
      expect(EmailValidator.validate(null), 'Enter an email address.');
    });

    test('returns prompt for empty string', () {
      expect(EmailValidator.validate(''), 'Enter an email address.');
    });

    test('returns prompt for whitespace-only string', () {
      expect(EmailValidator.validate('   '), 'Enter an email address.');
    });

    test('trims surrounding whitespace before validating', () {
      expect(EmailValidator.validate('  user@example.com  '), isNull);
    });

    test('returns null for a valid email', () {
      expect(EmailValidator.validate('user@example.com'), isNull);
    });

    test('returns invalid message for malformed input', () {
      expect(EmailValidator.validate('not an email'), 'Enter a valid email address.');
    });
  });
}
