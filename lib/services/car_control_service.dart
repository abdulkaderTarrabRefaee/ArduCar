import 'dart:async';
import '../models/sensor_data.dart';
import '../models/car_control_data.dart';
import 'bluetooth_service.dart';
import 'sensor_service.dart';
import '../utils/constants.dart';

/// Service that orchestrates sensor reading and car control
///
/// This service:
/// - Coordinates SensorService and BluetoothService
/// - Implements 10Hz update loop for sending control data
/// - Provides start/stop/emergency stop functionality
/// - Handles safety timeouts and error conditions

class CarControlService {
  final BluetoothService _bluetoothService;
  final SensorService _sensorService;

  /// Timer for periodic data transmission
  Timer? _sendTimer;

  /// Subscription to sensor data stream
  StreamSubscription<SensorData>? _sensorSubscription;

  /// Flag indicating if control is currently active
  bool _isControlActive = false;

  /// Latest control data for tracking
  CarControlData? _lastSentData;

  /// Timestamp of last successful send
  DateTime? _lastSendTime;

  /// Stream controller for control state changes
  final StreamController<bool> _controlStateController =
      StreamController<bool>.broadcast();

  /// Stream controller for current control data
  final StreamController<CarControlData> _controlDataController =
      StreamController<CarControlData>.broadcast();

  CarControlService(this._bluetoothService, this._sensorService);

  /// Get control state stream
  Stream<bool> get controlStateStream => _controlStateController.stream;

  /// Get control data stream
  Stream<CarControlData> get controlDataStream =>
      _controlDataController.stream;

  /// Check if control is currently active
  bool get isControlActive => _isControlActive;

  /// Get the last sent control data
  CarControlData? get lastSentData => _lastSentData;

  /// Start the control loop
  ///
  /// This will:
  /// 1. Start reading sensor data
  /// 2. Begin periodic transmission of control data at 10Hz
  /// 3. Enable safety monitoring
  Future<void> startControl() async {
    if (_isControlActive) {
      print('Control already active');
      return;
    }

    if (!_bluetoothService.isConnected) {
      print('Cannot start control: Bluetooth not connected');
      return;
    }

    print('Starting car control...');

    // Start sensor service
    _sensorService.start();

    // Subscribe to sensor data (for monitoring, actual sending is timer-based)
    _sensorSubscription = _sensorService.sensorStream.listen(
      (sensorData) {
        // Sensor data received - it will be read by timer
      },
      onError: (error) {
        print('Sensor error: $error');
      },
    );

    // Start periodic timer for sending control data
    _sendTimer = Timer.periodic(
      Duration(milliseconds: DATA_SEND_INTERVAL),
      (timer) {
        _sendControlData();
      },
    );

    _isControlActive = true;
    _controlStateController.add(true);

    print('Car control started (${1000 / DATA_SEND_INTERVAL}Hz update rate)');
  }

  /// Stop the control loop
  Future<void> stopControl() async {
    if (!_isControlActive) {
      return;
    }

    print('Stopping car control...');

    // Cancel timer
    _sendTimer?.cancel();
    _sendTimer = null;

    // Cancel sensor subscription
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;

    // Stop sensor service
    _sensorService.stop();

    // Send stop command to Arduino
    await _bluetoothService.sendStopCommand();

    _isControlActive = false;
    _lastSentData = null;
    _lastSendTime = null;
    _controlStateController.add(false);

    print('Car control stopped');
  }

  /// Emergency stop - immediately stop the car
  Future<void> emergencyStop() async {
    print('EMERGENCY STOP!');

    // Immediately send stop command
    await _bluetoothService.sendStopCommand();

    // Then stop the control loop
    await stopControl();
  }

  /// Send current control data to Arduino
  ///
  /// This method is called by the periodic timer
  void _sendControlData() {
    // Check if still connected
    if (!_bluetoothService.isConnected) {
      print('Connection lost - stopping control');
      stopControl();
      return;
    }

    // Get latest sensor data
    final sensorData = _sensorService.latestSensorData;
    if (sensorData == null) {
      // No sensor data yet, skip this cycle
      return;
    }

    // Map sensor data to control values
    final controlData = _sensorService.mapToControl(sensorData);

    // Send to Arduino
    _bluetoothService.sendControlData(controlData).then((success) {
      if (success) {
        _lastSentData = controlData;
        _lastSendTime = DateTime.now();
        _controlDataController.add(controlData);
      } else {
        print('Failed to send control data');
      }
    });
  }

  /// Calibrate sensor neutral position
  void calibrate() {
    _sensorService.calibrate();
    print('Sensors calibrated to current position');
  }

  /// Reset everything to initial state
  void reset() {
    _sensorService.reset();
    _lastSentData = null;
    _lastSendTime = null;
  }

  /// Get current sensor calibration status
  bool get isCalibrated => _sensorService.isCalibrated;

  /// Get neutral position values (for display)
  Map<String, double> get neutralPosition => _sensorService.neutralPosition;

  /// Dispose of resources
  void dispose() {
    stopControl();
    _controlStateController.close();
    _controlDataController.close();
  }
}
