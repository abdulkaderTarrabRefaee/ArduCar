import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/control_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Run app
  runApp(const ArduinoCarApp());
}

class ArduinoCarApp extends StatelessWidget {
  const ArduinoCarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Bluetooth provider
        ChangeNotifierProvider(
          create: (_) => BluetoothProvider(),
        ),

        // Control provider (depends on Bluetooth provider)
        ChangeNotifierProxyProvider<BluetoothProvider, ControlProvider>(
          create: (context) => ControlProvider(
            context.read<BluetoothProvider>().service,
          ),
          update: (context, bluetoothProvider, previous) =>
              previous ?? ControlProvider(bluetoothProvider.service),
        ),
      ],
      child: MaterialApp(
        title: 'ArduCar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: SplashScreen(),
      ),
    );
  }
}
