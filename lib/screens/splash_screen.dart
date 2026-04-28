import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_scan_screen.dart';
import '../utils/app_theme.dart';

/// Splash screen shown on app launch
///
/// Responsibilities:
/// - Display app branding
/// - Request necessary permissions (Bluetooth, Location, Sensors)
/// - Check Bluetooth availability
/// - Navigate to Bluetooth scan screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();

    // Setup fade animation
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Start initialization
    _initialize();
  }

  /// Initialize app and request permissions
  Future<void> _initialize() async {
    // Wait for animation
    await Future.delayed(Duration(seconds: 1));

    // Request Bluetooth permissions
    setState(() => _statusMessage = 'Requesting Bluetooth permission...');
    await _requestBluetoothPermissions();

    // Request location permission (required for Bluetooth on Android)
    setState(() => _statusMessage = 'Requesting location permission...');
    await _requestLocationPermission();

    // Request sensors permission (for accelerometer)
    setState(() => _statusMessage = 'Requesting sensor permission...');
    await _requestSensorsPermission();

    // All done
    setState(() => _statusMessage = 'Ready!');
    await Future.delayed(Duration(milliseconds: 500));

    // Navigate to Bluetooth scan screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BluetoothScanScreen()),
      );
    }
  }

  /// Request Bluetooth permissions
  Future<void> _requestBluetoothPermissions() async {
    try {
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
    } catch (e) {
      print('Error requesting Bluetooth permissions: $e');
    }
  }

  /// Request location permission (required for Bluetooth scanning on Android)
  Future<void> _requestLocationPermission() async {
    try {
      await Permission.location.request();
      await Permission.locationWhenInUse.request();
    } catch (e) {
      print('Error requesting location permission: $e');
    }
  }

  /// Request sensors permission
  Future<void> _requestSensorsPermission() async {
    try {
      await Permission.sensors.request();
    } catch (e) {
      print('Error requesting sensors permission: $e');
      // Sensors permission might not be needed on all platforms
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo
                Icon(
                  Icons.directions_car,
                  size: 120,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 24),

                // App Name
                Text(
                  'ArduCar',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  'Controller',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 24,
                        color: AppTheme.secondaryColor,
                      ),
                ),
                SizedBox(height: 48),

                // Loading indicator
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 24),

                // Status message
                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
