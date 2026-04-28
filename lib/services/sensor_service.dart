import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';
import '../utils/sensor_mapper.dart';
import '../models/car_control_data.dart';

/// Service for reading and processing accelerometer data
///
/// This service:
/// - Subscribes to device accelerometer stream
/// - Calculates pitch and roll angles from raw accelerometer values
/// - Provides calibration functionality through SensorMapper
/// - Transforms sensor data into car control values

class SensorService {
  /// Stream subscription for accelerometer events
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  /// Stream controller for processed sensor data
  final StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();

  /// Sensor mapper for converting sensor data to control values
  final SensorMapper _mapper = SensorMapper();

  /// Latest sensor data reading
  SensorData? _latestSensorData;

  /// Latest control data from mapping
  CarControlData? _latestControlData;

  /// Get the sensor data stream
  Stream<SensorData> get sensorStream => _sensorDataController.stream;

  /// Get the latest sensor data (if available)
  SensorData? get latestSensorData => _latestSensorData;

  /// Get the latest control data (if available)
  CarControlData? get latestControlData => _latestControlData;

  /// Start listening to accelerometer events
  void start() {
    // Cancel existing subscription if any
    stop();

    // Subscribe to accelerometer events from sensors_plus package
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Process the raw accelerometer data
        final sensorData = _processAccelerometerEvent(event);

        // Store latest data
        _latestSensorData = sensorData;

        // Also update control data
        _latestControlData = _mapper.mapSensorToControl(sensorData);

        // Emit to stream
        _sensorDataController.add(sensorData);
      },
      onError: (error) {
        print('Error reading accelerometer: $error');
      },
    );
  }

  /// Stop listening to accelerometer events
  void stop() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  /// Process raw accelerometer event and calculate pitch/roll
  ///
  /// Accelerometer axes (when phone is upright in portrait):
  /// - X: Left/Right (negative = left, positive = right)
  /// - Y: Forward/Backward (negative = backward, positive = forward)
  /// - Z: Up/Down (negative = down, positive = up, ~9.8 when flat)
  ///
  /// Pitch: Rotation around X-axis (forward/backward tilt)
  /// Roll: Rotation around Y-axis (left/right tilt)
  SensorData _processAccelerometerEvent(AccelerometerEvent event) {
    final x = event.x;
    final y = event.y;
    final z = event.z;

    // Calculate pitch (forward/backward tilt)
    // Formula: pitch = atan2(y, sqrt(x² + z²))
    // Positive pitch = tilting forward
    final pitch = atan2(y, sqrt(x * x + z * z));

    // Calculate roll (left/right tilt)
    // Formula: roll = atan2(-x, sqrt(y² + z²))
    // Positive roll = tilting right
    final roll = atan2(-x, sqrt(y * y + z * z));

    return SensorData(
      pitch: pitch,
      roll: roll,
      rawX: x,
      rawY: y,
      rawZ: z,
      timestamp: DateTime.now(),
    );
  }

  /// Calibrate the neutral position using current sensor reading
  void calibrate() {
    if (_latestSensorData != null) {
      _mapper.calibrate(_latestSensorData!);
    }
  }

  /// Calibrate using provided sensor data
  void calibrateWith(SensorData data) {
    _mapper.calibrate(data);
  }

  /// Map sensor data to control values
  CarControlData mapToControl(SensorData data) {
    return _mapper.mapSensorToControl(data);
  }

  /// Get current neutral position (for display/debugging)
  Map<String, double> get neutralPosition => _mapper.neutralPosition;

  /// Check if mapper has been calibrated
  bool get isCalibrated => _mapper.isCalibrated;

  /// Reset calibration and smoothing
  void reset() {
    _mapper.reset();
    _latestSensorData = null;
    _latestControlData = null;
  }

  /// Dispose of resources
  void dispose() {
    stop();
    _sensorDataController.close();
  }
}
