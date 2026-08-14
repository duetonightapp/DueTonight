class AssignmentSolution {
  final String id;
  final String roomId;
  final String assignmentId;
  final String uploadedBy;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;

  const AssignmentSolution({
    required this.id,
    required this.roomId,
    required this.assignmentId,
    required this.uploadedBy,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
  });

  factory AssignmentSolution.fromJson(Map<String, dynamic> json) {
    return AssignmentSolution(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      assignmentId: json['assignment_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'assignment_id': assignmentId,
      'uploaded_by': uploadedBy,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
