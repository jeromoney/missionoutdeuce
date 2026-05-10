/// Validation outcome for a name. `null` from [NameValidator.validate]
/// means the input is valid.
enum NameValidationError { empty, invalid }

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

  /// Returns a [NameValidationError] when invalid, or null when valid.
  static NameValidationError? validate(String? name) {
    final value = name?.trim() ?? '';
    if (value.isEmpty) {
      return NameValidationError.empty;
    }
    if (!isValid(value)) {
      return NameValidationError.invalid;
    }
    return null;
  }
}
