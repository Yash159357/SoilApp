/// App-wide constants for Soil Health Monitoring App
class AppConstants {
  // App Information
  static const String appName = 'Soil Health Monitor';
  static const String appVersion = '1.0.0';

  // Firebase Collection Paths
  static const String soilReadingsCollection = 'soil_readings';
  static const String usersCollection = 'users';
  static const String devicesCollection = 'devices';

  // Firebase Field Names
  static const String fieldTimestamp = 'timestamp';
  static const String fieldTemperature = 'temperature';
  static const String fieldMoisture = 'moisture';
  static const String fieldUserId = 'userId';
  static const String fieldDeviceId = 'deviceId';
  static const String fieldEmail = 'email';
  static const String fieldDisplayName = 'displayName';
  static const String fieldCreatedAt = 'createdAt';

  // Bluetooth Low Energy (BLE) UUIDs
  // Service UUID for soil monitoring device
  static const String soilMonitorServiceUUID = '12345678-1234-1234-1234-123456789abc';
  // Characteristic UUIDs
  static const String temperatureCharacteristicUUID = '87654321-4321-4321-4321-cba987654321';
  static const String moistureCharacteristicUUID = '11111111-2222-3333-4444-555555555555';
  static const String dataCharacteristicUUID = '66666666-7777-8888-9999-aaaaaaaaaaaa';

  // Device Discovery Settings
  static const Duration bluetoothScanTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration dataReadTimeout = Duration(seconds: 5);

  // Mock Device Settings
  static const String mockDeviceName = 'Mock Soil Sensor';
  static const String mockDeviceId = 'MOCK_DEVICE_001';

  // Temperature and Moisture Ranges (for validation)
  static const double minTemperature = -40.0;
  static const double maxTemperature = 80.0;
  static const double minMoisture = 0.0;
  static const double maxMoisture = 100.0;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 15;



  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Chart Settings
  static const int maxHistoryDataPoints = 50;
  static const Duration chartAnimationDuration = Duration(milliseconds: 500);

  // Cache Settings
  static const String cacheKeyLastReading = 'last_soil_reading';
  static const String cacheKeyDeviceList = 'device_list';
  static const Duration cacheExpiration = Duration(hours: 1);

  // Error Messages
  static const String errorBluetoothDisabled = 'Bluetooth is disabled. Please enable it to connect to devices.';
  static const String errorDeviceNotFound = 'Soil monitoring device not found. Make sure it\'s powered on and nearby.';
  static const String errorConnectionFailed = 'Failed to connect to device. Please try again.';
  static const String errorDataReadFailed = 'Failed to read data from device.';
  static const String errorFirebaseConnection = 'Unable to connect to server. Please check your internet connection.';
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorNetworkUnavailable = 'Network unavailable. Some features may not work properly.';

  // Success Messages
  static const String successDataSaved = 'Soil reading saved successfully!';
  static const String successDeviceConnected = 'Device connected successfully!';
  static const String successLoginCompleted = 'Login successful!';

  // Navigation Routes
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeHome = '/home';
  static const String routeHistory = '/history';

  // Shared Preferences Keys
  static const String prefKeyIsFirstLaunch = 'is_first_launch';
  static const String prefKeyLastDeviceId = 'last_device_id';
  static const String prefKeyUserEmail = 'user_email';
  static const String prefKeyThemeMode = 'theme_mode';

  // Mock Data Generation Settings
  static const double mockTemperatureBase = 22.0;
  static const double mockTemperatureVariance = 8.0;
  static const double mockMoistureBase = 45.0;
  static const double mockMoistureVariance = 20.0;

  // Permissions
  static const List<String> requiredPermissions = [
    'android.permission.BLUETOOTH',
    'android.permission.BLUETOOTH_ADMIN',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
  ];

  // Time Formats
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String dateOnlyFormat = 'yyyy-MM-dd';
  static const String timeOnlyFormat = 'HH:mm';
  static const String chartDateFormat = 'MM/dd HH:mm';
}