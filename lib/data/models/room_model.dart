class Room {
  final String id;
  final String roomCode;
  final String collegeName;
  final String branch;
  final String semester;
  final String division;
  final String ownerId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Room({
    required this.id,
    required this.roomCode,
    required this.collegeName,
    required this.branch,
    required this.semester,
    required this.division,
    required this.ownerId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      roomCode: json['room_code'] as String,
      collegeName: json['college_name'] as String,
      branch: json['branch'] as String,
      semester: json['semester'] as String,
      division: json['division'] as String,
      ownerId: json['owner_id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_code': roomCode,
      'college_name': collegeName,
      'branch': branch,
      'semester': semester,
      'division': division,
      'owner_id': ownerId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
