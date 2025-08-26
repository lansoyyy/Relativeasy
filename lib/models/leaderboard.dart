class LeaderboardEntry {
  final String userId;
  final String username;
  final int totalXP;
  final int weeklyXP;
  final int rank;
  final int weeklyRank;
  final double averageAccuracy;
  final int dailyStreak;
  final int badgesEarned;
  final DateTime lastActive;
  final String? avatarUrl;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalXP,
    required this.weeklyXP,
    required this.rank,
    required this.weeklyRank,
    required this.averageAccuracy,
    required this.dailyStreak,
    required this.badgesEarned,
    required this.lastActive,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'],
      username: json['username'],
      totalXP: json['totalXP'],
      weeklyXP: json['weeklyXP'],
      rank: json['rank'],
      weeklyRank: json['weeklyRank'],
      averageAccuracy: json['averageAccuracy'].toDouble(),
      dailyStreak: json['dailyStreak'],
      badgesEarned: json['badgesEarned'],
      lastActive: DateTime.parse(json['lastActive']),
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'totalXP': totalXP,
      'weeklyXP': weeklyXP,
      'rank': rank,
      'weeklyRank': weeklyRank,
      'averageAccuracy': averageAccuracy,
      'dailyStreak': dailyStreak,
      'badgesEarned': badgesEarned,
      'lastActive': lastActive.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }
}

class Leaderboard {
  final List<LeaderboardEntry> allTimeLeaders;
  final List<LeaderboardEntry> weeklyLeaders;
  final DateTime lastUpdated;

  Leaderboard({
    required this.allTimeLeaders,
    required this.weeklyLeaders,
    required this.lastUpdated,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      allTimeLeaders: (json['allTimeLeaders'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      weeklyLeaders: (json['weeklyLeaders'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allTimeLeaders': allTimeLeaders.map((e) => e.toJson()).toList(),
      'weeklyLeaders': weeklyLeaders.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
