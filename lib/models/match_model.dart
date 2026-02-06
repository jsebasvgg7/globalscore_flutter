class MatchModel {
  final String id;
  final String league;
  final String? leagueLogoUrl;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final String? homeTeamLogoUrl;
  final String? awayTeamLogoUrl;
  final String date;
  final String time;
  final String? deadline;
  final String status;
  final bool isKnockout;
  final int? resultHome;
  final int? resultAway;
  final String? advancingTeam;

  MatchModel({
    required this.id,
    required this.league,
    this.leagueLogoUrl,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeTeamLogoUrl,
    this.awayTeamLogoUrl,
    required this.date,
    required this.time,
    this.deadline,
    required this.status,
    this.isKnockout = false,
    this.resultHome,
    this.resultAway,
    this.advancingTeam,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      league: json['league'] as String? ?? '',
      leagueLogoUrl: json['league_logo_url'] as String?,
      homeTeam: json['home_team'] as String? ?? '',
      awayTeam: json['away_team'] as String? ?? '',
      homeTeamLogo: json['home_team_logo'] as String?,
      awayTeamLogo: json['away_team_logo'] as String?,
      homeTeamLogoUrl: json['home_team_logo_url'] as String?,
      awayTeamLogoUrl: json['away_team_logo_url'] as String?,
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      deadline: json['deadline'] as String?,
      status: json['status'] as String? ?? 'pending',
      isKnockout: json['is_knockout'] as bool? ?? false,
      resultHome: json['result_home'] as int?,
      resultAway: json['result_away'] as int?,
      advancingTeam: json['advancing_team'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league': league,
      'league_logo_url': leagueLogoUrl,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'home_team_logo': homeTeamLogo,
      'away_team_logo': awayTeamLogo,
      'home_team_logo_url': homeTeamLogoUrl,
      'away_team_logo_url': awayTeamLogoUrl,
      'date': date,
      'time': time,
      'deadline': deadline,
      'status': status,
      'is_knockout': isKnockout,
      'result_home': resultHome,
      'result_away': resultAway,
      'advancing_team': advancingTeam,
    };
  }
}

class PredictionModel {
  final String? id;
  final String matchId;
  final String userId;
  final int homeScore;
  final int awayScore;
  final String? predictedAdvancingTeam;
  final int? pointsEarned;
  final int? advancingPoints;

  PredictionModel({
    this.id,
    required this.matchId,
    required this.userId,
    required this.homeScore,
    required this.awayScore,
    this.predictedAdvancingTeam,
    this.pointsEarned,
    this.advancingPoints,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'] as String?,
      matchId: json['match_id'] as String,
      userId: json['user_id'] as String,
      homeScore: json['home_score'] as int,
      awayScore: json['away_score'] as int,
      predictedAdvancingTeam: json['predicted_advancing_team'] as String?,
      pointsEarned: json['points_earned'] as int?,
      advancingPoints: json['advancing_points'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'match_id': matchId,
      'user_id': userId,
      'home_score': homeScore,
      'away_score': awayScore,
      if (predictedAdvancingTeam != null)
        'predicted_advancing_team': predictedAdvancingTeam,
      if (pointsEarned != null) 'points_earned': pointsEarned,
      if (advancingPoints != null) 'advancing_points': advancingPoints,
    };
  }
}