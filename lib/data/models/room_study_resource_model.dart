class RoomStudyResource {
  final String id;
  final String roomId;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String uploadedBy;
  final DateTime createdAt;

  const RoomStudyResource({
    required this.id,
    required this.roomId,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory RoomStudyResource.fromJson(Map<String, dynamic> json) {
    return RoomStudyResource(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      title: json['title'] as String? ?? 'Untitled Resource',
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fileExtension {
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return '';
  }

  bool get isPdf =>
      fileExtension == 'pdf' || fileType.toLowerCase().contains('pdf');

  bool get isPpt =>
      fileExtension == 'ppt' ||
      fileExtension == 'pptx' ||
      fileType.toLowerCase().contains('powerpoint') ||
      fileType.toLowerCase().contains('presentation');

  bool get isDocx =>
      fileExtension == 'doc' ||
      fileExtension == 'docx' ||
      fileType.toLowerCase().contains('word') ||
      fileType.toLowerCase().contains('document');

  String get formattedSize {
    if (fileSize <= 0) return '0 B';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
