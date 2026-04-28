import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/car_control_data.dart';

/// Service for managing Bluetooth communication with Arduino HC-05 module
///
/// This service handles:
/// - Device discovery and scanning
/// - Connection management
/// - Command transmission in "X,Y,Z" format
/// - Disconnection and cleanup

class BluetoothService {
  /// Bluetooth connection instance
  BluetoothConnection? _connection;

  /// Flag indicating if currently connected
  bool _isConnected = false;

  /// Currently connected device
  BluetoothDevice? _connectedDevice;

  /// Stream controller for connection state changes
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  /// Get connection state stream
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Check if Bluetooth is available on device
  Future<bool> get isBluetoothAvailable async {
    try {
      final state = await FlutterBluetoothSerial.instance.state;
      return state == BluetoothState.STATE_ON;
    } catch (e) {
      print('Error checking Bluetooth state: $e');
      return false;
    }
  }

  /// Request to enable Bluetooth if it's off
  Future<bool> requestBluetoothEnable() async {
    try {
      return await FlutterBluetoothSerial.instance.requestEnable() ?? false;
    } catch (e) {
      print('Error requesting Bluetooth enable: $e');
      return false;
    }
  }

  /// Start discovering Bluetooth devices
  ///
  /// Returns a stream of discovered devices
  Stream<BluetoothDiscoveryResult> startDiscovery() {
    return FlutterBluetoothSerial.instance.startDiscovery();
  }

  /// Get list of bonded (paired) devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print('Error getting bonded devices: $e');
      return [];
    }
  }

  /// Connect to a Bluetooth device by address
  ///
  /// Returns true if connection successful, false otherwise
  Future<bool> connectToDevice(String address) async {
    try {
      // Disconnect if already connected
      if (_isConnected) {
        await disconnect();
      }

      print('Attempting to connect to $address...');

      // Create connection to device with timeout
      _connection = await BluetoothConnection.toAddress(address);

      // Wait a moment for connection to stabilize
      await Future.delayed(Duration(milliseconds: 500));

      print('Connected successfully!');

      _isConnected = true;
      _connectionStateController.add(true);

      // Listen for incoming data (optional, for debugging)
      _connection!.input?.listen(
        (data) {
          print('Received from Arduino: ${String.fromCharCodes(data)}');
        },
        onDone: () {
          print('Connection closed by remote device');
          _handleDisconnection();
        },
        onError: (error) {
          print('Connection error: $error');
          _handleDisconnection();
        },
      );

      return true;
    } catch (e) {
      print('Connection failed: $e');
      _isConnected = false;
      _connectionStateController.add(false);
      return false;
    }
  }

  /// Connect to a Bluetooth device object
  Future<bool> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    return await connectToDevice(device.address);
  }

  /// Send a command string to Arduino
  ///
  /// Command format: "X,Y,Z\n" where X, Y, Z are integers
  Future<bool> sendCommand(String command) async {
    if (!_isConnected || _connection == null) {
      print('Cannot send command: not connected');
      return false;
    }

    try {
      // Add newline if not present (Arduino expects line-terminated commands)
      if (!command.endsWith('\n')) {
        command += '\n';
      }

      // Convert string to bytes
      final bytes = Uint8List.fromList(utf8.encode(command));

      // Send to Arduino - simpler approach like Serial Bluetooth Terminal
      _connection!.output.add(bytes);

      // Small delay to ensure data is sent
      await Future.delayed(Duration(milliseconds: 10));

      print('Sent: $command');
      return true;
    } catch (e) {
      print('Error sending command: $e');
      _handleDisconnection();
      return false;
    }
  }

  /// Send car control data to Arduino
  Future<bool> sendControlData(CarControlData data) async {
    return await sendCommand(data.toArduinoCommand());
  }

  /// Send stop command (0,0,0) to Arduino
  ///
  /// This is a safety feature to ensure car stops
  Future<bool> sendStopCommand() async {
    print('Sending stop command...');
    return await sendCommand('0,0,0');
  }

  /// Send keyboard command to Arduino (W, A, S, D, C)
  ///
  /// W = forward, S = backward, A = right, D = left, C = stop
  Future<bool> sendKeyboardCommand(String key) async {
    if (!_isConnected || _connection == null) {
      print('Cannot send keyboard command: not connected');
      return false;
    }

    try {
      // Arduino expects single character followed by newline
      final command = '${key.toLowerCase()}\n';
      final bytes = Uint8List.fromList(utf8.encode(command));

      _connection!.output.add(bytes);

      // Small delay to ensure data is sent
      await Future.delayed(Duration(milliseconds: 10));

      print('Sent key: $key');
      return true;
    } catch (e) {
      print('Error sending keyboard command: $e');
      return false;
    }
  }

  /// Handle disconnection event
  void _handleDisconnection() {
    if (_isConnected) {
      print('Bluetooth disconnected');
      _isConnected = false;
      _connection = null;
      _connectedDevice = null;
      _connectionStateController.add(false);
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_connection == null || !_isConnected) {
      return;
    }

    try {
      // Send stop command before disconnecting (safety)
      await sendStopCommand();

      // Wait a moment for command to be sent
      await Future.delayed(Duration(milliseconds: 200));

      // Close connection
      _connection!.finish();
      await _connection!.close();
    } catch (e) {
      print('Error during disconnect: $e');
    } finally {
      _handleDisconnection();
    }
  }

  /// Get connection status
  bool get isConnected => _isConnected;

  /// Get currently connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Dispose of resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
  }
}
