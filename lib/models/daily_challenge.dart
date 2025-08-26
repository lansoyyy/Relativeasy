import '../utils/const.dart';
import 'calculation_result.dart';
import 'dart:math' as math;

class DailyChallenge {
  final String id;
  final String title;
  final String question;
  final DifficultyLevel difficulty;
  final CalculationType type;
  final double expectedAnswer;
  final String unit;
  final Map<String, dynamic> parameters;
  final String explanation;
  final String hint;
  final DateTime date;
  final bool isCompleted;
  final double? userAnswer;
  final bool? isCorrect;
  final DateTime? completedAt;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.question,
    required this.difficulty,
    required this.type,
    required this.expectedAnswer,
    required this.unit,
    required this.parameters,
    required this.explanation,
    required this.hint,
    required this.date,
    this.isCompleted = false,
    this.userAnswer,
    this.isCorrect,
    this.completedAt,
  });

  static List<DailyChallenge> generateChallengesForWeek(DateTime startDate) {
    List<DailyChallenge> challenges = [];

    for (int i = 0; i < 7; i++) {
      DateTime date = startDate.add(Duration(days: i));
      DifficultyLevel difficulty = _getDifficultyForDay(i);

      challenges.add(_generateChallengeForDate(date, difficulty));
    }

    return challenges;
  }

  static DifficultyLevel _getDifficultyForDay(int dayIndex) {
    // Cycle through difficulties: 2 beginner, 3 intermediate, 2 expert per week
    switch (dayIndex % 7) {
      case 0:
      case 1:
        return DifficultyLevel.beginner;
      case 2:
      case 3:
      case 4:
        return DifficultyLevel.intermediate;
      case 5:
      case 6:
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.beginner;
    }
  }

  static DailyChallenge _generateChallengeForDate(
      DateTime date, DifficultyLevel difficulty) {
    String id = 'challenge_${date.year}_${date.month}_${date.day}';

    switch (difficulty) {
      case DifficultyLevel.beginner:
        return _generateBeginnerChallenge(id, date);
      case DifficultyLevel.intermediate:
        return _generateIntermediateChallenge(id, date);
      case DifficultyLevel.expert:
        return _generateExpertChallenge(id, date);
    }
  }

  static DailyChallenge _generateBeginnerChallenge(String id, DateTime date) {
    // Simple time dilation problem
    double velocity = 0.5 + (date.day % 3) * 0.1; // 0.5c to 0.7c
    double properTime = 10.0 + (date.day % 5) * 2; // 10 to 18 years

    double dilatedTime = properTime / (1 - velocity * velocity).sqrt();

    return DailyChallenge(
      id: id,
      title: 'Time Dilation Basics',
      question:
          'A spaceship travels at ${(velocity * 100).toStringAsFixed(0)}% the speed of light. If ${properTime.toStringAsFixed(0)} years pass on the ship, how much time passes on Earth?',
      difficulty: DifficultyLevel.beginner,
      type: CalculationType.timeDilation,
      expectedAnswer: dilatedTime,
      unit: 'years',
      parameters: {
        'velocity': velocity,
        'properTime': properTime,
      },
      explanation:
          'When objects move at high speeds, time passes slower for them relative to stationary observers. This is calculated using the Lorentz factor.',
      hint: 'Use the time dilation formula: Δt = Δt₀ / √(1 - v²/c²)',
      date: date,
    );
  }

  static DailyChallenge _generateIntermediateChallenge(
      String id, DateTime date) {
    // Length contraction problem
    double velocity = 0.7 + (date.day % 3) * 0.05; // 0.7c to 0.8c
    double properLength = 100.0 + (date.day % 4) * 50; // 100 to 250 meters

    double contractedLength = properLength * (1 - velocity * velocity).sqrt();

    return DailyChallenge(
      id: id,
      title: 'Length Contraction',
      question:
          'A rod with proper length ${properLength.toStringAsFixed(0)}m moves at ${(velocity * 100).toStringAsFixed(1)}% the speed of light. What is its contracted length as observed from a stationary frame?',
      difficulty: DifficultyLevel.intermediate,
      type: CalculationType.lengthContraction,
      expectedAnswer: contractedLength,
      unit: 'meters',
      parameters: {
        'velocity': velocity,
        'properLength': properLength,
      },
      explanation:
          'Objects appear shorter in the direction of motion when moving at relativistic speeds.',
      hint: 'Use the length contraction formula: L = L₀ × √(1 - v²/c²)',
      date: date,
    );
  }

  static DailyChallenge _generateExpertChallenge(String id, DateTime date) {
    // Complex scenario
    double velocity = 0.85 + (date.day % 3) * 0.03; // 0.85c to 0.91c
    double properTime = 5.0 + (date.day % 3) * 2; // 5 to 9 years

    double dilatedTime = properTime / (1 - velocity * velocity).sqrt();

    return DailyChallenge(
      id: id,
      title: 'Relativistic Journey',
      question:
          'An astronaut travels to a star system ${(velocity * 100).toStringAsFixed(1)}% the speed of light. If the journey takes ${properTime.toStringAsFixed(0)} years in the ship\'s frame, how much time passes on Earth? Consider only the outbound journey.',
      difficulty: DifficultyLevel.expert,
      type: CalculationType.timeDilation,
      expectedAnswer: dilatedTime,
      unit: 'years',
      parameters: {
        'velocity': velocity,
        'properTime': properTime,
      },
      explanation:
          'At very high speeds, the time dilation effect becomes extreme. This is why interstellar travel might be possible for travelers but not for those left behind.',
      hint:
          'Remember that time dilation becomes more pronounced as velocity approaches the speed of light.',
      date: date,
    );
  }

  DailyChallenge completeChallenge(double userAnswer) {
    bool correct = (userAnswer - expectedAnswer).abs() / expectedAnswer <
        0.05; // 5% tolerance

    return DailyChallenge(
      id: id,
      title: title,
      question: question,
      difficulty: difficulty,
      type: type,
      expectedAnswer: expectedAnswer,
      unit: unit,
      parameters: parameters,
      explanation: explanation,
      hint: hint,
      date: date,
      isCompleted: true,
      userAnswer: userAnswer,
      isCorrect: correct,
      completedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'question': question,
      'difficulty': difficulty.index,
      'type': type.index,
      'expectedAnswer': expectedAnswer,
      'unit': unit,
      'parameters': parameters,
      'explanation': explanation,
      'hint': hint,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'],
      title: json['title'],
      question: json['question'],
      difficulty: DifficultyLevel.values[json['difficulty']],
      type: CalculationType.values[json['type']],
      expectedAnswer: json['expectedAnswer'].toDouble(),
      unit: json['unit'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      explanation: json['explanation'],
      hint: json['hint'],
      date: DateTime.parse(json['date']),
      isCompleted: json['isCompleted'] ?? false,
      userAnswer: json['userAnswer']?.toDouble(),
      isCorrect: json['isCorrect'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

extension SquareRoot on double {
  double sqrt() => math.sqrt(this);
}
