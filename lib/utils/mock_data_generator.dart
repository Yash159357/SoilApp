import 'dart:math';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/models/soil_device.dart';
import 'package:soil_app/const.dart';

/// Utility class to generate mock data for testing and development
class MockDataGenerator {
  static final Random _random = Random();

  // Private constructor to prevent instantiation
  MockDataGenerator._();

  /// Generate a single mock soil reading
  static SoilReading generateSoilReading(String userId, {
    DateTime? timestamp,
    String? deviceId,
    double? baseTemperature,
    double? baseMoisture,
  }) {
    final now = timestamp ?? DateTime.now();

    // Generate realistic temperature (15-35°C with some variation)
    final temp = baseTemperature ?? (20.0 + _random.nextDouble() * 15.0);
    final temperatureVariation = (_random.nextDouble() - 0.5) * 4.0; // ±2°C variation
    final temperature = (temp + temperatureVariation).clamp(
      AppConstants.minTemperature.toDouble(),
      AppConstants.maxTemperature.toDouble(),
    );

    // Generate realistic moisture (30-80% with some variation)
    final moist = baseMoisture ?? (40.0 + _random.nextDouble() * 40.0);
    final moistureVariation = (_random.nextDouble() - 0.5) * 20.0; // ±10% variation
    final moisture = (moist + moistureVariation).clamp(
      AppConstants.minMoisture.toDouble(),
      AppConstants.maxMoisture.toDouble(),
    );

    return SoilReading(
      temperature: double.parse(temperature.toStringAsFixed(1)),
      moisture: double.parse(moisture.toStringAsFixed(1)),
      timestamp: now,
      userId: userId,
      deviceId: deviceId ?? AppConstants.mockDeviceId,
    );
  }

  /// Generate multiple mock soil readings over a time period
  static List<SoilReading> generateMultipleReadings(
      String userId, {
        int count = 50,
        Duration intervalBetween = const Duration(hours: 1),
        DateTime? startTime,
        String? deviceId,
        bool addRandomVariation = true,
      }) {
    final readings = <SoilReading>[];
    final start = startTime ?? DateTime.now().subtract(Duration(hours: count));

    // Base values that will drift over time
    double baseTemperature = 22.0 + (_random.nextDouble() - 0.5) * 6.0;
    double baseMoisture = 55.0 + (_random.nextDouble() - 0.5) * 20.0;

    for (int i = 0; i < count; i++) {
      final timestamp = start.add(intervalBetween * i);

      if (addRandomVariation) {
        // Simulate gradual changes over time
        baseTemperature += (_random.nextDouble() - 0.5) * 2.0;
        baseMoisture += (_random.nextDouble() - 0.5) * 5.0;

        // Keep within reasonable bounds
        baseTemperature = baseTemperature.clamp(18.0, 32.0);
        baseMoisture = baseMoisture.clamp(35.0, 75.0);
      }

      readings.add(generateSoilReading(
        userId,
        timestamp: timestamp,
        deviceId: deviceId,
        baseTemperature: baseTemperature,
        baseMoisture: baseMoisture,
      ));
    }

    return readings;
  }

  /// Generate readings for different soil conditions
  static List<SoilReading> generateReadingsForCondition(
      String userId,
      SoilCondition condition, {
        int count = 10,
        DateTime? startTime,
        String? deviceId,
      }) {
    final readings = <SoilReading>[];
    final start = startTime ?? DateTime.now().subtract(Duration(hours: count));

    for (int i = 0; i < count; i++) {
      final timestamp = start.add(Duration(hours: i));

      double temperature, moisture;

      switch (condition) {
        case SoilCondition.dry:
          temperature = 25.0 + _random.nextDouble() * 8.0; // 25-33°C
          moisture = 15.0 + _random.nextDouble() * 15.0; // 15-30%
          break;
        case SoilCondition.optimal:
          temperature = 20.0 + _random.nextDouble() * 6.0; // 20-26°C
          moisture = 45.0 + _random.nextDouble() * 20.0; // 45-65%
          break;
        case SoilCondition.wet:
          temperature = 18.0 + _random.nextDouble() * 5.0; // 18-23°C
          moisture = 70.0 + _random.nextDouble() * 15.0; // 70-85%
          break;
        case SoilCondition.frozen:
          temperature = -5.0 + _random.nextDouble() * 8.0; // -5 to 3°C
          moisture = 20.0 + _random.nextDouble() * 30.0; // 20-50%
          break;
        case SoilCondition.hot:
          temperature = 35.0 + _random.nextDouble() * 10.0; // 35-45°C
          moisture = 25.0 + _random.nextDouble() * 25.0; // 25-50%
          break;
      }

      readings.add(SoilReading(
        temperature: double.parse(temperature.toStringAsFixed(1)),
        moisture: double.parse(moisture.toStringAsFixed(1)),
        timestamp: timestamp,
        userId: userId,
        deviceId: deviceId ?? AppConstants.mockDeviceId,
      ));
    }

    return readings;
  }

  /// Generate mock device for testing
  static SoilDevice generateMockDevice({
    String? id,
    String? name,
    DeviceType type = DeviceType.mock,
    DeviceConnectionStatus status = DeviceConnectionStatus.disconnected,
  }) {
    final deviceId = id ?? 'mock_device_${_random.nextInt(1000)}';
    final deviceNames = [
      'Soil Sensor Pro',
      'AgriSense Monitor',
      'Garden Guardian',
      'PlantCare Sensor',
      'Smart Soil Probe',
      'EcoSense Device',
      'GrowthTracker',
      'Soil Master 3000',
    ];

    return SoilDevice(
      id: deviceId,
      name: name ?? deviceNames[_random.nextInt(deviceNames.length)],
      type: type,
      address: type == DeviceType.real ? _generateMacAddress() : null,
      rssi: type == DeviceType.real ? -40 - _random.nextInt(40) : null, // -40 to -80
      connectionStatus: status,
      lastConnected: status == DeviceConnectionStatus.connected
          ? DateTime.now().subtract(Duration(minutes: _random.nextInt(120)))
          : null,
      lastDataReceived: status == DeviceConnectionStatus.connected
          ? DateTime.now().subtract(Duration(minutes: _random.nextInt(30)))
          : null,
      firmwareVersion: _generateFirmwareVersion(),
      batteryLevel: 20 + _random.nextInt(80), // 20-100%
    );
  }

  /// Generate multiple mock devices
  static List<SoilDevice> generateMockDevices(int count) {
    return List.generate(count, (index) => generateMockDevice());
  }

  /// Generate seasonal temperature pattern
  static List<SoilReading> generateSeasonalReadings(
      String userId, {
        required DateTime startDate,
        required DateTime endDate,
        Duration interval = const Duration(days: 1),
        String? deviceId,
      }) {
    final readings = <SoilReading>[];
    final totalDays = endDate.difference(startDate).inDays;

    DateTime current = startDate;
    while (current.isBefore(endDate)) {
      // Calculate day of year (0-365)
      final dayOfYear = current.difference(DateTime(current.year, 1, 1)).inDays;

      // Seasonal temperature variation (sine wave)
      final seasonalTemp = 22.0 + 8.0 * sin((dayOfYear / 365.0) * 2 * pi - pi/2);

      // Seasonal moisture variation (inverse of temperature somewhat)
      final seasonalMoisture = 55.0 - 10.0 * sin((dayOfYear / 365.0) * 2 * pi - pi/2);

      // Add daily variation
      final dailyTempVariation = (_random.nextDouble() - 0.5) * 4.0;
      final dailyMoistureVariation = (_random.nextDouble() - 0.5) * 10.0;

      final temperature = (seasonalTemp + dailyTempVariation).clamp(-10.0, 50.0);
      final moisture = (seasonalMoisture + dailyMoistureVariation).clamp(10.0, 90.0);

      readings.add(SoilReading(
        temperature: double.parse(temperature.toStringAsFixed(1)),
        moisture: double.parse(moisture.toStringAsFixed(1)),
        timestamp: current,
        userId: userId,
        deviceId: deviceId ?? AppConstants.mockDeviceId,
      ));

      current = current.add(interval);
    }

    return readings;
  }

  /// Generate readings with trends (increasing/decreasing over time)
  static List<SoilReading> generateTrendingReadings(
      String userId, {
        int count = 24,
        Duration interval = const Duration(hours: 1),
        TemperatureTrend temperatureTrend = TemperatureTrend.stable,
        MoistureTrend moistureTrend = MoistureTrend.stable,
        DateTime? startTime,
        String? deviceId,
      }) {
    final readings = <SoilReading>[];
    final start = startTime ?? DateTime.now().subtract(Duration(hours: count));

    double baseTemperature = 22.0;
    double baseMoisture = 55.0;

    for (int i = 0; i < count; i++) {
      final timestamp = start.add(interval * i);
      final progress = i / (count - 1); // 0 to 1

      // Apply temperature trend
      double temperature = baseTemperature;
      switch (temperatureTrend) {
        case TemperatureTrend.increasing:
          temperature += progress * 10.0; // +10°C over period
          break;
        case TemperatureTrend.decreasing:
          temperature -= progress * 10.0; // -10°C over period
          break;
        case TemperatureTrend.stable:
        // Small random variation
          temperature += (_random.nextDouble() - 0.5) * 2.0;
          break;
      }

      // Apply moisture trend
      double moisture = baseMoisture;
      switch (moistureTrend) {
        case MoistureTrend.increasing:
          moisture += progress * 20.0; // +20% over period
          break;
        case MoistureTrend.decreasing:
          moisture -= progress * 20.0; // -20% over period
          break;
        case MoistureTrend.stable:
        // Small random variation
          moisture += (_random.nextDouble() - 0.5) * 5.0;
          break;
      }

      // Clamp to valid ranges
      temperature = temperature.clamp(-10.0, 50.0);
      moisture = moisture.clamp(0.0, 100.0);

      readings.add(SoilReading(
        temperature: double.parse(temperature.toStringAsFixed(1)),
        moisture: double.parse(moisture.toStringAsFixed(1)),
        timestamp: timestamp,
        userId: userId,
        deviceId: deviceId ?? AppConstants.mockDeviceId,
      ));
    }

    return readings;
  }

  /// Generate MAC address for Bluetooth device
  static String _generateMacAddress() {
    final bytes = List.generate(6, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  /// Generate firmware version
  static String _generateFirmwareVersion() {
    final major = 1 + _random.nextInt(3); // 1-3
    final minor = _random.nextInt(10); // 0-9
    final patch = _random.nextInt(20); // 0-19

    return '$major.$minor.$patch';
  }

  /// Generate random user ID for testing
  static String generateUserId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        28, (_) => chars.codeUnitAt(_random.nextInt(chars.length))));
  }

  /// Generate readings with specific patterns for testing charts
  static List<SoilReading> generateChartTestData(
      String userId,
      ChartTestPattern pattern, {
        int count = 50,
        DateTime? startTime,
        String? deviceId,
      }) {
    final readings = <SoilReading>[];
    final start = startTime ?? DateTime.now().subtract(Duration(hours: count));

    for (int i = 0; i < count; i++) {
      final timestamp = start.add(Duration(hours: i));
      final progress = i / (count - 1); // 0 to 1

      double temperature, moisture;

      switch (pattern) {
        case ChartTestPattern.sine:
          temperature = 25.0 + 5.0 * sin(progress * 4 * pi);
          moisture = 50.0 + 15.0 * cos(progress * 4 * pi);
          break;
        case ChartTestPattern.linear:
          temperature = 20.0 + progress * 15.0;
          moisture = 70.0 - progress * 40.0;
          break;
        case ChartTestPattern.exponential:
          temperature = 20.0 + 15.0 * (exp(progress * 2) - 1) / (exp(2) - 1);
          moisture = 80.0 - 50.0 * progress * progress;
          break;
        case ChartTestPattern.random:
          temperature = 22.0 + (_random.nextDouble() - 0.5) * 20.0;
          moisture = 50.0 + (_random.nextDouble() - 0.5) * 60.0;
          break;
        case ChartTestPattern.step:
          final step = (progress * 4).floor();
          temperature = 18.0 + step * 4.0;
          moisture = 80.0 - step * 15.0;
          break;
      }

      // Clamp to valid ranges
      temperature = temperature.clamp(-10.0, 50.0);
      moisture = moisture.clamp(0.0, 100.0);

      readings.add(SoilReading(
        temperature: double.parse(temperature.toStringAsFixed(1)),
        moisture: double.parse(moisture.toStringAsFixed(1)),
        timestamp: timestamp,
        userId: userId,
        deviceId: deviceId ?? AppConstants.mockDeviceId,
      ));
    }

    return readings;
  }
}

/// Enum for different soil conditions
enum SoilCondition {
  dry,
  optimal,
  wet,
  frozen,
  hot,
}

/// Enum for temperature trends
enum TemperatureTrend {
  increasing,
  decreasing,
  stable,
}

/// Enum for moisture trends
enum MoistureTrend {
  increasing,
  decreasing,
  stable,
}

/// Enum for chart test patterns
enum ChartTestPattern {
  sine,
  linear,
  exponential,
  random,
  step,
}