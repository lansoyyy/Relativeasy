import 'dart:math' as math;
import '../models/leaderboard.dart';
import '../models/user_progress.dart';

class LeaderboardService {
  static LeaderboardService? _instance;
  static LeaderboardService get instance =>
      _instance ??= LeaderboardService._();

  LeaderboardService._();

  // Generate mock leaderboard data for demonstration
  List<LeaderboardEntry> _generateMockLeaderboard({bool isWeekly = false}) {
    final List<Map<String, dynamic>> mockUsers = [
      {
        'username': 'EinsteinFan',
        'totalXP': isWeekly ? 350 : 8420,
        'weeklyXP': 350,
        'accuracy': 96.5,
        'streak': 18,
        'badges': 9,
      },
      {
        'username': 'PhysicsWhiz',
        'totalXP': isWeekly ? 320 : 7890,
        'weeklyXP': 320,
        'accuracy': 93.2,
        'streak': 15,
        'badges': 8,
      },
      {
        'username': 'RelativityMaster',
        'totalXP': isWeekly ? 285 : 7350,
        'weeklyXP': 285,
        'accuracy': 89.7,
        'streak': 12,
        'badges': 7,
      },
      {
        'username': 'QuantumQueen',
        'totalXP': isWeekly ? 275 : 6820,
        'weeklyXP': 275,
        'accuracy': 94.1,
        'streak': 20,
        'badges': 8,
      },
      {
        'username': 'SpaceTimeStudent',
        'totalXP': isWeekly ? 260 : 6450,
        'weeklyXP': 260,
        'accuracy': 87.3,
        'streak': 8,
        'badges': 6,
      },
    ];

    return mockUsers.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> user = entry.value;

      return LeaderboardEntry(
        userId: 'user_${index + 1}',
        username: user['username'],
        totalXP: user['totalXP'],
        weeklyXP: user['weeklyXP'],
        rank: index + 1,
        weeklyRank: index + 1,
        averageAccuracy: user['accuracy'] / 100,
        dailyStreak: user['streak'],
        badgesEarned: user['badges'],
        lastActive: DateTime.now().subtract(Duration(hours: index + 1)),
      );
    }).toList();
  }

  // Add current user to leaderboard
  LeaderboardEntry _createCurrentUserEntry(
      UserProgress userProgress, int unlockedBadges) {
    return LeaderboardEntry(
      userId: userProgress.userId,
      username: 'You',
      totalXP: userProgress.totalXP,
      weeklyXP: _calculateWeeklyXP(userProgress),
      rank: 0, // Will be calculated
      weeklyRank: 0, // Will be calculated
      averageAccuracy: userProgress.averageAccuracy,
      dailyStreak: userProgress.dailyStreak,
      badgesEarned: unlockedBadges,
      lastActive: DateTime.now(),
    );
  }

  int _calculateWeeklyXP(UserProgress userProgress) {
    // Estimate weekly XP based on recent activity
    DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
    if (userProgress.lastUpdated.isAfter(weekAgo)) {
      return math.min(userProgress.totalXP ~/ 4, 300);
    }
    return 0;
  }

  // Get leaderboard with current user included
  Future<Leaderboard> getLeaderboard(
      UserProgress? userProgress, int unlockedBadges) async {
    List<LeaderboardEntry> allTimeEntries =
        _generateMockLeaderboard(isWeekly: false);
    List<LeaderboardEntry> weeklyEntries =
        _generateMockLeaderboard(isWeekly: true);

    // Add current user if available
    if (userProgress != null) {
      LeaderboardEntry currentUser =
          _createCurrentUserEntry(userProgress, unlockedBadges);

      // Calculate user's rank
      int allTimeRank = _calculateUserRank(allTimeEntries, currentUser.totalXP);
      int weeklyRank = _calculateUserRank(weeklyEntries, currentUser.weeklyXP);

      currentUser = LeaderboardEntry(
        userId: currentUser.userId,
        username: currentUser.username,
        totalXP: currentUser.totalXP,
        weeklyXP: currentUser.weeklyXP,
        rank: allTimeRank,
        weeklyRank: weeklyRank,
        averageAccuracy: currentUser.averageAccuracy,
        dailyStreak: currentUser.dailyStreak,
        badgesEarned: currentUser.badgesEarned,
        lastActive: currentUser.lastActive,
      );

      // Add user to appropriate position
      if (allTimeRank <= 20) {
        allTimeEntries.insert(allTimeRank - 1, currentUser);
      } else {
        allTimeEntries.add(currentUser);
      }

      if (weeklyRank <= 20) {
        weeklyEntries.insert(weeklyRank - 1, currentUser);
      } else {
        weeklyEntries.add(currentUser);
      }
    }

    return Leaderboard(
      allTimeLeaders: allTimeEntries.take(25).toList(),
      weeklyLeaders: weeklyEntries.take(25).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  int _calculateUserRank(List<LeaderboardEntry> entries, int userXP) {
    int rank = 1;
    for (final entry in entries) {
      if (userXP > entry.totalXP) {
        break;
      }
      rank++;
    }
    return rank;
  }

  // Get competitive insights
  Map<String, dynamic> getCompetitiveInsights(
      UserProgress userProgress, Leaderboard leaderboard) {
    LeaderboardEntry? currentUser = leaderboard.allTimeLeaders
        .where((entry) => entry.username == 'You')
        .firstOrNull;

    if (currentUser == null) {
      return {
        'currentRank': 999,
        'weeklyRank': 999,
        'xpToNextRank': 100,
        'weeklyPosition': 'Keep going!',
      };
    }

    // Calculate XP needed to advance
    int xpToNextRank = 0;
    if (currentUser.rank > 1) {
      LeaderboardEntry nextUser = leaderboard.allTimeLeaders
          .firstWhere((entry) => entry.rank == currentUser.rank - 1);
      xpToNextRank = nextUser.totalXP - currentUser.totalXP + 1;
    }

    return {
      'currentRank': currentUser.rank,
      'weeklyRank': currentUser.weeklyRank,
      'xpToNextRank': xpToNextRank,
      'weeklyPosition': _getWeeklyPosition(currentUser),
    };
  }

  String _getWeeklyPosition(LeaderboardEntry user) {
    if (user.weeklyRank == 1) return 'Weekly Champion! 🏆';
    if (user.weeklyRank <= 3) return 'Top 3 This Week! 🥉';
    if (user.weeklyRank <= 10) return 'Top 10 This Week! ⭐';
    if (user.weeklyRank <= 25) return 'Top 25 This Week! 📈';
    return 'Keep climbing! 💪';
  }
}
