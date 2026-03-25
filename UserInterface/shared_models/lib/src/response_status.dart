enum ResponseStatus {
  responding('Responding'),
  pending('Pending'),
  notAvailable('Not Available');

  const ResponseStatus(this.label);

  final String label;
}
