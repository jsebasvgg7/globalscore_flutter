class UserModel {
  final String id;
  final String authId;
  final String username;
  final String email;
  final String? avatarUrl;
  final int points;
  final int level;
  final int currentStreak;
  final int bestStreak;
  final bool isAdmin;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.authId,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.points,
    required this.level,
    required this.currentStreak,
    required this.bestStreak,
    required this.isAdmin,
    required this.createdAt,
  });

  // From JSON (desde Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      authId: json['auth_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: json['points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // To JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'points': points,
      'level': level,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // CopyWith para actualizaciones inmutables
  UserModel copyWith({
    String? id,
    String? authId,
    String? username,
    String? email,
    String? avatarUrl,
    int? points,
    int? level,
    int? currentStreak,
    int? bestStreak,
    bool? isAdmin,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this
          .points,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}