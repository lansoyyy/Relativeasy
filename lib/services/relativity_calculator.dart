import 'dart:math' as math;
import '../models/calculation_result.dart';
import '../utils/const.dart';

class RelativityCalculator {
  static const double c = speedOfLight; // Speed of light in m/s

  /// Calculate time dilation using the Lorentz factor
  /// Δt = Δt₀ / √(1 - v²/c²)
  static CalculationResult calculateTimeDilation({
    required double properTime,
    required double velocity, // as fraction of c (0 to 0.99)
    required String unit,
  }) {
    // Validate input
    if (velocity >= 1.0) {
      throw ArgumentError('Velocity cannot exceed the speed of light');
    }
    if (velocity < 0) {
      throw ArgumentError('Velocity cannot be negative');
    }
    if (properTime <= 0) {
      throw ArgumentError('Time must be positive');
    }

    // Calculate Lorentz factor: γ = 1 / √(1 - v²/c²)
    double vSquaredOverCSquared = velocity * velocity;
    double lorentzFactor = 1.0 / math.sqrt(1.0 - vSquaredOverCSquared);

    // Calculate dilated time
    double dilatedTime = properTime * lorentzFactor;

    // Generate explanation
    String explanation = _generateTimeDilationExplanation(
        properTime, velocity, dilatedTime, lorentzFactor, unit);

    return CalculationResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CalculationType.timeDilation,
      inputValue: properTime,
      velocity: velocity,
      result: dilatedTime,
      explanation: explanation,
      timestamp: DateTime.now(),
      unit: unit,
    );
  }

  /// Calculate length contraction using the Lorentz factor
  /// L = L₀ × √(1 - v²/c²)
  static CalculationResult calculateLengthContraction({
    required double properLength,
    required double velocity, // as fraction of c (0 to 0.99)
    required String unit,
  }) {
    // Validate input
    if (velocity >= 1.0) {
      throw ArgumentError('Velocity cannot exceed the speed of light');
    }
    if (velocity < 0) {
      throw ArgumentError('Velocity cannot be negative');
    }
    if (properLength <= 0) {
      throw ArgumentError('Length must be positive');
    }

    // Calculate length contraction factor: √(1 - v²/c²)
    double vSquaredOverCSquared = velocity * velocity;
    double contractionFactor = math.sqrt(1.0 - vSquaredOverCSquared);

    // Calculate contracted length
    double contractedLength = properLength * contractionFactor;

    // Generate explanation
    String explanation = _generateLengthContractionExplanation(
        properLength, velocity, contractedLength, contractionFactor, unit);

    return CalculationResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CalculationType.lengthContraction,
      inputValue: properLength,
      velocity: velocity,
      result: contractedLength,
      explanation: explanation,
      timestamp: DateTime.now(),
      unit: unit,
    );
  }

  /// Calculate relativistic velocity given time dilation factor
  static double calculateVelocityFromTimeDilation(double timeDilationFactor) {
    if (timeDilationFactor < 1.0) {
      throw ArgumentError('Time dilation factor must be ≥ 1');
    }

    // From γ = 1 / √(1 - v²/c²), solve for v
    // v = c × √(1 - 1/γ²)
    double gamma = timeDilationFactor;
    double velocityFraction = math.sqrt(1.0 - 1.0 / (gamma * gamma));

    return velocityFraction;
  }

  /// Calculate relativistic velocity given length contraction factor
  static double calculateVelocityFromLengthContraction(
      double contractionFactor) {
    if (contractionFactor > 1.0 || contractionFactor <= 0.0) {
      throw ArgumentError('Length contraction factor must be between 0 and 1');
    }

    // From L/L₀ = √(1 - v²/c²), solve for v
    // v = c × √(1 - (L/L₀)²)
    double velocityFraction =
        math.sqrt(1.0 - contractionFactor * contractionFactor);

    return velocityFraction;
  }

  /// Generate data points for velocity vs time dilation graph
  static List<Map<String, double>> generateTimeDilationGraph({
    int points = 100,
    double maxVelocity = 0.99,
  }) {
    List<Map<String, double>> dataPoints = [];

    for (int i = 0; i <= points; i++) {
      double velocity = (i / points) * maxVelocity;
      double gamma = 1.0 / math.sqrt(1.0 - velocity * velocity);

      dataPoints.add({
        'velocity': velocity,
        'dilation': gamma,
      });
    }

    return dataPoints;
  }

  /// Generate data points for velocity vs length contraction graph
  static List<Map<String, double>> generateLengthContractionGraph({
    int points = 100,
    double maxVelocity = 0.99,
  }) {
    List<Map<String, double>> dataPoints = [];

    for (int i = 0; i <= points; i++) {
      double velocity = (i / points) * maxVelocity;
      double contraction = math.sqrt(1.0 - velocity * velocity);

      dataPoints.add({
        'velocity': velocity,
        'contraction': contraction,
      });
    }

    return dataPoints;
  }

  static String _generateTimeDilationExplanation(
    double properTime,
    double velocity,
    double dilatedTime,
    double lorentzFactor,
    String unit,
  ) {
    double velocityPercent = velocity * 100;
    double timeDifference = dilatedTime - properTime;

    return '''
Time Dilation Calculation:

Initial time (proper time): ${properTime.toStringAsFixed(2)} $unit
Velocity: ${velocityPercent.toStringAsFixed(1)}% of light speed
Lorentz factor (γ): ${lorentzFactor.toStringAsFixed(3)}

Result: ${dilatedTime.toStringAsFixed(2)} $unit

Explanation:
When traveling at ${velocityPercent.toStringAsFixed(1)}% the speed of light, time passes ${lorentzFactor.toStringAsFixed(2)}x slower for the moving observer. This means that while ${properTime.toStringAsFixed(1)} $unit pass for the traveler, ${dilatedTime.toStringAsFixed(1)} $unit pass for a stationary observer.

The difference is ${timeDifference.toStringAsFixed(2)} $unit - this is the "time gained" by traveling at relativistic speeds!
''';
  }

  static String _generateLengthContractionExplanation(
    double properLength,
    double velocity,
    double contractedLength,
    double contractionFactor,
    String unit,
  ) {
    double velocityPercent = velocity * 100;
    double lengthReduction = properLength - contractedLength;
    double reductionPercent = (lengthReduction / properLength) * 100;

    return '''
Length Contraction Calculation:

Proper length (rest frame): ${properLength.toStringAsFixed(2)} $unit
Velocity: ${velocityPercent.toStringAsFixed(1)}% of light speed
Contraction factor: ${contractionFactor.toStringAsFixed(3)}

Result: ${contractedLength.toStringAsFixed(2)} $unit

Explanation:
When moving at ${velocityPercent.toStringAsFixed(1)}% the speed of light, the object appears ${reductionPercent.toStringAsFixed(1)}% shorter in the direction of motion to a stationary observer.

The object contracts from ${properLength.toStringAsFixed(1)} $unit to ${contractedLength.toStringAsFixed(1)} $unit - a reduction of ${lengthReduction.toStringAsFixed(2)} $unit!

This effect only occurs in the direction of motion; perpendicular dimensions remain unchanged.
''';
  }

  /// Validate velocity input and provide user-friendly error messages
  static String? validateVelocity(double velocity) {
    if (velocity < 0) {
      return 'Velocity cannot be negative';
    }
    if (velocity >= 1.0) {
      return 'Velocity cannot exceed the speed of light (100% c)';
    }
    if (velocity < 0.01) {
      return 'Velocity too small - relativistic effects are negligible below 1% c';
    }
    return null; // Valid
  }

  /// Validate time/length input
  static String? validatePositiveValue(double value, String fieldName) {
    if (value <= 0) {
      return '$fieldName must be positive';
    }
    if (value > 1e10) {
      return '$fieldName is too large';
    }
    return null; // Valid
  }
}
