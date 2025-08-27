import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard.dart';
import '../models/user_progress.dart';

class LeaderboardService {
  static LeaderboardService? _instance;
  static LeaderboardService get instance =>
      _instance ??= LeaderboardService._();

  LeaderboardService._();

  // Main method to get leaderboard with real Firebase data
  Future<Leaderboard> getLeaderboard(
      UserProgress userProgress, int unlockedBadges) async {
    try {
      // Fetch real data from Firebase
      final allTimeLeaders = await _fetchLeaderboardData(isWeekly: false);
      final weeklyLeaders = await _fetchLeaderboardData(isWeekly: true);

      // Add current user to the leaderboard
      final currentUserEntry =
          _createCurrentUserEntry(userProgress, unlockedBadges);

      // Add current user to both leaderboards if not already present
      bool userInAllTime = allTimeLeaders
          .any((entry) => entry.userId == currentUserEntry.userId);
      bool userInWeekly =
          weeklyLeaders.any((entry) => entry.userId == currentUserEntry.userId);

      final List<LeaderboardEntry> finalAllTimeLeaders =
          List.from(allTimeLeaders);
      final List<LeaderboardEntry> finalWeeklyLeaders =
          List.from(weeklyLeaders);

      if (!userInAllTime) {
        finalAllTimeLeaders.add(currentUserEntry);
        // Re-sort and re-rank
        finalAllTimeLeaders.sort((a, b) => b.totalXP.compareTo(a.totalXP));
        for (int i = 0; i < finalAllTimeLeaders.length; i++) {
          finalAllTimeLeaders[i] = LeaderboardEntry(
            userId: finalAllTimeLeaders[i].userId,
            username: finalAllTimeLeaders[i].username,
            totalXP: finalAllTimeLeaders[i].totalXP,
            weeklyXP: finalAllTimeLeaders[i].weeklyXP,
            rank: i + 1,
            weeklyRank: finalAllTimeLeaders[i].weeklyRank,
            averageAccuracy: finalAllTimeLeaders[i].averageAccuracy,
            dailyStreak: finalAllTimeLeaders[i].dailyStreak,
            badgesEarned: finalAllTimeLeaders[i].badgesEarned,
            lastActive: finalAllTimeLeaders[i].lastActive,
          );
        }
      }

      if (!userInWeekly) {
        finalWeeklyLeaders.add(currentUserEntry);
        // Re-sort and re-rank
        finalWeeklyLeaders.sort((a, b) => b.weeklyXP.compareTo(a.weeklyXP));
        for (int i = 0; i < finalWeeklyLeaders.length; i++) {
          finalWeeklyLeaders[i] = LeaderboardEntry(
            userId: finalWeeklyLeaders[i].userId,
            username: finalWeeklyLeaders[i].username,
            totalXP: finalWeeklyLeaders[i].totalXP,
            weeklyXP: finalWeeklyLeaders[i].weeklyXP,
            rank: finalWeeklyLeaders[i].rank,
            weeklyRank: i + 1,
            averageAccuracy: finalWeeklyLeaders[i].averageAccuracy,
            dailyStreak: finalWeeklyLeaders[i].dailyStreak,
            badgesEarned: finalWeeklyLeaders[i].badgesEarned,
            lastActive: finalWeeklyLeaders[i].lastActive,
          );
        }
      }

      return Leaderboard(
        allTimeLeaders: finalAllTimeLeaders,
        weeklyLeaders: finalWeeklyLeaders,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      // If Firebase fails, generate mock data as fallback
      final mockAllTime = _generateMockLeaderboard(isWeekly: false);
      final mockWeekly = _generateMockLeaderboard(isWeekly: true);

      // Add current user to mock data
      final currentUserEntry =
          _createCurrentUserEntry(userProgress, unlockedBadges);
      mockAllTime.add(currentUserEntry);
      mockWeekly.add(currentUserEntry);

      // Sort and rank mock data
      mockAllTime.sort((a, b) => b.totalXP.compareTo(a.totalXP));
      mockWeekly.sort((a, b) => b.weeklyXP.compareTo(a.weeklyXP));

      for (int i = 0; i < mockAllTime.length; i++) {
        mockAllTime[i] = LeaderboardEntry(
          userId: mockAllTime[i].userId,
          username: mockAllTime[i].username,
          totalXP: mockAllTime[i].totalXP,
          weeklyXP: mockAllTime[i].weeklyXP,
          rank: i + 1,
          weeklyRank: mockAllTime[i].weeklyRank,
          averageAccuracy: mockAllTime[i].averageAccuracy,
          dailyStreak: mockAllTime[i].dailyStreak,
          badgesEarned: mockAllTime[i].badgesEarned,
          lastActive: mockAllTime[i].lastActive,
        );
      }

      for (int i = 0; i < mockWeekly.length; i++) {
        mockWeekly[i] = LeaderboardEntry(
          userId: mockWeekly[i].userId,
          username: mockWeekly[i].username,
          totalXP: mockWeekly[i].totalXP,
          weeklyXP: mockWeekly[i].weeklyXP,
          rank: mockWeekly[i].rank,
          weeklyRank: i + 1,
          averageAccuracy: mockWeekly[i].averageAccuracy,
          dailyStreak: mockWeekly[i].dailyStreak,
          badgesEarned: mockWeekly[i].badgesEarned,
          lastActive: mockWeekly[i].lastActive,
        );
      }

      return Leaderboard(
        allTimeLeaders: mockAllTime,
        weeklyLeaders: mockWeekly,
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Fetch real leaderboard data from Firestore
  Future<List<LeaderboardEntry>> _fetchLeaderboardData(
      {bool isWeekly = false}) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      // For weekly leaderboard, we only consider data from the last 7 days
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get all users' progress data
      final query = await firestore.collection('users').get();

      List<LeaderboardEntry> entries = [];

      for (var doc in query.docs) {
        final userData = doc.data();

        // Skip if no progress data
        if (!userData.containsKey('progress') || userData['progress'] == null) {
          continue;
        }

        final progressData = userData['progress'];
        final userId = doc.id;
        final username = userData['username'] ?? 'Anonymous';

        // Calculate XP based on timeframe
        int totalXP = progressData['totalXP'] ?? 0;
        int weeklyXP = 0;

        // For weekly XP, we would need to track daily XP gains
        // For now, we'll estimate based on recent activity
        if (progressData.containsKey('lastUpdated')) {
          try {
            final lastUpdated =
                (progressData['lastUpdated'] as Timestamp).toDate();
            if (lastUpdated.isAfter(weekAgo)) {
              weeklyXP = math.min(totalXP ~/ 4, 300);
            }
          } catch (e) {
            // If parsing fails, use a default calculation
            weeklyXP = math.min(totalXP ~/ 4, 300);
          }
        }

        // Get other user stats
        final accuracy = (progressData['averageAccuracy'] ?? 0.0) as double;
        final streak = progressData['dailyStreak'] ?? 0;
        final badges = progressData['badgesEarned'] ?? 0;
        final lastActive = progressData.containsKey('lastUpdated')
            ? (progressData['lastUpdated'] as Timestamp).toDate()
            : now;

        entries.add(LeaderboardEntry(
          userId: userId,
          username: username,
          totalXP: totalXP,
          weeklyXP: weeklyXP,
          rank: 0, // Will be calculated later
          weeklyRank: 0, // Will be calculated later
          averageAccuracy: accuracy,
          dailyStreak: streak,
          badgesEarned: badges,
          lastActive: lastActive,
        ));
      }

      // Sort by XP (descending)
      entries.sort((a, b) => isWeekly
          ? b.weeklyXP.compareTo(a.weeklyXP)
          : b.totalXP.compareTo(a.totalXP));

      // Assign ranks
      for (int i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          userId: entries[i].userId,
          username: entries[i].username,
          totalXP: entries[i].totalXP,
          weeklyXP: entries[i].weeklyXP,
          rank: isWeekly ? entries[i].rank : (i + 1),
          weeklyRank: isWeekly ? (i + 1) : entries[i].weeklyRank,
          averageAccuracy: entries[i].averageAccuracy,
          dailyStreak: entries[i].dailyStreak,
          badgesEarned: entries[i].badgesEarned,
          lastActive: entries[i].lastActive,
        );
      }

      return entries;
    } catch (e) {
      // Fallback to mock data if Firebase fails
      return _generateMockLeaderboard(isWeekly: isWeekly);
    }
  }

  // Generate mock leaderboard data for demonstration (fallback)
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
