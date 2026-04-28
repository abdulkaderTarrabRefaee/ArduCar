import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/control_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/keyboard_control.dart';

class CarControlScreen extends StatefulWidget {
  const CarControlScreen({Key? key}) : super(key: key);

  @override
  State<CarControlScreen> createState() => _CarControlScreenState();
}

class _CarControlScreenState extends State<CarControlScreen>
    with WidgetsBindingObserver {
  bool _useButtonControl = false; // false = tilt control, true = button control

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Force portrait orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Start reading sensor data immediately for display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controlProvider = context.read<ControlProvider>();
      // Start sensor service for display (without sending to car)
      controlProvider.startSensorReading();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    // Stop control when leaving screen
    context.read<ControlProvider>().stopControl();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background - emergency stop
      context.read<ControlProvider>().emergencyStop();
    }
  }

  Future<bool> _onWillPop() async {
    try {
      // Stop control and disconnect before leaving
      await context.read<ControlProvider>().stopControl();
      await context.read<BluetoothProvider>().disconnect();
    } catch (e) {
      print('Error during back navigation disconnect: $e');
      // Continue anyway - allow user to exit
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('ArduCar'),
          actions: [
            // Connection indicator
            Consumer<BluetoothProvider>(
              builder: (context, btProvider, _) => Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  btProvider.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: btProvider.isConnected
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
            ),
          ],
        ),
        body: Consumer2<BluetoothProvider, ControlProvider>(
          builder: (context, btProvider, controlProvider, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Connection status
                  _buildConnectionCard(btProvider),
                  SizedBox(height: 16),

                  // Control mode switcher
                  _buildControlModeSwitcher(),
                  SizedBox(height: 16),

                  // Show either tilt sensor display or button controls
                  if (!_useButtonControl) ...[
                    // Sensor display (Tilt mode)
                    _buildSensorCard(controlProvider),
                    SizedBox(height: 16),

                    // Tilt control buttons
                    _buildControlButtons(controlProvider),
                  ] else ...[
                    // Button controls (Keyboard mode)
                    KeyboardControl(
                      bluetoothService: btProvider.service,
                    ),
                  ],

                  SizedBox(height: 24),

                  // Emergency stop (always visible)
                  _buildEmergencyStop(controlProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlModeSwitcher() {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Control Mode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Icon(
                  Icons.screen_rotation,
                  size: 20,
                  color: !_useButtonControl
                      ? AppTheme.primaryColor
                      : Colors.grey,
                ),
                SizedBox(width: 8),
                Switch(
                  value: _useButtonControl,
                  onChanged: (value) {
                    setState(() => _useButtonControl = value);
                    // Stop tilt control when switching to button mode
                    if (value) {
                      context.read<ControlProvider>().stopControl();
                    }
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.gamepad,
                  size: 20,
                  color: _useButtonControl
                      ? AppTheme.primaryColor
                      : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BluetoothProvider provider) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.devices, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connected to',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    provider.connectedDevice?.name ?? 'Unknown Device',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                try {
                  // Stop control and disconnect
                  await context.read<ControlProvider>().stopControl();
                  await provider.disconnect();
                } catch (e) {
                  print('Error during disconnect: $e');
                }

                // Close loading dialog
                if (mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to scan screen
                }
              },
              child: Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(ControlProvider provider) {
    final sensorData = provider.currentSensorData;
    final controlData = provider.currentControlData;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Sensor Data',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            if (sensorData != null) ...[
              _buildSensorRow(
                  'Pitch', sensorData.pitchDegrees, controlData?.y ?? 0),
              SizedBox(height: 12),
              _buildSensorRow(
                  'Roll', sensorData.rollDegrees, controlData?.x ?? 0),
            ] else
              Text('No sensor data', style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 16),
            if (controlData != null)
              Text(
                'Command: ${controlData.toArduinoCommand()}',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, double angle, int controlValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text('${angle.toStringAsFixed(1)}°',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: (controlValue + 100) / 200, // Map -100:100 to 0:1
          backgroundColor: Colors.white24,
          color: controlValue >= 0 ? AppTheme.successColor : AppTheme.errorColor,
          minHeight: 8,
        ),
        SizedBox(height: 4),
        Text('Control: $controlValue',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildControlButtons(ControlProvider provider) {
    return Column(
      children: [
        // Start/Stop control
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (provider.isControlActive) {
                provider.stopControl();
              } else {
                provider.startControl();
              }
            },
            icon: Icon(provider.isControlActive ? Icons.stop : Icons.play_arrow),
            label: Text(
                provider.isControlActive ? 'STOP CONTROL' : 'START CONTROL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.isControlActive
                  ? AppTheme.warningColor
                  : AppTheme.successColor,
              padding: EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        SizedBox(height: 12),

        // Calibrate button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              provider.calibrate();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sensors calibrated!')),
              );
            },
            icon: Icon(Icons.settings_backup_restore),
            label: Text('CALIBRATE'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyStop(ControlProvider provider) {
    return Container(
      width: double.infinity,
      height: 120,
      child: ElevatedButton(
        onPressed: () async {
          await provider.emergencyStop();
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('EMERGENCY STOP ACTIVATED'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pan_tool, size: 48, color: Colors.white),
            SizedBox(height: 8),
            Text(
              'EMERGENCY STOP',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
