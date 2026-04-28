import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/car_control_data.dart';
import '../services/car_control_service.dart';
import '../services/bluetooth_service.dart';
import '../services/sensor_service.dart';

/// Provider for managing car control state and operations
///
/// This provider wraps CarControlService and provides reactive state
/// updates to the UI using ChangeNotifier pattern.

class ControlProvider extends ChangeNotifier {
  late final CarControlService _controlService;
  final SensorService _sensorService = SensorService();

  /// Current sensor data
  SensorData? _currentSensorData;

  /// Current control data
  CarControlData? _currentControlData;

  /// Flag indicating if control is active
  bool _isControlActive = false;

  /// Error message if any
  String? _errorMessage;

  /// Stream subscriptions
  StreamSubscription<bool>? _controlStateSubscription;
  StreamSubscription<CarControlData>? _controlDataSubscription;
  StreamSubscription<SensorData>? _sensorDataSubscription;

  ControlProvider(BluetoothService bluetoothService) {
    _controlService = CarControlService(bluetoothService, _sensorService);
    _initialize();
  }

  // Getters
  SensorData? get currentSensorData => _currentSensorData;
  CarControlData? get currentControlData => _currentControlData;
  bool get isControlActive => _isControlActive;
  String? get errorMessage => _errorMessage;
  bool get isCalibrated => _controlService.isCalibrated;
  Map<String, double> get neutralPosition => _controlService.neutralPosition;

  /// Initialize provider
  void _initialize() {
    // Listen to control state changes
    _controlStateSubscription = _controlService.controlStateStream.listen(
      (isActive) {
        _isControlActive = isActive;
        notifyListeners();
      },
    );

    // Listen to control data updates
    _controlDataSubscription = _controlService.controlDataStream.listen(
      (controlData) {
        _currentControlData = controlData;
        notifyListeners();
      },
    );

    // Listen to sensor data updates
    _sensorDataSubscription = _sensorService.sensorStream.listen(
      (sensorData) {
        _currentSensorData = sensorData;
        // Update control data based on sensor
        if (_isControlActive) {
          _currentControlData = _sensorService.mapToControl(sensorData);
        }
        notifyListeners();
      },
    );
  }

  /// Start reading sensors (for display only, without sending to car)
  void startSensorReading() {
    _sensorService.start();
  }

  /// Start car control
  Future<void> startControl() async {
    try {
      await _controlService.startControl();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start control: $e';
      notifyListeners();
    }
  }

  /// Stop car control
  Future<void> stopControl() async {
    try {
      await _controlService.stopControl();
      _currentSensorData = null;
      _currentControlData = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop control: $e';
      notifyListeners();
    }
  }

  /// Emergency stop - immediately stop the car
  Future<void> emergencyStop() async {
    try {
      await _controlService.emergencyStop();
      _currentSensorData = null;
      _currentControlData = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Emergency stop failed: $e';
      notifyListeners();
    }
  }

  /// Calibrate sensors to current position
  void calibrate() {
    try {
      _controlService.calibrate();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Calibration failed: $e';
      notifyListeners();
    }
  }

  /// Reset control state
  void reset() {
    _controlService.reset();
    _currentSensorData = null;
    _currentControlData = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _controlStateSubscription?.cancel();
    _controlDataSubscription?.cancel();
    _sensorDataSubscription?.cancel();
    _controlService.dispose();
    _sensorService.dispose();
    super.dispose();
  }
}
