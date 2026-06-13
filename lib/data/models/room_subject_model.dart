class RoomSubject {
  final String id;
  final String roomId;
  final String name;
  final DateTime createdAt;

  const RoomSubject({
    required this.id,
    required this.roomId,
    required this.name,
    required this.createdAt,
  });

  factory RoomSubject.fromJson(Map<String, dynamic> json) {
    return RoomSubject(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
