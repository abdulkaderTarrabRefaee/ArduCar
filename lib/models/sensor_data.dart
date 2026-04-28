/// Model class for accelerometer sensor data with calculated orientation values

class SensorData {
  /// Pitch angle in radians (forward/backward tilt)
  /// Positive = tilting forward, Negative = tilting backward
  final double pitch;

  /// Roll angle in radians (left/right tilt)
  /// Positive = tilting right, Negative = tilting left
  final double roll;

  /// Raw accelerometer X-axis value (left/right)
  final double rawX;

  /// Raw accelerometer Y-axis value (forward/backward)
  final double rawY;

  /// Raw accelerometer Z-axis value (up/down / gravity)
  final double rawZ;

  /// Timestamp when this sensor data was captured
  final DateTime timestamp;

  SensorData({
    required this.pitch,
    required this.roll,
    required this.rawX,
    required this.rawY,
    required this.rawZ,
    required this.timestamp,
  });

  /// Convert pitch from radians to degrees for display
  double get pitchDegrees => pitch * 180 / 3.14159;

  /// Convert roll from radians to degrees for display
  double get rollDegrees => roll * 180 / 3.14159;

  /// Create a copy of this sensor data with optional field updates
  SensorData copyWith({
    double? pitch,
    double? roll,
    double? rawX,
    double? rawY,
    double? rawZ,
    DateTime? timestamp,
  }) {
    return SensorData(
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      rawX: rawX ?? this.rawX,
      rawY: rawY ?? this.rawY,
      rawZ: rawZ ?? this.rawZ,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert sensor data to JSON for debugging/logging
  Map<String, dynamic> toJson() {
    return {
      'pitch': pitch,
      'roll': roll,
      'pitchDegrees': pitchDegrees,
      'rollDegrees': rollDegrees,
      'rawX': rawX,
      'rawY': rawY,
      'rawZ': rawZ,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SensorData(pitch: ${pitchDegrees.toStringAsFixed(1)}°, '
        'roll: ${rollDegrees.toStringAsFixed(1)}°, '
        'raw: [${ rawX.toStringAsFixed(2)}, ${rawY.toStringAsFixed(2)}, ${rawZ.toStringAsFixed(2)}])';
  }
}
