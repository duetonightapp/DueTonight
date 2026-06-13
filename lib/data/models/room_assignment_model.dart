class RoomAssignment {
  final String id;
  final String roomId;
  final String title;
  final String? description;
  final String? subject;
  final String? subjectId;
  final DateTime? deadline;
  final String? attachmentPath;
  final bool isPinned;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoomAssignment({
    required this.id,
    required this.roomId,
    required this.title,
    this.description,
    this.subject,
    this.subjectId,
    this.deadline,
    this.attachmentPath,
    required this.isPinned,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomAssignment.fromJson(Map<String, dynamic> json) {
    return RoomAssignment(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      subjectId: json['subject_id'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
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
      'description': description,
      'subject': subject,
      'subject_id': subjectId,
      'deadline': deadline?.toIso8601String(),
      'attachment_path': attachmentPath,
      'is_pinned': isPinned,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
