enum ResponseStatus {
  responding('Responding'),
  pending('Pending'),
  notAvailable('Not Available');

  const ResponseStatus(this.label);

  final String label;

  static ResponseStatus? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    for (final value in ResponseStatus.values) {
      if (value.label == label) {
        return value;
      }
    }
    return null;
  }
}
