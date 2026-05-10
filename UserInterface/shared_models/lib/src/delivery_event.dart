class DeliveryEvent {
  const DeliveryEvent({
    required this.title,
    required this.detail,
    required this.time,
    this.iconKey,
    this.colorHex,
  });

  final String title;
  final String detail;
  final DateTime? time;
  final String? iconKey;
  final String? colorHex;

  factory DeliveryEvent.fromJson(Map<String, dynamic> json) {
    return DeliveryEvent(
      title: json['title'] as String? ?? 'Event',
      detail: json['detail'] as String? ?? '',
      time: DateTime.tryParse(json['time'] as String? ?? ''),
      iconKey: json['icon'] as String?,
      colorHex: json['color'] as String?,
    );
  }
}
