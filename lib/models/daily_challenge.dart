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
    // More diverse time dilation problems with unique parameters
    // Using date.microsecondsSinceEpoch for better uniqueness
    int seed = date.microsecondsSinceEpoch ~/ 1000;
    seed = seed + id.hashCode; // Add additional uniqueness from the ID

    // Generate unique velocity between 0.3c and 0.8c
    double velocity = 0.3 + (seed % 51) * 0.01; // 0.30c to 0.80c

    // Generate unique proper time between 5 and 30 years
    double properTime = 5.0 + (seed % 251) * 0.1; // 5.0 to 30.0 years

    double dilatedTime = properTime / (1 - velocity * velocity).sqrt();

    return DailyChallenge(
      id: id,
      title: 'Time Dilation Basics',
      question:
          'A spaceship travels at ${(velocity * 100).toStringAsFixed(1)}% the speed of light. If ${properTime.toStringAsFixed(1)} years pass on the ship, how much time passes on Earth?',
      difficulty: DifficultyLevel.beginner,
      type: CalculationType.timeDilation,
      expectedAnswer: dilatedTime,
      unit: 'years',
      parameters: {
        'velocity': velocity,
        'properTime': properTime,
      },
      explanation:
          'When objects move at high speeds, time passes slower for them relative to stationary observers. This is calculated using the Lorentz factor: Δt = Δt₀ / √(1 - v²/c²)',
      hint:
          'Use the time dilation formula: Δt = Δt₀ / √(1 - v²/c²). Remember to square the velocity ratio (v/c).',
      date: date,
    );
  }

  static DailyChallenge _generateIntermediateChallenge(
      String id, DateTime date) {
    // More diverse length contraction problems with unique parameters
    int seed = date.microsecondsSinceEpoch ~/ 1000;
    seed = seed + id.hashCode; // Add additional uniqueness from the ID

    // Generate unique velocity between 0.6c and 0.95c
    double velocity = 0.6 + (seed % 36) * 0.01; // 0.60c to 0.95c

    // Generate unique proper length between 50 and 500 meters
    double properLength = 50.0 + (seed % 4501) * 0.1; // 50.0 to 500.0 meters

    double contractedLength = properLength * (1 - velocity * velocity).sqrt();

    // Alternate between different question formats
    String question;
    if (seed % 3 == 0) {
      question =
          'A rod with proper length ${properLength.toStringAsFixed(1)}m moves at ${(velocity * 100).toStringAsFixed(1)}% the speed of light. What is its contracted length as observed from a stationary frame?';
    } else if (seed % 3 == 1) {
      question =
          'An object that is ${properLength.toStringAsFixed(1)}m long at rest appears to be how long when moving at ${(velocity * 100).toStringAsFixed(1)}% the speed of light?';
    } else {
      question =
          'A spaceship that is ${properLength.toStringAsFixed(1)}m long at rest is traveling at ${(velocity * 100).toStringAsFixed(1)}% the speed of light. What length would an observer at rest measure?';
    }

    // Vary the title based on seed
    String title;
    if (seed % 4 == 0) {
      title = 'Length Contraction';
    } else if (seed % 4 == 1) {
      title = 'Lorentz Contraction';
    } else if (seed % 4 == 2) {
      title = 'Relativistic Length';
    } else {
      title = 'Contracted Dimensions';
    }

    return DailyChallenge(
      id: id,
      title: title,
      question: question,
      difficulty: DifficultyLevel.intermediate,
      type: CalculationType.lengthContraction,
      expectedAnswer: contractedLength,
      unit: 'meters',
      parameters: {
        'velocity': velocity,
        'properLength': properLength,
      },
      explanation:
          'Objects appear shorter in the direction of motion when moving at relativistic speeds. This is calculated using the length contraction formula: L = L₀ × √(1 - v²/c²)',
      hint:
          'Use the length contraction formula: L = L₀ × √(1 - v²/c²). Remember that the contracted length is always less than the proper length.',
      date: date,
    );
  }

  static DailyChallenge _generateExpertChallenge(String id, DateTime date) {
    // More complex scenarios with unique parameters
    int seed = date.microsecondsSinceEpoch ~/ 1000;
    seed = seed + id.hashCode; // Add additional uniqueness from the ID

    // Generate unique velocity between 0.9c and 0.99c
    double velocity = 0.9 + (seed % 100) * 0.001; // 0.900c to 0.999c

    // Generate unique proper time between 1 and 20 years
    double properTime = 1.0 + (seed % 191) * 0.1; // 1.0 to 20.0 years

    double dilatedTime = properTime / (1 - velocity * velocity).sqrt();

    // Alternate between different expert scenarios
    String title, question, explanation;
    if (seed % 5 == 0) {
      title = 'Interstellar Journey';
      question =
          'An astronaut travels to a star system ${(velocity * 100).toStringAsFixed(2)}% the speed of light. If the journey takes ${properTime.toStringAsFixed(1)} years in the ship\'s frame, how much time passes on Earth? Consider only the outbound journey.';
      explanation =
          'At very high speeds, the time dilation effect becomes extreme. This is why interstellar travel might be possible for travelers but not for those left behind.';
    } else if (seed % 5 == 1) {
      title = 'Twin Paradox';
      question =
          'One twin travels at ${(velocity * 100).toStringAsFixed(2)}% the speed of light for ${properTime.toStringAsFixed(1)} years (ship time) and returns. How much older is the Earth twin when the traveling twin returns?';
      explanation =
          'The twin paradox demonstrates that time passes differently for observers in relative motion. The traveling twin experiences less time than the stationary twin.';
    } else if (seed % 5 == 2) {
      title = 'Relativistic Effects';
      question =
          'A spacecraft travels at ${(velocity * 100).toStringAsFixed(2)}% the speed of light. If ${properTime.toStringAsFixed(1)} years pass for the crew, how much time has passed on their home planet?';
      explanation =
          'Time dilation is a fundamental aspect of special relativity. As objects approach the speed of light, time slows down relative to stationary observers.';
    } else if (seed % 5 == 3) {
      title = 'High-Speed Travel';
      question =
          'A probe is sent to a distant star at ${(velocity * 100).toStringAsFixed(2)}% the speed of light. Mission control observes that ${properTime.toStringAsFixed(1)} years pass for the probe. How much time has passed on Earth?';
      explanation =
          'The faster an object moves, the more pronounced the time dilation effect becomes. This is a direct consequence of Einstein\'s theory of special relativity.';
    } else {
      title = 'Time Dilation Extreme';
      question =
          'At ${(velocity * 100).toStringAsFixed(2)}% the speed of light, if ${properTime.toStringAsFixed(1)} years pass for a moving observer, how much time passes for a stationary observer?';
      explanation =
          'The Lorentz factor γ = 1/√(1 - v²/c²) determines the magnitude of relativistic effects. As velocity approaches c, γ approaches infinity.';
    }

    return DailyChallenge(
      id: id,
      title: title,
      question: question,
      difficulty: DifficultyLevel.expert,
      type: CalculationType.timeDilation,
      expectedAnswer: dilatedTime,
      unit: 'years',
      parameters: {
        'velocity': velocity,
        'properTime': properTime,
      },
      explanation: explanation,
      hint:
          'Remember that time dilation becomes more pronounced as velocity approaches the speed of light. Use the formula: Δt = Δt₀ / √(1 - v²/c²)',
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
