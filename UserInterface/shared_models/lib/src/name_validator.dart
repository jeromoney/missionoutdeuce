/// Name validation per MissionOut data-validation spec.
/// See docs/data-validation.md. Intent is to catch garbage, not define
/// what a name is.
class NameValidator {
  NameValidator._();

  static final RegExp _regex = RegExp(
    r"^[\p{L}]+([ '\-\.][\p{L}]+)*$",
    unicode: true,
  );

  static bool isValid(String name) => _regex.hasMatch(name);

  /// Returns an error message when invalid, or null when the name is valid.
  static String? validate(String? name) {
    final value = name?.trim() ?? '';
    if (value.isEmpty) {
      return 'Enter a name.';
    }
    if (!isValid(value)) {
      return 'Enter a valid name.';
    }
    return null;
  }
}
