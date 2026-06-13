class RoomAttachment {
  final String id;
  final String roomId;
  final String uploadedBy;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final String? assignmentId;
  final DateTime createdAt;

  const RoomAttachment({
    required this.id,
    required this.roomId,
    required this.uploadedBy,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
    this.assignmentId,
  });

  factory RoomAttachment.fromJson(Map<String, dynamic> json) {
    return RoomAttachment(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      assignmentId: json['assignment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'uploaded_by': uploadedBy,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'assignment_id': assignmentId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
