import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bluetooth_service.dart';
import '../utils/app_theme.dart';

/// Widget for keyboard-based car control using W, A, S, D keys
///
/// This provides an alternative to tilt control with visual buttons
/// that send keyboard commands to Arduino

class KeyboardControl extends StatefulWidget {
  final BluetoothService bluetoothService;

  const KeyboardControl({
    Key? key,
    required this.bluetoothService,
  }) : super(key: key);

  @override
  State<KeyboardControl> createState() => _KeyboardControlState();
}

class _KeyboardControlState extends State<KeyboardControl> {
  String? _activeKey;
  Timer? _sendTimer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Button Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Press and hold buttons to move',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 24),

            // Button layout
            Column(
              children: [
                // Forward button (W)
                _buildControlButton(
                  key: 'w',
                  label: 'W',
                  icon: Icons.arrow_upward,
                  tooltip: 'Forward',
                ),
                SizedBox(height: 12),

                // Left, Stop, Right buttons (A, C, D)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left button (A) - Note: In Arduino code A is right
                    _buildControlButton(
                      key: 'a',
                      label: 'A',
                      icon: Icons.arrow_back,
                      tooltip: 'Turn Right',
                    ),
                    SizedBox(width: 12),

                    // Stop button (C)
                    _buildStopButton(),
                    SizedBox(width: 12),

                    // Right button (D) - Note: In Arduino code D is left
                    _buildControlButton(
                      key: 'd',
                      label: 'D',
                      icon: Icons.arrow_forward,
                      tooltip: 'Turn Left',
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Backward button (S)
                _buildControlButton(
                  key: 's',
                  label: 'S',
                  icon: Icons.arrow_downward,
                  tooltip: 'Backward',
                ),
              ],
            ),

            SizedBox(height: 16),

            // Instructions
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('W - Forward', style: TextStyle(fontSize: 12)),
                      Text('S - Backward', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('A - Turn Right', style: TextStyle(fontSize: 12)),
                      Text('D - Turn Left', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('C - Stop', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String key,
    required String label,
    required IconData icon,
    required String tooltip,
  }) {
    final isActive = _activeKey == key;

    return Listener(
      onPointerDown: (_) => _onKeyDown(key),
      onPointerUp: (_) => _onKeyUp(),
      onPointerCancel: (_) => _onKeyUp(),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withAlpha(128),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isActive ? Colors.black : AppTheme.primaryColor,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: () => _sendStopCommand(),
      child: Tooltip(
        message: 'Stop',
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.errorColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorColor.withAlpha(77),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.stop,
                size: 32,
                color: Colors.white,
              ),
              SizedBox(height: 4),
              Text(
                'C',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onKeyDown(String key) {
    // Cancel any existing timer
    _sendTimer?.cancel();

    setState(() => _activeKey = key);
    HapticFeedback.lightImpact();

    // Send command immediately
    widget.bluetoothService.sendKeyboardCommand(key);

    // Start timer to send command repeatedly (2 times per second = 500ms)
    _sendTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_activeKey == key) {
        widget.bluetoothService.sendKeyboardCommand(key);
      }
    });
  }

  void _onKeyUp() {
    // Cancel timer
    _sendTimer?.cancel();
    _sendTimer = null;

    if (_activeKey != null) {
      setState(() => _activeKey = null);
      // Send stop command when button is released
      widget.bluetoothService.sendKeyboardCommand('c');
    }
  }

  void _sendStopCommand() {
    // Cancel any active timer
    _sendTimer?.cancel();
    _sendTimer = null;

    HapticFeedback.mediumImpact();
    widget.bluetoothService.sendKeyboardCommand('c');
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    super.dispose();
  }
}
