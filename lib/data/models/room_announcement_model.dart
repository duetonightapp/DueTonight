class RoomAnnouncement {
  final String id;
  final String roomId;
  final String title;
  final String body;
  final String? attachmentPath;
  final bool isPinned;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoomAnnouncement({
    required this.id,
    required this.roomId,
    required this.title,
    required this.body,
    this.attachmentPath,
    required this.isPinned,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomAnnouncement.fromJson(Map<String, dynamic> json) {
    return RoomAnnouncement(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      attachmentPath: json['attachment_path'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'title': title,
      'body': body,
      'attachment_path': attachmentPath,
      'is_pinned': isPinned,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
