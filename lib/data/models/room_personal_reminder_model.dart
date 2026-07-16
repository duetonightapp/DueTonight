class RoomPersonalReminder {
  final String id;
  final String roomId;
  final String userId;
  final String title;
  final String? body;
  final DateTime date;
  final DateTime createdAt;

  const RoomPersonalReminder({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.title,
    this.body,
    required this.date,
    required this.createdAt,
  });

  factory RoomPersonalReminder.fromJson(Map<String, dynamic> json) {
    return RoomPersonalReminder(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'title': title,
      'body': body,
      'date': date.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
