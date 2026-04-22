/// Email validation per MissionOut data-validation spec (RFC 5322).
/// See docs/data-validation.md.
class EmailValidator {
  EmailValidator._();

  static final RegExp _regex = RegExp(
    r"""^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])$""",
    caseSensitive: false,
  );

  static bool isValid(String email) => _regex.hasMatch(email);

  /// Returns an error message when invalid, or null when the email is valid.
  static String? validate(String? email) {
    final value = email?.trim() ?? '';
    if (value.isEmpty) {
      return 'Enter an email address.';
    }
    if (!isValid(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }
}
