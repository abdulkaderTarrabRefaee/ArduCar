# ArduCar

A Flutter application for controlling an Arduino-based RC car over Classic Bluetooth. The app supports two control modes: tilt control using the device accelerometer, and on-screen directional buttons with exponential speed ramping.

## Overview

ArduCar communicates with an HC-05 Bluetooth module attached to an Arduino Uno. The phone acts as a wireless controller, translating sensor input or button presses into motor commands sent at 10 Hz over a serial connection at 9600 baud.

The Arduino drives two DC motors in a differential-drive configuration. Direction and speed are derived from the received commands and applied immediately via PWM.

## Hardware Requirements

- Arduino Uno (or compatible board)
- HC-05 Bluetooth module (Classic Bluetooth, connected to pins 6 RX / 7 TX via SoftwareSerial)
- L298N or equivalent dual H-bridge motor driver
  - ENA on pin 9, ENB on pin 10 (PWM)
  - IN1-IN4 on pins 2-5
- Two DC gear motors
- Android device with Bluetooth support

## Communication Protocol

All commands are ASCII strings terminated with a newline character (`\n`).

**Tilt / Joystick mode**

```
X,Y,Z\n
```

- `X`: Steering, -100 (full left) to +100 (full right)
- `Y`: Speed, -100 (full reverse) to +100 (full forward)
- `Z`: Reserved, always 0

Example: `45,-80,0\n` steers 45% right at 80% reverse speed.

**Button / Keyboard mode**

| Command | Action     |
|---------|------------|
| `w\n`   | Forward    |
| `s\n`   | Backward   |
| `a\n`   | Turn right |
| `d\n`   | Turn left  |
| `c\n`   | Stop       |

Button commands use exponential speed ramping over 2 seconds (PWM 60 to 255). The Arduino applies a 600 ms safety timeout: if no command arrives within that window, the motors stop.

## Tilt Control

The device accelerometer is read continuously via the `sensors_plus` package. Pitch and roll are computed from the raw X/Y/Z acceleration values:

```
pitch = atan2(Y, sqrt(X^2 + Z^2))
roll  = atan2(-X, sqrt(Y^2 + Z^2))
```

Before mapping to control values, the pipeline applies:

- Calibration offset (user-settable neutral position)
- Dead zone of 0.08 rad to suppress idle jitter
- Exponential moving average with a smoothing factor of 0.7
- Sensitivity multiplier of 0.8x
- Reference angle of 45 deg (pi/4) for full-range output

The resulting -100 to +100 values are sent to the Arduino at 10 Hz.

## Architecture

```
UI
  BluetoothScanScreen   — device discovery and connection
  CarControlScreen      — control interface and sensor readout

State
  BluetoothProvider     — connection state and device list
  ControlProvider       — active control mode and sensor data

Services
  BluetoothService      — low-level serial communication over HC-05
  CarControlService     — sensor-to-command orchestration at 10 Hz
  SensorService         — accelerometer subscription and pitch/roll computation

Models
  CarControlData        — X, Y, Z control values
  SensorData            — pitch, roll, raw accelerometer
  SensorMapper          — calibration and range mapping

Utils
  Constants             — tuning parameters (dead zone, smoothing, update rate)
  AppTheme              — shared styling
```

## Safety Features

- Emergency stop button cuts motor output immediately
- App backgrounding triggers an automatic stop command
- 500 ms Bluetooth inactivity timeout on the app side
- 600 ms serial inactivity timeout on the Arduino side
- Connection state monitored via a broadcast stream; UI reflects loss instantly

## Flutter Dependencies

| Package                  | Version | Purpose                         |
|--------------------------|---------|---------------------------------|
| flutter_bluetooth_serial | 0.4.0   | Classic Bluetooth communication |
| sensors_plus             | 6.0.1   | Accelerometer access            |
| permission_handler       | 11.3.1  | Runtime permissions             |
| provider                 | 6.1.2   | State management                |
| flutter_animate          | 4.5.0   | UI transitions                  |

## Getting Started

1. Upload `arduino.ino` to the Arduino board using the Arduino IDE.
2. Wire the HC-05 module to pins 6 and 7, and the motor driver to pins 2-5, 9, 10.
3. Clone the repository and run `flutter pub get`.
4. Pair your Android device with the HC-05 module (default PIN: 1234).
5. Launch the app, select the paired device from the scan screen, and connect.

The HC-05 baud rate must match the value defined in `arduino.ino` (9600). Use `configure_hc05.ino` to reconfigure the module if needed, and `check_hc05_baudrate.ino` to verify the current baud rate.

## License

MIT
