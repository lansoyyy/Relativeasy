import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../models/badge.dart' as app_badge;
import '../models/daily_challenge.dart';
import '../models/calculation_result.dart';
import '../models/leaderboard.dart';
import '../services/local_storage_service.dart';
import '../services/leaderboard_service.dart';
import '../utils/const.dart';

class AppStateProvider extends ChangeNotifier {
  UserProgress? _userProgress;
  List<app_badge.Badge> _badges = [];
  List<DailyChallenge> _dailyChallenges = [];
  List<CalculationResult> _calculationHistory = [];
  bool _isFirstTimeUser = true;
  bool _tutorialCompleted = false;
  bool _isInitialized = false;

  final LocalStorageService _storage = LocalStorageService.instance;
  final LeaderboardService _leaderboardService = LeaderboardService.instance;

  Leaderboard? _leaderboard;

  // Getters
  UserProgress? get userProgress => _userProgress;
  List<app_badge.Badge> get badges => _badges;
  List<DailyChallenge> get dailyChallenges => _dailyChallenges;
  List<CalculationResult> get calculationHistory => _calculationHistory;
  bool get isFirstTimeUser => _isFirstTimeUser;
  bool get tutorialCompleted => _tutorialCompleted;
  bool get isInitialized => _isInitialized;
  Leaderboard? get leaderboard => _leaderboard;

  // Navigation
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Initialize user data
  Future<void> initializeUser(String userId) async {
    if (_isInitialized) return;

    try {
      // Initialize storage
      await _storage.initialize();

      // Load saved data
      _userProgress = await _storage.loadUserProgress();
      _calculationHistory = await _storage.loadCalculationResults();
      _dailyChallenges = await _storage.loadDailyChallenges();

      // If no saved data, create new user
      if (_userProgress == null) {
        _userProgress = UserProgress(userId: userId);
        _isFirstTimeUser = true;
        _tutorialCompleted = false;

        // Generate initial challenges
        _dailyChallenges =
            DailyChallenge.generateChallengesForWeek(DateTime.now());

        // Save initial data
        await _saveUserData();
      } else {
        _isFirstTimeUser = false;
        _tutorialCompleted = _userProgress!.tutorialCompleted;

        // Generate new challenges if needed
        if (_dailyChallenges.isEmpty || _shouldGenerateNewChallenges()) {
          _dailyChallenges =
              DailyChallenge.generateChallengesForWeek(DateTime.now());
          await _saveChallenges();
        }
      }

      // Initialize badges with unlock status
      await _initializeBadges();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Fallback to default initialization if storage fails
      _userProgress = UserProgress(userId: userId);
      _badges = app_badge.Badge.getAllBadges();
      _dailyChallenges =
          DailyChallenge.generateChallengesForWeek(DateTime.now());
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Tutorial methods
  void startTutorial() {
    _isFirstTimeUser = true;
    notifyListeners();
  }

  void completeTutorial() {
    _tutorialCompleted = true;
    _isFirstTimeUser = false;
    _userProgress?.completeTutorial();

    // Unlock Einstein Apprentice badge
    unlockBadge('einstein_apprentice');

    // Save progress
    _saveUserData();

    notifyListeners();
  }

  // Progress tracking
  void addXP(DifficultyLevel difficulty, bool isCorrect) {
    _userProgress?.addXP(difficulty, isCorrect);
    _checkBadgeUnlocks();
    _saveUserData();
    notifyListeners();
  }

  void addCalculationResult(CalculationResult result) {
    _calculationHistory.insert(0, result);

    // Keep only last 100 calculations
    if (_calculationHistory.length > 100) {
      _calculationHistory = _calculationHistory.take(100).toList();
    }

    // Save to storage
    _storage.saveCalculationResult(result);

    _checkBadgeUnlocks();
    notifyListeners();
  }

  void completeDailyChallenge(String challengeId, double userAnswer) {
    final challengeIndex =
        _dailyChallenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex != -1) {
      final challenge = _dailyChallenges[challengeIndex];
      final completedChallenge = challenge.completeChallenge(userAnswer);
      _dailyChallenges[challengeIndex] = completedChallenge;

      if (completedChallenge.isCorrect == true) {
        _userProgress?.completeDailyChallenge();
        addXP(challenge.difficulty, true);
      } else {
        addXP(challenge.difficulty, false);
      }

      _checkBadgeUnlocks();
      notifyListeners();
    }
  }

  void unlockBadge(String badgeId) {
    final badgeIndex = _badges.indexWhere((b) => b.id == badgeId);
    if (badgeIndex != -1 && !_badges[badgeIndex].isUnlocked) {
      _badges[badgeIndex] = _badges[badgeIndex].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      _userProgress?.unlockBadge(badgeId);

      // Save badge unlock to storage
      _storage.saveBadgeUnlock(badgeId);

      // Show badge unlock notification
      _showBadgeUnlockNotification(badgeId);

      notifyListeners();
    }
  }

  void _checkBadgeUnlocks() {
    if (_userProgress == null) return;

    // Check Einstein Apprentice
    if (_tutorialCompleted && !_isBadgeUnlocked('einstein_apprentice')) {
      unlockBadge('einstein_apprentice');
    }

    // Check Speed Sprinter (5 problems with speed >= 0.8c)
    int highSpeedProblems =
        _calculationHistory.where((r) => r.velocity >= 0.8).length;
    if (highSpeedProblems >= 5 && !_isBadgeUnlocked('speed_sprinter')) {
      unlockBadge('speed_sprinter');
    }

    // Check Time Twister (3 expert time dilation problems)
    int expertTimeDilationProblems = _dailyChallenges
        .where((c) =>
            c.type == CalculationType.timeDilation &&
            c.difficulty == DifficultyLevel.expert &&
            c.isCompleted &&
            c.isCorrect == true)
        .length;
    if (expertTimeDilationProblems >= 3 && !_isBadgeUnlocked('time_twister')) {
      unlockBadge('time_twister');
    }

    // Check Shrink Master (3 intermediate+ length contraction problems)
    int intermediateExpertLengthProblems = _dailyChallenges
        .where((c) =>
            c.type == CalculationType.lengthContraction &&
            (c.difficulty == DifficultyLevel.intermediate ||
                c.difficulty == DifficultyLevel.expert) &&
            c.isCompleted &&
            c.isCorrect == true)
        .length;
    if (intermediateExpertLengthProblems >= 3 &&
        !_isBadgeUnlocked('shrink_master')) {
      unlockBadge('shrink_master');
    }

    // Check Daily Streaker (5 day streak)
    if (_userProgress!.dailyStreak >= 5 &&
        !_isBadgeUnlocked('daily_streaker')) {
      unlockBadge('daily_streaker');
    }

    // Check Relativity Challenger (90% accuracy in 10 consecutive dailies)
    if (_userProgress!.averageAccuracy >= 0.9 &&
        _userProgress!.totalProblemsAttempted >= 10 &&
        !_isBadgeUnlocked('relativity_challenger')) {
      unlockBadge('relativity_challenger');
    }

    // Check Formula Wizard (10 complex calculations)
    int complexCalculations = _calculationHistory
        .where((r) =>
            r.velocity >= 0.7) // Complex problems typically involve high speeds
        .length;
    if (complexCalculations >= 10 && !_isBadgeUnlocked('formula_wizard')) {
      unlockBadge('formula_wizard');
    }

    // Check Concept Crusher (perfect accuracy on a sample of problems)
    if (_userProgress!.averageAccuracy >= 1.0 &&
        _userProgress!.totalProblemsAttempted >= 5 &&
        !_isBadgeUnlocked('concept_crusher')) {
      unlockBadge('concept_crusher');
    }

    // Check Level Legend (Level 15 total)
    if (_userProgress!.currentLevel >= 15 &&
        !_isBadgeUnlocked('level_legend')) {
      unlockBadge('level_legend');
    }

    // Check Grand Master (all other badges unlocked)
    List<String> requiredBadges = [
      'einstein_apprentice',
      'speed_sprinter',
      'time_twister',
      'shrink_master',
      'daily_streaker',
      'relativity_challenger',
      'formula_wizard',
      'concept_crusher',
      'level_legend'
    ];
    bool allBadgesUnlocked = requiredBadges.every(_isBadgeUnlocked);
    if (allBadgesUnlocked && !_isBadgeUnlocked('grand_master')) {
      unlockBadge('grand_master');
      _showGrandMasterCelebration();
    }
  }

  bool _isBadgeUnlocked(String badgeId) {
    return _badges.any((b) => b.id == badgeId && b.isUnlocked);
  }

  // Get progress statistics
  Map<String, dynamic> getProgressStats() {
    if (_userProgress == null) {
      return {
        'totalXP': 0,
        'currentLevel': 1,
        'badgesEarned': 0,
        'dailyStreak': 0,
        'averageAccuracy': 0.0,
        'totalProblems': 0,
      };
    }

    return {
      'totalXP': _userProgress!.totalXP,
      'currentLevel': _userProgress!.currentLevel,
      'badgesEarned': _badges.where((b) => b.isUnlocked).length,
      'dailyStreak': _userProgress!.dailyStreak,
      'averageAccuracy': _userProgress!.averageAccuracy,
      'totalProblems': _userProgress!.totalProblemsAttempted,
    };
  }

  // Get today's challenge
  DailyChallenge? getTodaysChallenge() {
    final today = DateTime.now();
    return _dailyChallenges.firstWhere(
      (challenge) =>
          challenge.date.year == today.year &&
          challenge.date.month == today.month &&
          challenge.date.day == today.day,
      orElse: () => _dailyChallenges.first,
    );
  }

  // Get unlocked badges
  List<app_badge.Badge> getUnlockedBadges() {
    return _badges.where((badge) => badge.isUnlocked).toList();
  }

  // Get locked badges
  List<app_badge.Badge> getLockedBadges() {
    return _badges.where((badge) => !badge.isUnlocked).toList();
  }

  // Storage helper methods
  Future<void> _saveUserData() async {
    if (_userProgress != null) {
      await _storage.saveUserProgress(_userProgress!);
    }
  }

  Future<void> _saveChallenges() async {
    for (final challenge in _dailyChallenges) {
      await _storage.saveDailyChallenge(challenge);
    }
  }

  Future<void> _initializeBadges() async {
    final unlockedBadgeIds = await _storage.loadUnlockedBadges();
    _badges = app_badge.Badge.getAllBadges().map((badge) {
      bool isUnlocked = unlockedBadgeIds.contains(badge.id);
      return badge.copyWith(
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked ? DateTime.now() : null,
      );
    }).toList();
  }

  bool _shouldGenerateNewChallenges() {
    if (_dailyChallenges.isEmpty) return true;

    final now = DateTime.now();
    final latestChallenge = _dailyChallenges.first;

    // Generate new challenges if latest is more than a week old
    return now.difference(latestChallenge.date).inDays > 7;
  }

  // Export/Import methods
  Future<Map<String, dynamic>> exportUserData() async {
    return await _storage.exportData();
  }

  Future<bool> importUserData(Map<String, dynamic> data) async {
    final success = await _storage.importData(data);
    if (success) {
      // Reload data after import
      _isInitialized = false;
      await initializeUser('default_user');
    }
    return success;
  }

  // Badge notification methods
  void _showBadgeUnlockNotification(String badgeId) {
    final badge = _badges.firstWhere((b) => b.id == badgeId);
    // This could trigger a notification overlay or toast
    // For now, we'll just track that it was unlocked
    print('🎉 Badge Unlocked: ${badge.name} ${badge.emoji}');
  }

  void _showGrandMasterCelebration() {
    // Special celebration for the ultimate achievement
    print('🌟🎊 GRAND MASTER OF RELATIVITY ACHIEVED! 🎊🌟');
    print('You have mastered Einstein\'s Special Theory of Relativity!');
  }

  // Badge statistics
  Map<String, dynamic> getBadgeStats() {
    final unlockedCount = _badges.where((b) => b.isUnlocked).length;
    final totalCount = _badges.length;
    final completionPercentage = (unlockedCount / totalCount * 100).toInt();

    return {
      'unlocked': unlockedCount,
      'total': totalCount,
      'percentage': completionPercentage,
      'recentlyUnlocked': _badges
          .where((b) => b.isUnlocked && b.unlockedAt != null)
          .where((b) => DateTime.now().difference(b.unlockedAt!).inDays < 7)
          .toList(),
    };
  }

  // Get badges by rarity
  List<app_badge.Badge> getBadgesByRarity(app_badge.BadgeRarity rarity) {
    return _badges.where((badge) => badge.rarity == rarity).toList();
  }

  // Leaderboard methods
  Future<void> refreshLeaderboard() async {
    if (_userProgress != null) {
      int unlockedBadges = _badges.where((b) => b.isUnlocked).length;
      _leaderboard = await _leaderboardService.getLeaderboard(
          _userProgress!, unlockedBadges);
      notifyListeners();
    }
  }

  Map<String, dynamic> getCompetitiveInsights() {
    if (_userProgress != null && _leaderboard != null) {
      return _leaderboardService.getCompetitiveInsights(
          _userProgress!, _leaderboard!);
    }
    return {
      'currentRank': 999,
      'weeklyRank': 999,
      'xpToNextRank': 100,
      'weeklyPosition': 'Keep going!',
    };
  }

  // Check if user is close to unlocking a badge
  List<Map<String, dynamic>> getNearlyUnlockedBadges() {
    List<Map<String, dynamic>> nearly = [];

    // Speed Sprinter progress
    if (!_isBadgeUnlocked('speed_sprinter')) {
      int highSpeedProblems =
          _calculationHistory.where((r) => r.velocity >= 0.8).length;
      if (highSpeedProblems >= 3) {
        nearly.add({
          'badge_id': 'speed_sprinter',
          'progress': highSpeedProblems,
          'required': 5,
          'description':
              'Solve ${5 - highSpeedProblems} more high-speed problems (≥0.8c)',
        });
      }
    }

    // Daily Streaker progress
    if (!_isBadgeUnlocked('daily_streaker') && _userProgress != null) {
      int streak = _userProgress!.dailyStreak;
      if (streak >= 3) {
        nearly.add({
          'badge_id': 'daily_streaker',
          'progress': streak,
          'required': 5,
          'description': 'Keep your streak for ${5 - streak} more days',
        });
      }
    }

    return nearly;
  }
}
