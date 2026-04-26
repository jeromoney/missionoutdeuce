import 'package:phone_numbers_parser/phone_numbers_parser.dart';

export 'package:phone_numbers_parser/phone_numbers_parser.dart' show IsoCode;

/// Phone validation per MissionOut data-validation spec (E.164).
/// See docs/data-validation.md. Defaults unprefixed input to US (+1) but
/// accepts international numbers when [isoCode] is supplied or the input
/// already starts with '+'.
class PhoneValidator {
  PhoneValidator._();

  static final RegExp _e164 = RegExp(r'^\+[1-9]\d{1,14}$');

  static PhoneNumber? _parse(String phone, {IsoCode? isoCode}) {
    try {
      if (phone.startsWith('+')) {
        return PhoneNumber.parse(phone);
      }
      return PhoneNumber.parse(
        phone,
        destinationCountry: isoCode ?? IsoCode.US,
      );
    } catch (_) {
      return null;
    }
  }

  static bool isValid(String phone, {IsoCode? isoCode}) {
    final parsed = _parse(phone, isoCode: isoCode);
    if (parsed == null) {
      return false;
    }
    return parsed.isValid() && _e164.hasMatch(parsed.international);
  }

  /// Returns an error message when invalid, or null when the phone is valid.
  static String? validate(String? phone, {IsoCode? isoCode}) {
    final value = phone?.trim() ?? '';
    if (value.isEmpty) {
      return 'Enter a phone number.';
    }
    if (!isValid(value, isoCode: isoCode)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  /// Returns the E.164 form of [phone] (e.g. +15551234567), or null if the
  /// input cannot be parsed. Useful for normalizing before submit.
  static String? toE164(String phone, {IsoCode? isoCode}) {
    final parsed = _parse(phone, isoCode: isoCode);
    if (parsed == null || !parsed.isValid()) {
      return null;
    }
    return parsed.international;
  }
}
