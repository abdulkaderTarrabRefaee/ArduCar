import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';

/// Provider for managing Bluetooth state and operations
///
/// This provider wraps BluetoothService and provides reactive state
/// updates to the UI using ChangeNotifier pattern.

class BluetoothProvider extends ChangeNotifier {
  final BluetoothService _service = BluetoothService();

  /// List of discovered devices
  List<BluetoothDevice> _discoveredDevices = [];

  /// List of bonded (paired) devices
  List<BluetoothDevice> _bondedDevices = [];

  /// Currently connected device
  BluetoothDevice? _connectedDevice;

  /// Flag indicating if device discovery is in progress
  bool _isScanning = false;

  /// Flag indicating if connection attempt is in progress
  bool _isConnecting = false;

  /// Flag indicating if Bluetooth is enabled
  bool _isBluetoothEnabled = false;

  /// Error message if any
  String? _errorMessage;

  /// Stream subscription for connection state
  StreamSubscription<bool>? _connectionStateSubscription;

  /// Stream subscription for device discovery
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;

  BluetoothProvider() {
    _initialize();
  }

  // Getters
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  List<BluetoothDevice> get bondedDevices => _bondedDevices;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _service.isConnected;
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  String? get errorMessage => _errorMessage;
  BluetoothService get service => _service;

  /// Initialize provider
  Future<void> _initialize() async {
    // Check Bluetooth availability
    _isBluetoothEnabled = await _service.isBluetoothAvailable;
    notifyListeners();

    // Listen to connection state changes
    _connectionStateSubscription = _service.connectionStateStream.listen(
      (isConnected) {
        if (!isConnected && _connectedDevice != null) {
          // Connection lost
          _handleDisconnection();
        }
        notifyListeners();
      },
    );

    // Load bonded devices
    await loadBondedDevices();
  }

  /// Check and request Bluetooth enable if needed
  Future<bool> ensureBluetoothEnabled() async {
    _isBluetoothEnabled = await _service.isBluetoothAvailable;

    if (!_isBluetoothEnabled) {
      _isBluetoothEnabled = await _service.requestBluetoothEnable();
    }

    notifyListeners();
    return _isBluetoothEnabled;
  }

  /// Load list of bonded (paired) devices
  Future<void> loadBondedDevices() async {
    try {
      _bondedDevices = await _service.getBondedDevices();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load bonded devices: $e';
      notifyListeners();
    }
  }

  /// Start scanning for Bluetooth devices
  Future<void> startScan() async {
    if (_isScanning) {
      return;
    }

    // Ensure Bluetooth is enabled
    if (!await ensureBluetoothEnabled()) {
      _errorMessage = 'Bluetooth is not enabled';
      notifyListeners();
      return;
    }

    _isScanning = true;
    _discoveredDevices.clear();
    _errorMessage = null;
    notifyListeners();

    try {
      _discoverySubscription = _service.startDiscovery().listen(
        (result) {
          // Add device if not already in list
          if (!_discoveredDevices
              .any((d) => d.address == result.device.address)) {
            _discoveredDevices.add(result.device);
            notifyListeners();
          }
        },
        onDone: () {
          _isScanning = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Scan error: $error';
          _isScanning = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to start scan: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning for devices
  void stopScan() {
    _discoverySubscription?.cancel();
    _discoverySubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a Bluetooth device
  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnecting) {
      return false;
    }

    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.connect(device);

      if (success) {
        _connectedDevice = device;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to connect to ${device.name ?? device.address}';
      }

      _isConnecting = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    await _service.disconnect();
    _handleDisconnection();
  }

  /// Handle disconnection event
  void _handleDisconnection() {
    _connectedDevice = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
