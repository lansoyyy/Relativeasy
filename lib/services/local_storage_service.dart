import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_progress.dart';
import '../models/badge.dart';
import '../models/daily_challenge.dart';
import '../models/calculation_result.dart';
import '../utils/const.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance =>
      _instance ??= LocalStorageService._();

  LocalStorageService._();

  Database? _database;
  SharedPreferences? _prefs;

  // Initialize the storage service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _database = await _initDatabase();
  }

  // Initialize SQLite database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'relativeasy.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create tables
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // User Progress Table
    await db.execute('''
      CREATE TABLE user_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        total_xp INTEGER DEFAULT 0,
        current_level INTEGER DEFAULT 1,
        current_level_xp INTEGER DEFAULT 0,
        xp_to_next_level INTEGER DEFAULT 100,
        daily_streak INTEGER DEFAULT 0,
        last_daily_challenge TEXT,
        tutorial_completed INTEGER DEFAULT 0,
        average_accuracy REAL DEFAULT 0.0,
        total_problems_attempted INTEGER DEFAULT 0,
        total_problems_correct INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_updated TEXT NOT NULL
      )
    ''');

    // Calculation Results Table
    await db.execute('''
      CREATE TABLE calculation_results (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        input_value REAL NOT NULL,
        velocity REAL NOT NULL,
        result REAL NOT NULL,
        explanation TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        unit TEXT NOT NULL
      )
    ''');

    // Daily Challenges Table
    await db.execute('''
      CREATE TABLE daily_challenges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        question TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        type INTEGER NOT NULL,
        expected_answer REAL NOT NULL,
        unit TEXT NOT NULL,
        parameters TEXT NOT NULL,
        explanation TEXT NOT NULL,
        hint TEXT NOT NULL,
        date TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        user_answer REAL,
        is_correct INTEGER,
        completed_at TEXT
      )
    ''');

    // Badges Table (for tracking unlocked status)
    await db.execute('''
      CREATE TABLE user_badges (
        id TEXT PRIMARY KEY,
        badge_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // User Progress Methods
  Future<void> saveUserProgress(UserProgress progress) async {
    if (_database == null) return;

    await _database!.insert(
      'user_progress',
      {
        'id': 'default',
        'user_id': progress.userId,
        'total_xp': progress.totalXP,
        'current_level': progress.currentLevel,
        'current_level_xp': progress.currentLevelXP,
        'xp_to_next_level': progress.xpToNextLevel,
        'daily_streak': progress.dailyStreak,
        'last_daily_challenge': progress.lastDailyChallenge.toIso8601String(),
        'tutorial_completed': progress.tutorialCompleted ? 1 : 0,
        'average_accuracy': progress.averageAccuracy,
        'total_problems_attempted': progress.totalProblemsAttempted,
        'total_problems_correct': progress.totalProblemsCorrect,
        'created_at': progress.createdAt.toIso8601String(),
        'last_updated': progress.lastUpdated.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save difficulty-specific progress in SharedPreferences
    await _prefs!.setString(
        'levels_by_difficulty',
        jsonEncode(progress.levelsByDifficulty
            .map((key, value) => MapEntry(key.index.toString(), value))));
    await _prefs!.setString(
        'xp_by_difficulty',
        jsonEncode(progress.xpByDifficulty
            .map((key, value) => MapEntry(key.index.toString(), value))));
    await _prefs!.setString(
        'problems_solved_by_difficulty',
        jsonEncode(progress.problemsSolvedByDifficulty
            .map((key, value) => MapEntry(key.index.toString(), value))));
    await _prefs!.setString(
        'problems_to_next_level',
        jsonEncode(progress.problemsToNextLevel
            .map((key, value) => MapEntry(key.index.toString(), value))));
    await _prefs!.setStringList('unlocked_badges', progress.unlockedBadges);
  }

  Future<UserProgress?> loadUserProgress() async {
    if (_database == null) return null;

    final List<Map<String, dynamic>> maps = await _database!.query(
      'user_progress',
      where: 'id = ?',
      whereArgs: ['default'],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;

    // Load difficulty-specific data from SharedPreferences
    final levelsByDifficultyJson = _prefs!.getString('levels_by_difficulty');
    final xpByDifficultyJson = _prefs!.getString('xp_by_difficulty');
    final problemsSolvedJson =
        _prefs!.getString('problems_solved_by_difficulty');
    final problemsToNextLevelJson = _prefs!.getString('problems_to_next_level');
    final unlockedBadges = _prefs!.getStringList('unlocked_badges') ?? [];

    return UserProgress(
      userId: map['user_id'],
      totalXP: map['total_xp'],
      currentLevel: map['current_level'],
      currentLevelXP: map['current_level_xp'],
      xpToNextLevel: map['xp_to_next_level'],
      levelsByDifficulty: levelsByDifficultyJson != null
          ? Map<DifficultyLevel, int>.from(
              (jsonDecode(levelsByDifficultyJson) as Map).map((key, value) =>
                  MapEntry(DifficultyLevel.values[int.parse(key)], value)))
          : null,
      xpByDifficulty: xpByDifficultyJson != null
          ? Map<DifficultyLevel, int>.from(
              (jsonDecode(xpByDifficultyJson) as Map).map((key, value) =>
                  MapEntry(DifficultyLevel.values[int.parse(key)], value)))
          : null,
      problemsSolvedByDifficulty: problemsSolvedJson != null
          ? Map<DifficultyLevel, int>.from(
              (jsonDecode(problemsSolvedJson) as Map).map((key, value) =>
                  MapEntry(DifficultyLevel.values[int.parse(key)], value)))
          : null,
      problemsToNextLevel: problemsToNextLevelJson != null
          ? Map<DifficultyLevel, int>.from(
              (jsonDecode(problemsToNextLevelJson) as Map).map((key, value) =>
                  MapEntry(DifficultyLevel.values[int.parse(key)], value)))
          : null,
      unlockedBadges: unlockedBadges,
      dailyStreak: map['daily_streak'],
      lastDailyChallenge: DateTime.parse(map['last_daily_challenge']),
      tutorialCompleted: map['tutorial_completed'] == 1,
      averageAccuracy: map['average_accuracy'],
      totalProblemsAttempted: map['total_problems_attempted'],
      totalProblemsCorrect: map['total_problems_correct'],
      createdAt: DateTime.parse(map['created_at']),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  // Calculation Results Methods
  Future<void> saveCalculationResult(CalculationResult result) async {
    if (_database == null) return;

    await _database!.insert(
      'calculation_results',
      {
        'id': result.id,
        'type': result.type.index,
        'input_value': result.inputValue,
        'velocity': result.velocity,
        'result': result.result,
        'explanation': result.explanation,
        'timestamp': result.timestamp.toIso8601String(),
        'unit': result.unit,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CalculationResult>> loadCalculationResults(
      {int limit = 100}) async {
    if (_database == null) return [];

    final List<Map<String, dynamic>> maps = await _database!.query(
      'calculation_results',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps
        .map((map) => CalculationResult(
              id: map['id'],
              type: CalculationType.values[map['type']],
              inputValue: map['input_value'],
              velocity: map['velocity'],
              result: map['result'],
              explanation: map['explanation'],
              timestamp: DateTime.parse(map['timestamp']),
              unit: map['unit'],
            ))
        .toList();
  }

  // Daily Challenges Methods
  Future<void> saveDailyChallenge(DailyChallenge challenge) async {
    if (_database == null) return;

    await _database!.insert(
      'daily_challenges',
      {
        'id': challenge.id,
        'title': challenge.title,
        'question': challenge.question,
        'difficulty': challenge.difficulty.index,
        'type': challenge.type.index,
        'expected_answer': challenge.expectedAnswer,
        'unit': challenge.unit,
        'parameters': jsonEncode(challenge.parameters),
        'explanation': challenge.explanation,
        'hint': challenge.hint,
        'date': challenge.date.toIso8601String(),
        'is_completed': challenge.isCompleted ? 1 : 0,
        'user_answer': challenge.userAnswer,
        'is_correct':
            challenge.isCorrect != null ? (challenge.isCorrect! ? 1 : 0) : null,
        'completed_at': challenge.completedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DailyChallenge>> loadDailyChallenges() async {
    if (_database == null) return [];

    final List<Map<String, dynamic>> maps = await _database!.query(
      'daily_challenges',
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => DailyChallenge(
              id: map['id'],
              title: map['title'],
              question: map['question'],
              difficulty: DifficultyLevel.values[map['difficulty']],
              type: CalculationType.values[map['type']],
              expectedAnswer: map['expected_answer'],
              unit: map['unit'],
              parameters:
                  Map<String, dynamic>.from(jsonDecode(map['parameters'])),
              explanation: map['explanation'],
              hint: map['hint'],
              date: DateTime.parse(map['date']),
              isCompleted: map['is_completed'] == 1,
              userAnswer: map['user_answer'],
              isCorrect:
                  map['is_correct'] != null ? map['is_correct'] == 1 : null,
              completedAt: map['completed_at'] != null
                  ? DateTime.parse(map['completed_at'])
                  : null,
            ))
        .toList();
  }

  // Badge Methods
  Future<void> saveBadgeUnlock(String badgeId) async {
    if (_database == null) return;

    await _database!.insert(
      'user_badges',
      {
        'id': '${badgeId}_${DateTime.now().millisecondsSinceEpoch}',
        'badge_id': badgeId,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> loadUnlockedBadges() async {
    if (_database == null) return [];

    final List<Map<String, dynamic>> maps =
        await _database!.query('user_badges');
    return maps.map((map) => map['badge_id'] as String).toList();
  }

  // Settings Methods
  Future<void> saveSetting(String key, String value) async {
    if (_prefs == null) return;
    await _prefs!.setString(key, value);
  }

  Future<String?> loadSetting(String key) async {
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }

  // Cleanup Methods
  Future<void> clearAllData() async {
    if (_database == null || _prefs == null) return;

    // Clear database tables
    await _database!.delete('user_progress');
    await _database!.delete('calculation_results');
    await _database!.delete('daily_challenges');
    await _database!.delete('user_badges');
    await _database!.delete('user_settings');

    // Clear SharedPreferences
    await _prefs!.clear();
  }

  Future<void> clearCalculationHistory() async {
    if (_database == null) return;
    await _database!.delete('calculation_results');
  }

  // Export/Import Methods (for backup)
  Future<Map<String, dynamic>> exportData() async {
    final userProgress = await loadUserProgress();
    final calculations = await loadCalculationResults();
    final challenges = await loadDailyChallenges();
    final badges = await loadUnlockedBadges();

    return {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'user_progress': userProgress?.toJson(),
      'calculations': calculations.map((c) => c.toJson()).toList(),
      'challenges': challenges.map((c) => c.toJson()).toList(),
      'badges': badges,
    };
  }

  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // Clear existing data
      await clearAllData();

      // Import user progress
      if (data['user_progress'] != null) {
        final progress = UserProgress.fromJson(data['user_progress']);
        await saveUserProgress(progress);
      }

      // Import calculations
      if (data['calculations'] != null) {
        for (final calc in data['calculations']) {
          final calculation = CalculationResult.fromJson(calc);
          await saveCalculationResult(calculation);
        }
      }

      // Import challenges
      if (data['challenges'] != null) {
        for (final challenge in data['challenges']) {
          final dailyChallenge = DailyChallenge.fromJson(challenge);
          await saveDailyChallenge(dailyChallenge);
        }
      }

      // Import badges
      if (data['badges'] != null) {
        for (final badgeId in data['badges']) {
          await saveBadgeUnlock(badgeId);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
