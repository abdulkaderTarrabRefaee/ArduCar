import 'dart:math';

/// Application-wide constants for Arduino car controller

// ==================== Bluetooth Configuration ====================
/// Baud rate for HC-05 Bluetooth module communication
const int BLUETOOTH_BAUD_RATE = 9600;

/// How often to send control data to Arduino (in milliseconds)
/// 100ms = 10Hz update rate - balances responsiveness and performance
const int DATA_SEND_INTERVAL = 100;

/// Timeout for connection monitoring (in milliseconds)
const int CONNECTION_CHECK_INTERVAL = 2000;

// ==================== Sensor Configuration ====================
/// Dead zone threshold in radians to prevent jitter from small movements
/// Tilts smaller than this will be considered neutral
const double SENSOR_DEAD_ZONE = 0.08;

/// Sensitivity multiplier for tilt response
/// Higher values = more sensitive control
/// Range: 1.0 (less sensitive) to 2.5 (very sensitive)
const double TILT_SENSITIVITY = 0.8;

/// Smoothing factor for exponential moving average
/// 0.7 means 70% new data, 30% old data
/// Higher values = more responsive but potentially jerkier
/// Lower values = smoother but less responsive
const double SMOOTHING_FACTOR = 0.7;

// ==================== Control Value Ranges ====================
/// Maximum control value sent to Arduino
const int MAX_CONTROL_VALUE = 100;

/// Minimum control value sent to Arduino
const int MIN_CONTROL_VALUE = -100;

/// Reference tilt angle for full range (45 degrees in radians)
/// When phone is tilted 45°, control value reaches maximum
const double REFERENCE_TILT_ANGLE = pi / 4;

// ==================== Safety Configuration ====================
/// Timeout for stopping car if no data received (in milliseconds)
/// Arduino has its own 500ms timeout, this is for app-side safety
const int SAFETY_TIMEOUT = 500;

// ==================== UI Configuration ====================
/// App name displayed in UI
const String APP_NAME = 'Arduino Car Controller';

/// Default theme colors
const int PRIMARY_COLOR = 0xFF00BCD4; // Cyan
const int SECONDARY_COLOR = 0xFF00897B; // Teal
const int ERROR_COLOR = 0xFFFF5252; // Red

/// Update frequency for sensor display (in milliseconds)
const int SENSOR_DISPLAY_UPDATE_INTERVAL = 100;
