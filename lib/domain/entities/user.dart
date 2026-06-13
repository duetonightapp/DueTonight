class User {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? batchId;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.batchId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      batchId: json['batch_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'batch_id': batchId,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? batchId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      batchId: batchId ?? this.batchId,
    );
  }
}