import '../utils/const.dart';

class UserProgress {
  final String userId;
  int totalXP;
  int currentLevel;
  int currentLevelXP;
  int xpToNextLevel;
  Map<DifficultyLevel, int> levelsByDifficulty;
  Map<DifficultyLevel, int> xpByDifficulty;
  Map<DifficultyLevel, int> problemsSolvedByDifficulty;
  Map<DifficultyLevel, int> problemsToNextLevel;
  List<String> unlockedBadges;
  int dailyStreak;
  DateTime lastDailyChallenge;
  bool tutorialCompleted;
  double averageAccuracy;
  int totalProblemsAttempted;
  int totalProblemsCorrect;
  DateTime createdAt;
  DateTime lastUpdated;

  UserProgress({
    required this.userId,
    this.totalXP = 0,
    this.currentLevel = 1,
    this.currentLevelXP = 0,
    this.xpToNextLevel = 100,
    Map<DifficultyLevel, int>? levelsByDifficulty,
    Map<DifficultyLevel, int>? xpByDifficulty,
    Map<DifficultyLevel, int>? problemsSolvedByDifficulty,
    Map<DifficultyLevel, int>? problemsToNextLevel,
    List<String>? unlockedBadges,
    this.dailyStreak = 0,
    DateTime? lastDailyChallenge,
    this.tutorialCompleted = false,
    this.averageAccuracy = 0.0,
    this.totalProblemsAttempted = 0,
    this.totalProblemsCorrect = 0,
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : levelsByDifficulty = levelsByDifficulty ??
            {
              DifficultyLevel.beginner: 1,
              DifficultyLevel.intermediate: 1,
              DifficultyLevel.expert: 1,
            },
        xpByDifficulty = xpByDifficulty ??
            {
              DifficultyLevel.beginner: 0,
              DifficultyLevel.intermediate: 0,
              DifficultyLevel.expert: 0,
            },
        problemsSolvedByDifficulty = problemsSolvedByDifficulty ??
            {
              DifficultyLevel.beginner: 0,
              DifficultyLevel.intermediate: 0,
              DifficultyLevel.expert: 0,
            },
        problemsToNextLevel = problemsToNextLevel ??
            {
              DifficultyLevel.beginner:
                  problemsToLevelUp[DifficultyLevel.beginner]!,
              DifficultyLevel.intermediate:
                  problemsToLevelUp[DifficultyLevel.intermediate]!,
              DifficultyLevel.expert:
                  problemsToLevelUp[DifficultyLevel.expert]!,
            },
        unlockedBadges = unlockedBadges ?? [],
        lastDailyChallenge = lastDailyChallenge ??
            DateTime.now().subtract(const Duration(days: 1)),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  void addXP(DifficultyLevel difficulty, bool isCorrect) {
    if (!isCorrect) {
      totalProblemsAttempted++;
      lastUpdated = DateTime.now();
      return;
    }

    int xpGained = xpValues[difficulty]!;
    totalXP += xpGained;
    xpByDifficulty[difficulty] = (xpByDifficulty[difficulty] ?? 0) + xpGained;
    problemsSolvedByDifficulty[difficulty] =
        (problemsSolvedByDifficulty[difficulty] ?? 0) + 1;
    totalProblemsAttempted++;
    totalProblemsCorrect++;

    // Update accuracy
    averageAccuracy = totalProblemsCorrect / totalProblemsAttempted;

    // Check for level up in specific difficulty
    int currentProblems = problemsSolvedByDifficulty[difficulty]!;
    int requiredProblems = problemsToLevelUp[difficulty]!;

    if (currentProblems >= requiredProblems) {
      levelsByDifficulty[difficulty] =
          (levelsByDifficulty[difficulty] ?? 1) + 1;
      problemsToNextLevel[difficulty] = requiredProblems;
      problemsSolvedByDifficulty[difficulty] =
          0; // Reset counter for next level
    } else {
      problemsToNextLevel[difficulty] = requiredProblems - currentProblems;
    }

    // Update overall level based on total XP
    _updateOverallLevel();

    lastUpdated = DateTime.now();
  }

  void _updateOverallLevel() {
    // Simple level calculation: every 100 XP = 1 level
    int newLevel = (totalXP ~/ 100) + 1;
    if (newLevel > currentLevel) {
      currentLevel = newLevel;
      currentLevelXP = totalXP % 100;
      xpToNextLevel = 100 - currentLevelXP;
    } else {
      currentLevelXP = totalXP % 100;
      xpToNextLevel = 100 - currentLevelXP;
    }
  }

  void completeDailyChallenge() {
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (lastDailyChallenge.day == yesterday.day &&
        lastDailyChallenge.month == yesterday.month &&
        lastDailyChallenge.year == yesterday.year) {
      dailyStreak++;
    } else if (lastDailyChallenge.day != today.day ||
        lastDailyChallenge.month != today.month ||
        lastDailyChallenge.year != today.year) {
      dailyStreak = 1; // Reset streak if more than a day has passed
    }

    lastDailyChallenge = today;
    lastUpdated = DateTime.now();
  }

  void unlockBadge(String badgeId) {
    if (!unlockedBadges.contains(badgeId)) {
      unlockedBadges.add(badgeId);
      lastUpdated = DateTime.now();
    }
  }

  void completeTutorial() {
    tutorialCompleted = true;
    lastUpdated = DateTime.now();
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'],
      totalXP: json['totalXP'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
      currentLevelXP: json['currentLevelXP'] ?? 0,
      xpToNextLevel: json['xpToNextLevel'] ?? 100,
      levelsByDifficulty: Map<DifficultyLevel, int>.from(
          (json['levelsByDifficulty'] as Map? ?? {}).map((key, value) =>
              MapEntry(DifficultyLevel.values[int.parse(key)], value))),
      xpByDifficulty: Map<DifficultyLevel, int>.from(
          (json['xpByDifficulty'] as Map? ?? {}).map((key, value) =>
              MapEntry(DifficultyLevel.values[int.parse(key)], value))),
      problemsSolvedByDifficulty: Map<DifficultyLevel, int>.from(
          (json['problemsSolvedByDifficulty'] as Map? ?? {}).map((key, value) =>
              MapEntry(DifficultyLevel.values[int.parse(key)], value))),
      problemsToNextLevel: Map<DifficultyLevel, int>.from(
          (json['problemsToNextLevel'] as Map? ?? {}).map((key, value) =>
              MapEntry(DifficultyLevel.values[int.parse(key)], value))),
      unlockedBadges: List<String>.from(json['unlockedBadges'] ?? []),
      dailyStreak: json['dailyStreak'] ?? 0,
      lastDailyChallenge: DateTime.parse(json['lastDailyChallenge'] ??
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String()),
      tutorialCompleted: json['tutorialCompleted'] ?? false,
      averageAccuracy: (json['averageAccuracy'] ?? 0.0).toDouble(),
      totalProblemsAttempted: json['totalProblemsAttempted'] ?? 0,
      totalProblemsCorrect: json['totalProblemsCorrect'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(
          json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalXP': totalXP,
      'currentLevel': currentLevel,
      'currentLevelXP': currentLevelXP,
      'xpToNextLevel': xpToNextLevel,
      'levelsByDifficulty': levelsByDifficulty
          .map((key, value) => MapEntry(key.index.toString(), value)),
      'xpByDifficulty': xpByDifficulty
          .map((key, value) => MapEntry(key.index.toString(), value)),
      'problemsSolvedByDifficulty': problemsSolvedByDifficulty
          .map((key, value) => MapEntry(key.index.toString(), value)),
      'problemsToNextLevel': problemsToNextLevel
          .map((key, value) => MapEntry(key.index.toString(), value)),
      'unlockedBadges': unlockedBadges,
      'dailyStreak': dailyStreak,
      'lastDailyChallenge': lastDailyChallenge.toIso8601String(),
      'tutorialCompleted': tutorialCompleted,
      'averageAccuracy': averageAccuracy,
      'totalProblemsAttempted': totalProblemsAttempted,
      'totalProblemsCorrect': totalProblemsCorrect,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
