import '../models/calculation_result.dart';

class KinematicsCalculator {
  /// Calculate displacement using s = ut + ½at²
  static CalculationResult calculateDisplacement({
    required double initialVelocity,
    required double acceleration,
    required double time,
    required String unit,
  }) {
    // Validate input
    if (time < 0) {
      throw ArgumentError('Time cannot be negative');
    }
    if (time == 0) {
      throw ArgumentError('Time cannot be zero');
    }

    // Calculate displacement: s = ut + ½at²
    double displacement =
        (initialVelocity * time) + (0.5 * acceleration * time * time);

    // Generate explanation
    String explanation = _generateDisplacementExplanation(
        initialVelocity, acceleration, time, displacement, unit);

    return CalculationResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CalculationType.displacement,
      inputValue: initialVelocity,
      velocity: acceleration, // Using velocity field to store acceleration
      result: displacement,
      explanation: explanation,
      timestamp: DateTime.now(),
      unit: unit,
    );
  }

  /// Calculate final velocity using v = u + at
  static CalculationResult calculateVelocity({
    required double initialVelocity,
    required double acceleration,
    required double time,
    required String unit,
  }) {
    // Validate input
    if (time < 0) {
      throw ArgumentError('Time cannot be negative');
    }

    // Calculate final velocity: v = u + at
    double finalVelocity = initialVelocity + (acceleration * time);

    // Generate explanation
    String explanation = _generateVelocityExplanation(
        initialVelocity, acceleration, time, finalVelocity, unit);

    return CalculationResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CalculationType.velocity,
      inputValue: initialVelocity,
      velocity: acceleration, // Using velocity field to store acceleration
      result: finalVelocity,
      explanation: explanation,
      timestamp: DateTime.now(),
      unit: unit,
    );
  }

  /// Calculate acceleration using a = (v - u)/t
  static CalculationResult calculateAcceleration({
    required double initialVelocity,
    required double finalVelocity,
    required double time,
    required String unit,
  }) {
    // Validate input
    if (time <= 0) {
      throw ArgumentError('Time must be positive');
    }

    // Calculate acceleration: a = (v - u)/t
    double acceleration = (finalVelocity - initialVelocity) / time;

    // Generate explanation
    String explanation = _generateAccelerationExplanation(
        initialVelocity, finalVelocity, time, acceleration, unit);

    return CalculationResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CalculationType.acceleration,
      inputValue: initialVelocity,
      velocity: finalVelocity, // Using velocity field to store final velocity
      result: acceleration,
      explanation: explanation,
      timestamp: DateTime.now(),
      unit: unit,
    );
  }

  /// Calculate time using t = (v - u)/a
  static CalculationResult calculateTime({
    required double initialVelocity,
    required double finalVelocity,
    required double acceleration,
    required String unit,
  }) {
    // Validate input
    if (acceleration == 0) {
      throw ArgumentError('Acceleration cannot be zero');
    }

    // Calculate time: t = (v - u)/a
    double time = (finalVelocity - initialVelocity) / acceleration;

    // Handle negative time (reverse direction)
    if (time < 0) {
      time = -time; // Convert to positive value
    }

    // Generate explanation
    String explanation = _generateTimeExplanation(
        initialVelocity, finalVelocity, acceleration, time, unit);

    return CalculationResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CalculationType.time,
      inputValue: initialVelocity,
      velocity: finalVelocity, // Using velocity field to store final velocity
      result: time,
      explanation: explanation,
      timestamp: DateTime.now(),
      unit: unit,
    );
  }

  static String _generateDisplacementExplanation(
    double initialVelocity,
    double acceleration,
    double time,
    double displacement,
    String unit,
  ) {
    return '''
Displacement Calculation:

Initial velocity (u): ${initialVelocity.toStringAsFixed(2)} $unit/s
Acceleration (a): ${acceleration.toStringAsFixed(2)} $unit/s²
Time (t): ${time.toStringAsFixed(2)} s

Result: ${displacement.toStringAsFixed(2)} $unit

Explanation:
Using the equation s = ut + ½at²:

• First term (ut): ${(initialVelocity * time).toStringAsFixed(2)} $unit
• Second term (½at²): ${(0.5 * acceleration * time * time).toStringAsFixed(2)} $unit
• Total displacement: ${displacement.toStringAsFixed(2)} $unit

This represents the total distance traveled in a straight line under constant acceleration.
''';
  }

  static String _generateVelocityExplanation(
    double initialVelocity,
    double acceleration,
    double time,
    double finalVelocity,
    String unit,
  ) {
    return '''
Final Velocity Calculation:

Initial velocity (u): ${initialVelocity.toStringAsFixed(2)} $unit/s
Acceleration (a): ${acceleration.toStringAsFixed(2)} $unit/s²
Time (t): ${time.toStringAsFixed(2)} s

Result: ${finalVelocity.toStringAsFixed(2)} $unit/s

Explanation:
Using the equation v = u + at:

• Change in velocity (at): ${(acceleration * time).toStringAsFixed(2)} $unit/s
• Initial velocity: ${initialVelocity.toStringAsFixed(2)} $unit/s
• Final velocity: ${finalVelocity.toStringAsFixed(2)} $unit/s

This represents the velocity of an object after accelerating for a given time.
''';
  }

  static String _generateAccelerationExplanation(
    double initialVelocity,
    double finalVelocity,
    double time,
    double acceleration,
    String unit,
  ) {
    double velocityChange = finalVelocity - initialVelocity;
    String direction = acceleration >= 0 ? "increasing" : "decreasing";

    return '''
Acceleration Calculation:

Initial velocity (u): ${initialVelocity.toStringAsFixed(2)} $unit/s
Final velocity (v): ${finalVelocity.toStringAsFixed(2)} $unit/s
Time (t): ${time.toStringAsFixed(2)} s

Result: ${acceleration.toStringAsFixed(2)} $unit/s²

Explanation:
Using the equation a = (v - u)/t:

• Change in velocity (v - u): ${velocityChange.toStringAsFixed(2)} $unit/s
• Time: ${time.toStringAsFixed(2)} s
• Acceleration: ${acceleration.toStringAsFixed(2)} $unit/s²

This represents the rate of change of velocity, with the velocity ${direction} over time.
''';
  }

  static String _generateTimeExplanation(
    double initialVelocity,
    double finalVelocity,
    double acceleration,
    double time,
    String unit,
  ) {
    double velocityChange = finalVelocity - initialVelocity;
    String direction = acceleration >= 0 ? "increasing" : "decreasing";

    return '''
Time Calculation:

Initial velocity (u): ${initialVelocity.toStringAsFixed(2)} $unit/s
Final velocity (v): ${finalVelocity.toStringAsFixed(2)} $unit/s
Acceleration (a): ${acceleration.toStringAsFixed(2)} $unit/s²

Result: ${time.toStringAsFixed(2)} s

Explanation:
Using the equation t = (v - u)/a:

• Change in velocity (v - u): ${velocityChange.toStringAsFixed(2)} $unit/s
• Acceleration: ${acceleration.toStringAsFixed(2)} $unit/s²
• Time: ${time.toStringAsFixed(2)} s

This represents the time required for the velocity to change from the initial to final value while ${direction} at a constant rate.
''';
  }

  /// Validate velocity input
  static String? validateVelocity(double velocity) {
    // Velocity can be any real number (positive or negative)
    return null; // Valid
  }

  /// Validate acceleration input
  static String? validateAcceleration(double acceleration) {
    // Acceleration can be any real number (positive or negative)
    return null; // Valid
  }

  /// Validate time input
  static String? validateTime(double time) {
    if (time < 0) {
      return 'Time cannot be negative';
    }
    return null; // Valid
  }

  /// Generate data for displacement vs time graph
  static List<Map<String, double>> generateDisplacementGraph() {
    List<Map<String, double>> data = [];

    // Using default values for initial velocity (5 m/s) and acceleration (2 m/s²)
    double initialVelocity = 5;
    double acceleration = 2;

    // Generate data points for time from 0 to 10 seconds
    for (double t = 0; t <= 10; t += 0.5) {
      double displacement =
          (initialVelocity * t) + (0.5 * acceleration * t * t);
      data.add({'x': t, 'y': displacement});
    }

    return data;
  }

  /// Generate data for velocity vs time graph
  static List<Map<String, double>> generateVelocityGraph() {
    List<Map<String, double>> data = [];

    // Using default values for initial velocity (5 m/s) and acceleration (2 m/s²)
    double initialVelocity = 5;
    double acceleration = 2;

    // Generate data points for time from 0 to 10 seconds
    for (double t = 0; t <= 10; t += 0.5) {
      double velocity = initialVelocity + (acceleration * t);
      data.add({'x': t, 'y': velocity});
    }

    return data;
  }

  /// Generate data for acceleration vs time graph
  static List<Map<String, double>> generateAccelerationGraph() {
    List<Map<String, double>> data = [];

    // Using default value for acceleration (2 m/s²)
    double acceleration = 2;

    // Generate data points for time from 0 to 10 seconds
    for (double t = 0; t <= 10; t += 0.5) {
      // Acceleration is constant
      data.add({'x': t, 'y': acceleration});
    }

    return data;
  }

  /// Generate data for time vs velocity graph
  static List<Map<String, double>> generateTimeGraph() {
    List<Map<String, double>> data = [];

    // Using default values for initial velocity (5 m/s) and acceleration (2 m/s²)
    double initialVelocity = 5;
    double acceleration = 2;

    // Generate data points for final velocity from 5 to 25 m/s
    for (double v = 5; v <= 25; v += 1) {
      double time = (v - initialVelocity) / acceleration;
      data.add({'x': v, 'y': time});
    }

    return data;
  }
}
