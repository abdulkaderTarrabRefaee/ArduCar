import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import 'car_control_screen.dart';
import '../utils/app_theme.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  @override
  void initState() {
    super.initState();
    // Load bonded devices on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothProvider>().loadBondedDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect to Arduino'),
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Scan button
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isScanning
                        ? null
                        : () => provider.startScan(),
                    icon: provider.isScanning
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Icon(Icons.bluetooth_searching),
                    label: Text(
                        provider.isScanning ? 'Scanning...' : 'SCAN FOR DEVICES'),
                  ),
                ),
              ),

              // Device lists
              Expanded(
                child: ListView(
                  children: [
                    // Bonded devices
                    if (provider.bondedDevices.isNotEmpty) ...[
                      ListTile(
                        title: Text('Paired Devices',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      ...provider.bondedDevices.map((device) =>
                          _buildDeviceTile(context, provider, device, true)),
                    ],

                    // Discovered devices
                    if (provider.discoveredDevices.isNotEmpty) ...[
                      ListTile(
                        title: Text('Available Devices',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      ...provider.discoveredDevices.map((device) =>
                          _buildDeviceTile(context, provider, device, false)),
                    ],

                    // No devices message
                    if (provider.bondedDevices.isEmpty &&
                        provider.discoveredDevices.isEmpty &&
                        !provider.isScanning)
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No devices found.\nTap SCAN to search for Bluetooth devices.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),

              // Error message
              if (provider.errorMessage != null)
                Container(
                  padding: EdgeInsets.all(16),
                  color: AppTheme.errorColor.withOpacity(0.2),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppTheme.errorColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceTile(BuildContext context, BluetoothProvider provider,
      device, bool isPaired) {
    final isConnecting = provider.isConnecting;

    return Card(
      child: ListTile(
        leading: Icon(
          isPaired ? Icons.bluetooth_connected : Icons.bluetooth,
          color: AppTheme.primaryColor,
        ),
        title: Text(device.name ?? 'Unknown Device'),
        subtitle: Text(device.address),
        trailing: isConnecting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.arrow_forward_ios, size: 16),
        onTap: isConnecting
            ? null
            : () async {
                final success = await provider.connect(device);
                if (success && mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => CarControlScreen()),
                  );
                }
              },
      ),
    );
  }
}
