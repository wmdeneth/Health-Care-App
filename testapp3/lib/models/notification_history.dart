class NotificationHistory {
  final String id;
  final DateTime notificationTime;
  final String title;
  final String message;
  final bool drank;
  final DateTime? drankTime;
  final int incrementMl;

  NotificationHistory({
    required this.id,
    required this.notificationTime,
    required this.title,
    required this.message,
    required this.drank,
    this.drankTime,
    required this.incrementMl,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'] ?? '',
      notificationTime:
          json['notificationTime'] != null
              ? DateTime.parse(json['notificationTime'])
              : DateTime.now(),
      title: json['title'] ?? 'Water Reminder',
      message: json['message'] ?? 'Drink water',
      drank: json['drank'] ?? false,
      drankTime:
          json['drankTime'] != null ? DateTime.parse(json['drankTime']) : null,
      incrementMl: json['incrementMl'] ?? 250,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notificationTime': notificationTime.toIso8601String(),
      'title': title,
      'message': message,
      'drank': drank,
      'drankTime': drankTime?.toIso8601String(),
      'incrementMl': incrementMl,
    };
  }
}
