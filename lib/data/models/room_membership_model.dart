import 'room_model.dart';

class RoomMembership {
  final Room room;
  final String role;

  const RoomMembership({required this.room, required this.role});

  factory RoomMembership.fromJson(Map<String, dynamic> json) {
    return RoomMembership(
      room: Room.fromJson(json),
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {...room.toJson(), 'role': role};
  }
}
