import 'dart:math';
import '../models/sensor_data.dart';
import '../models/car_control_data.dart';
import 'constants.dart';

/// Maps accelerometer sensor data to car control values
///
/// This class implements the core algorithm for converting phone tilt
/// (pitch and roll) into X,Y control values for the Arduino car.
///
/// Features:
/// - Calibration: Store neutral position for user comfort
/// - Dead zone: Prevent jitter from small movements
/// - Sensitivity scaling: Adjustable response curve
/// - Smoothing: Exponential moving average for stable control
/// - Value clamping: Ensure values stay in valid range

class SensorMapper {
  /// Neutral pitch angle (radians) - set during calibration
  double _neutralPitch = 0.0;

  /// Neutral roll angle (radians) - set during calibration
  double _neutralRoll = 0.0;

  /// Last computed control data for smoothing
  CarControlData? _lastData;

  /// Calibrate the neutral position based on current sensor reading
  ///
  /// This allows the user to hold the phone at a comfortable angle
  /// and define that as the "neutral" position.
  ///
  /// Should be called when:
  /// - App starts
  /// - User presses calibrate button
  /// - User changes grip/holding position
  void calibrate(SensorData data) {
    _neutralPitch = data.pitch;
    _neutralRoll = data.roll;
    _lastData = null; // Reset smoothing
  }

  /// Map sensor data to car control values
  ///
  /// Algorithm steps:
  /// 1. Calculate relative tilt from neutral position
  /// 2. Apply dead zone filtering
  /// 3. Scale by sensitivity and reference angle
  /// 4. Clamp to valid range (-100 to +100)
  /// 5. Apply exponential moving average smoothing
  ///
  /// Returns: CarControlData with X, Y, Z values
  CarControlData mapSensorToControl(SensorData data) {
    // Step 1: Calculate relative tilt from neutral position
    double relativePitch = data.pitch - _neutralPitch;
    double relativeRoll = data.roll - _neutralRoll;

    // Step 2: Apply dead zone with rescaling for smooth gradient
    // After the dead zone, values start from 0 and rise gradually to max
    double pitchMapped = _applyDeadZone(relativePitch, SENSOR_DEAD_ZONE, REFERENCE_TILT_ANGLE);
    double rollMapped  = _applyDeadZone(relativeRoll,  SENSOR_DEAD_ZONE, REFERENCE_TILT_ANGLE);

    // Step 3: Map to control values with sensitivity scaling
    double yRaw = -pitchMapped * TILT_SENSITIVITY * MAX_CONTROL_VALUE;
    double xRaw =  rollMapped  * TILT_SENSITIVITY * 0.5 * MAX_CONTROL_VALUE;

    // Step 4: Clamp to valid range
    int x = xRaw.round().clamp(MIN_CONTROL_VALUE, MAX_CONTROL_VALUE);
    int y = yRaw.round().clamp(MIN_CONTROL_VALUE, MAX_CONTROL_VALUE);

    // Step 5: Apply exponential moving average smoothing
    // This reduces jitter while maintaining responsiveness
    // Formula: smoothed = new * factor + old * (1 - factor)
    if (_lastData != null) {
      x = (x * SMOOTHING_FACTOR + _lastData!.x * (1 - SMOOTHING_FACTOR))
          .round();
      y = (y * SMOOTHING_FACTOR + _lastData!.y * (1 - SMOOTHING_FACTOR))
          .round();
    }

    // Create new control data
    final newData = CarControlData(x: x, y: y, z: 0);

    // Store for next smoothing cycle
    _lastData = newData;

    return newData;
  }

  /// Reset the mapper to initial state
  void reset() {
    _neutralPitch = 0.0;
    _neutralRoll = 0.0;
    _lastData = null;
  }

  /// Get current neutral position (for debugging/display)
  Map<String, double> get neutralPosition => {
        'pitch': _neutralPitch,
        'roll': _neutralRoll,
        'pitchDegrees': _neutralPitch * 180 / pi,
        'rollDegrees': _neutralRoll * 180 / pi,
      };

  /// Check if mapper has been calibrated
  bool get isCalibrated => _neutralPitch != 0.0 || _neutralRoll != 0.0;

  /// Dead zone with rescaling: below deadZone → 0, above → smooth gradient starting from 0
  double _applyDeadZone(double value, double deadZone, double maxRange) {
    if (value.abs() < deadZone) return 0.0;
    final sign = value > 0 ? 1.0 : -1.0;
    return sign * (value.abs() - deadZone) / (maxRange - deadZone);
  }
}
