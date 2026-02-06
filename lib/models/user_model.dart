class UserModel {
  final String id;
  final String authId;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? favoriteTeam;
  final String? favoritePlayer;
  final String? gender;
  final String? nationality;
  
  // Estadísticas
  final int points;
  final int predictions;
  final int correct;
  final int level;
  final int currentStreak;
  final int bestStreak;
  
  // Estadísticas mensuales
  final int monthlyPoints;
  final int monthlyPredictions;
  final int monthlyCorrect;
  final int monthlyChampionships;
  
  // Logros y títulos
  final List<dynamic> achievements;
  final List<dynamic> titles;
  
  // Permisos
  final bool isAdmin;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? lastMonthlyReset;

  UserModel({
    required this.id,
    required this.authId,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.favoriteTeam,
    this.favoritePlayer,
    this.gender,
    this.nationality,
    required this.points,
    required this.predictions,
    required this.correct,
    required this.level,
    required this.currentStreak,
    required this.bestStreak,
    required this.monthlyPoints,
    required this.monthlyPredictions,
    required this.monthlyCorrect,
    required this.monthlyChampionships,
    required this.achievements,
    required this.titles,
    required this.isAdmin,
    required this.createdAt,
    this.lastMonthlyReset,
  });

  // From JSON (desde Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      authId: json['auth_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      favoriteTeam: json['favorite_team'] as String?,
      favoritePlayer: json['favorite_player'] as String?,
      gender: json['gender'] as String?,
      nationality: json['nationality'] as String?,
      points: json['points'] as int? ?? 0,
      predictions: json['predictions'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      monthlyPoints: json['monthly_points'] as int? ?? 0,
      monthlyPredictions: json['monthly_predictions'] as int? ?? 0,
      monthlyCorrect: json['monthly_correct'] as int? ?? 0,
      monthlyChampionships: json['monthly_championships'] as int? ?? 0,
      achievements: json['achievements'] as List<dynamic>? ?? [],
      titles: json['titles'] as List<dynamic>? ?? [],
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastMonthlyReset: json['last_monthly_reset'] != null
          ? DateTime.parse(json['last_monthly_reset'] as String)
          : null,
    );
  }

  // To JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'favorite_team': favoriteTeam,
      'favorite_player': favoritePlayer,
      'gender': gender,
      'nationality': nationality,
      'points': points,
      'predictions': predictions,
      'correct': correct,
      'level': level,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'monthly_points': monthlyPoints,
      'monthly_predictions': monthlyPredictions,
      'monthly_correct': monthlyCorrect,
      'monthly_championships': monthlyChampionships,
      'achievements': achievements,
      'titles': titles,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
      'last_monthly_reset': lastMonthlyReset?.toIso8601String(),
    };
  }

  // CopyWith para actualizaciones inmutables
  UserModel copyWith({
    String? id,
    String? authId,
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    String? favoriteTeam,
    String? favoritePlayer,
    String? gender,
    String? nationality,
    int? points,
    int? predictions,
    int? correct,
    int? level,
    int? currentStreak,
    int? bestStreak,
    int? monthlyPoints,
    int? monthlyPredictions,
    int? monthlyCorrect,
    int? monthlyChampionships,
    List<dynamic>? achievements,
    List<dynamic>? titles,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastMonthlyReset,
  }) {
    return UserModel(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      favoriteTeam: favoriteTeam ?? this.favoriteTeam,
      favoritePlayer: favoritePlayer ?? this.favoritePlayer,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      points: points ?? this.points,
      predictions: predictions ?? this.predictions,
      correct: correct ?? this.correct,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      monthlyPoints: monthlyPoints ?? this.monthlyPoints,
      monthlyPredictions: monthlyPredictions ?? this.monthlyPredictions,
      monthlyCorrect: monthlyCorrect ?? this.monthlyCorrect,
      monthlyChampionships: monthlyChampionships ?? this.monthlyChampionships,
      achievements: achievements ?? this.achievements,
      titles: titles ?? this.titles,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      lastMonthlyReset: lastMonthlyReset ?? this.lastMonthlyReset,
    );
  }

  // Tasa de éxito como porcentaje
  double get successRate {
    if (predictions == 0) return 0.0;
    return (correct / predictions) * 100;
  }

  // Tasa de éxito mensual
  double get monthlySuccessRate {
    if (monthlyPredictions == 0) return 0.0;
    return (monthlyCorrect / monthlyPredictions) * 100;
  }
}