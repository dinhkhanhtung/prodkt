class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String date;
  final String type;
  final bool isRead;

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
  });

  // Create a Notification from a Map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      date: map['date'],
      type: map['type'],
      isRead: map['is_read'] == 1,
    );
  }

  // Convert a Notification to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date,
      'type': type,
      'is_read': isRead ? 1 : 0,
    };
  }

  // Create a copy of Notification with some fields changed
  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? date,
    String? type,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'Notification{id: $id, title: $title, date: $date, isRead: $isRead}';
  }
}
