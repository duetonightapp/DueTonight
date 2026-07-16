class RoomMember {
  final String id;
  final String roomId;
  final String userId;
  final String role;
  final DateTime joinedAt;

  const RoomMember({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
