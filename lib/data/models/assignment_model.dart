class Assignment {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? subject;
  final DateTime deadline;
  final String submissionMode;
  final String priority;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Assignment({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.subject,
    required this.deadline,
    this.submissionMode = 'online',
    this.priority = 'medium',
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue {
    return !isCompleted && deadline.isBefore(DateTime.now());
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      deadline: DateTime.parse(json['deadline'] as String),
      submissionMode:
          json['submission_mode'] as String? ??
          json['submissionMode'] as String? ??
          'online',
      priority: json['priority'] as String? ?? 'medium',
      isCompleted:
          json['is_completed'] as bool? ??
          json['isCompleted'] as bool? ??
          false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'subject': subject,
      'deadline': deadline.toIso8601String(),
      'submission_mode': submissionMode,
      'priority': priority,
      'is_completed': isCompleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Assignment copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? subject,
    DateTime? deadline,
    String? submissionMode,
    String? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      deadline: deadline ?? this.deadline,
      submissionMode: submissionMode ?? this.submissionMode,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
