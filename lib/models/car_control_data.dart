import 'dart:math' as math;
import '../utils/constants.dart';

/// Model class for car control values sent to Arduino

class CarControlData {
  /// X-axis control value (steering)
  /// Range: -100 (full left) to +100 (full right)
  /// 0 = straight
  final int x;

  /// Y-axis control value (forward/backward speed)
  /// Range: -100 (full backward) to +100 (full forward)
  /// 0 = stopped
  final int y;

  /// Z-axis control value (currently unused)
  /// Always 0 for this implementation
  final int z;

  CarControlData({
    required this.x,
    required this.y,
    this.z = 0,
  })  : assert(x >= MIN_CONTROL_VALUE && x <= MAX_CONTROL_VALUE,
            'X must be between $MIN_CONTROL_VALUE and $MAX_CONTROL_VALUE'),
        assert(y >= MIN_CONTROL_VALUE && y <= MAX_CONTROL_VALUE,
            'Y must be between $MIN_CONTROL_VALUE and $MAX_CONTROL_VALUE');

  /// Factory constructor for neutral/stopped position
  factory CarControlData.neutral() {
    return CarControlData(x: 0, y: 0, z: 0);
  }

  /// Convert to Arduino command format: "X,Y,Z"
  /// This is the format expected by the Arduino HC-05 receiver
  String toArduinoCommand() {
    return '$x,$y,$z';
  }

  /// Check if this represents a neutral/stopped position
  bool get isNeutral => x == 0 && y == 0;

  /// Check if car is moving forward
  bool get isMovingForward => y > 0;

  /// Check if car is moving backward
  bool get isMovingBackward => y < 0;

  /// Check if car is turning left
  bool get isTurningLeft => x < 0;

  /// Check if car is turning right
  bool get isTurningRight => x > 0;

  /// Get the magnitude of movement (0 to 100)
  double get magnitude {
    return (x * x + y * y).toDouble() / 100.0;
  }

  /// Get direction angle in degrees (0° = forward, 90° = right, etc.)
  double get directionDegrees {
    if (isNeutral) return 0;
    // atan2 returns angle in radians, convert to degrees
    // Note: Y is forward, X is right in car coordinates
    final angleRad = math.atan2(x.toDouble(), y.toDouble());
    return angleRad * 180 / 3.14159;
  }

  /// Create a copy with optional field updates
  CarControlData copyWith({
    int? x,
    int? y,
    int? z,
  }) {
    return CarControlData(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
    );
  }

  /// Convert to JSON for debugging/logging
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'command': toArduinoCommand(),
      'isNeutral': isNeutral,
    };
  }

  @override
  String toString() {
    return 'CarControlData(X: $x, Y: $y, Z: $z) => "${toArduinoCommand()}"';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarControlData &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);
}
