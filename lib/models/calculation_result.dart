class CalculationResult {
  final String id;
  final CalculationType type;
  final double inputValue;
  final double velocity; // as fraction of c
  final double result;
  final String explanation;
  final DateTime timestamp;
  final String unit;

  CalculationResult({
    required this.id,
    required this.type,
    required this.inputValue,
    required this.velocity,
    required this.result,
    required this.explanation,
    required this.timestamp,
    required this.unit,
  });

  factory CalculationResult.fromJson(Map<String, dynamic> json) {
    return CalculationResult(
      id: json['id'],
      type: CalculationType.values[json['type']],
      inputValue: json['inputValue'].toDouble(),
      velocity: json['velocity'].toDouble(),
      result: json['result'].toDouble(),
      explanation: json['explanation'],
      timestamp: DateTime.parse(json['timestamp']),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'inputValue': inputValue,
      'velocity': velocity,
      'result': result,
      'explanation': explanation,
      'timestamp': timestamp.toIso8601String(),
      'unit': unit,
    };
  }

  @override
  String toString() {
    return 'CalculationResult(type: $type, input: $inputValue $unit, velocity: ${(velocity * 100).toStringAsFixed(1)}%c, result: ${result.toStringAsFixed(3)} $unit)';
  }
}

enum CalculationType {
  timeDilation,
  lengthContraction,
}

extension CalculationTypeExtension on CalculationType {
  String get displayName {
    switch (this) {
      case CalculationType.timeDilation:
        return 'Time Dilation';
      case CalculationType.lengthContraction:
        return 'Length Contraction';
    }
  }

  String get formula {
    switch (this) {
      case CalculationType.timeDilation:
        return 'Δt = Δt₀ / √(1 - v²/c²)';
      case CalculationType.lengthContraction:
        return 'L = L₀ × √(1 - v²/c²)';
    }
  }

  String get description {
    switch (this) {
      case CalculationType.timeDilation:
        return 'Time passes slower for objects moving at high speeds relative to a stationary observer.';
      case CalculationType.lengthContraction:
        return 'Objects appear shorter in the direction of motion when moving at high speeds.';
    }
  }
}
