import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/models/soil_device.dart';
import 'package:soil_app/const.dart';

/// Service to handle offline caching of soil readings and device information
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // Cache keys
  static const String _keyLatestReading = 'latest_soil_reading';
  static const String _keyRecentReadings = 'recent_soil_readings';
  static const String _keyLastConnectedDevice = 'last_connected_device';
  static const String _keyDevicesList = 'cached_devices_list';
  static const String _keyCacheTimestamp = 'cache_timestamp';
  static const String _keyOfflineReadings = 'offline_readings';
  static const String _keyUserPreferences = 'user_preferences';

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;

      // Clean up old cache data on startup (older than 7 days)
      await _cleanupOldCache();
    } catch (e) {
      print('Failed to initialize cache service: $e');
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Cache Operations for Soil Readings

  /// Cache the latest soil reading
  Future<void> cacheLatestReading(SoilReading reading) async {
    await _ensureInitialized();
    try {
      final jsonString = jsonEncode(reading.toMap());
      await _prefs?.setString(_keyLatestReading, jsonString);
      await _prefs?.setInt(_keyCacheTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Failed to cache latest reading: $e');
    }
  }

  /// Get the cached latest soil reading
  Future<SoilReading?> getCachedLatestReading() async {
    await _ensureInitialized();
    try {
      final jsonString = _prefs?.getString(_keyLatestReading);
      if (jsonString != null) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return SoilReading.fromMap(map);
      }
      return null;
    } catch (e) {
      print('Failed to get cached latest reading: $e');
      return null;
    }
  }

  /// Cache recent soil readings (up to 100 recent readings)
  Future<void> cacheRecentReadings(List<SoilReading> readings) async {
    await _ensureInitialized();
    try {
      // Limit to 100 most recent readings to avoid storage issues
      final limitedReadings = readings.take(100).toList();
      final jsonList = limitedReadings.map((reading) => reading.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      await _prefs?.setString(_keyRecentReadings, jsonString);
      await _prefs?.setInt(_keyCacheTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Failed to cache recent readings: $e');
    }
  }

  /// Get cached recent soil readings
  Future<List<SoilReading>> getCachedRecentReadings() async {
    await _ensureInitialized();
    try {
      final jsonString = _prefs?.getString(_keyRecentReadings);
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        return jsonList
            .map((json) => SoilReading.fromMap(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Failed to get cached recent readings: $e');
      return [];
    }
  }

  /// Cache Operations for Devices

  /// Cache the last connected device
  Future<void> cacheLastConnectedDevice(SoilDevice device) async {
    await _ensureInitialized();
    try {
      final jsonString = jsonEncode(device.toMap());
      await _prefs?.setString(_keyLastConnectedDevice, jsonString);
    } catch (e) {
      print('Failed to cache last connected device: $e');
    }
  }

  /// Get the cached last connected device
  Future<SoilDevice?> getCachedLastConnectedDevice() async {
    await _ensureInitialized();
    try {
      final jsonString = _prefs?.getString(_keyLastConnectedDevice);
      if (jsonString != null) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return SoilDevice.fromMap(map);
      }
      return null;
    } catch (e) {
      print('Failed to get cached last connected device: $e');
      return null;
    }
  }

  /// Cache discovered devices list
  Future<void> cacheDevicesList(List<SoilDevice> devices) async {
    await _ensureInitialized();
    try {
      final jsonList = devices.map((device) => device.toMap()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs?.setString(_keyDevicesList, jsonString);
    } catch (e) {
      print('Failed to cache devices list: $e');
    }
  }

  /// Get cached devices list
  Future<List<SoilDevice>> getCachedDevicesList() async {
    await _ensureInitialized();
    try {
      final jsonString = _prefs?.getString(_keyDevicesList);
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        return jsonList
            .map((json) => SoilDevice.fromMap(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Failed to get cached devices list: $e');
      return [];
    }
  }

  /// Offline Readings Management

  /// Store reading for offline sync when connection is restored
  Future<void> storeOfflineReading(SoilReading reading) async {
    await _ensureInitialized();
    try {
      final existingReadings = await getOfflineReadings();
      existingReadings.add(reading);

      // Limit offline storage to 50 readings
      final limitedReadings = existingReadings.take(50).toList();

      final jsonList = limitedReadings.map((r) => r.toMap()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs?.setString(_keyOfflineReadings, jsonString);
    } catch (e) {
      print('Failed to store offline reading: $e');
    }
  }

  /// Get all offline readings waiting to be synced
  Future<List<SoilReading>> getOfflineReadings() async {
    await _ensureInitialized();
    try {
      final jsonString = _prefs?.getString(_keyOfflineReadings);
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        return jsonList
            .map((json) => SoilReading.fromMap(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Failed to get offline readings: $e');
      return [];
    }
  }

  /// Clear offline readings after successful sync
  Future<void> clearOfflineReadings() async {
    await _ensureInitialized();
    try {
      await _prefs?.remove(_keyOfflineReadings);
    } catch (e) {
      print('Failed to clear offline readings: $e');
    }
  }

  /// Remove specific offline readings after successful sync
  Future<void> removeOfflineReadings(List<SoilReading> syncedReadings) async {
    await _ensureInitialized();
    try {
      final allOfflineReadings = await getOfflineReadings();
      final remainingReadings = allOfflineReadings.where((offline) {
        return !syncedReadings.any((synced) =>
        offline.timestamp == synced.timestamp &&
            offline.temperature == synced.temperature &&
            offline.moisture == synced.moisture);
      }).toList();

      if (remainingReadings.isEmpty) {
        await clearOfflineReadings();
      } else {
        final jsonList = remainingReadings.map((r) => r.toMap()).toList();
        final jsonString = jsonEncode(jsonList);
        await _prefs?.setString(_keyOfflineReadings, jsonString);
      }
    } catch (e) {
      print('Failed to remove synced offline readings: $e');
    }
  }

  /// User Preferences Management

  /// Cache user preferences
  Future<void> cacheUserPreferences(Map<String, dynamic> preferences) async {
    await _ensureInitialized();
    try {
      final jsonString = jsonEncode(preferences);
      await _prefs?.setString(_keyUserPreferences, jsonString);
    } catch (e) {
      print('Failed to cache user preferences: $e');
    }
  }

  /// Get cached user preferences
  Future<Map<String, dynamic>> getCachedUserPreferences() async {
    await _ensureInitialized();
    try {
      final jsonString = _prefs?.getString(_keyUserPreferences);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Failed to get cached user preferences: $e');
      return {};
    }
  }

  /// Cache Utility Methods

  /// Check if cached data is still fresh (not older than specified duration)
  Future<bool> isCacheFresh({Duration maxAge = const Duration(hours: 1)}) async {
    await _ensureInitialized();
    try {
      final timestamp = _prefs?.getInt(_keyCacheTimestamp);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      return now.difference(cacheTime) < maxAge;
    } catch (e) {
      print('Failed to check cache freshness: $e');
      return false;
    }
  }

  /// Get cache size information
  Future<Map<String, int>> getCacheInfo() async {
    await _ensureInitialized();
    try {
      final latestReading = _prefs?.getString(_keyLatestReading)?.length ?? 0;
      final recentReadings = _prefs?.getString(_keyRecentReadings)?.length ?? 0;
      final devicesList = _prefs?.getString(_keyDevicesList)?.length ?? 0;
      final offlineReadings = _prefs?.getString(_keyOfflineReadings)?.length ?? 0;
      final preferences = _prefs?.getString(_keyUserPreferences)?.length ?? 0;

      return {
        'latestReading': latestReading,
        'recentReadings': recentReadings,
        'devicesList': devicesList,
        'offlineReadings': offlineReadings,
        'preferences': preferences,
        'total': latestReading + recentReadings + devicesList + offlineReadings + preferences,
      };
    } catch (e) {
      print('Failed to get cache info: $e');
      return {};
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    try {
      await _prefs?.remove(_keyLatestReading);
      await _prefs?.remove(_keyRecentReadings);
      await _prefs?.remove(_keyLastConnectedDevice);
      await _prefs?.remove(_keyDevicesList);
      await _prefs?.remove(_keyCacheTimestamp);
      await _prefs?.remove(_keyOfflineReadings);
      await _prefs?.remove(_keyUserPreferences);
    } catch (e) {
      print('Failed to clear all cache: $e');
    }
  }

  /// Clear only reading data (keep device info and preferences)
  Future<void> clearReadingsCache() async {
    await _ensureInitialized();
    try {
      await _prefs?.remove(_keyLatestReading);
      await _prefs?.remove(_keyRecentReadings);
      await _prefs?.remove(_keyOfflineReadings);
      await _prefs?.remove(_keyCacheTimestamp);
    } catch (e) {
      print('Failed to clear readings cache: $e');
    }
  }

  /// Clean up cache data older than specified days
  Future<void> _cleanupOldCache({int maxDays = 7}) async {
    try {
      final timestamp = _prefs?.getInt(_keyCacheTimestamp);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        if (now.difference(cacheTime).inDays > maxDays) {
          await clearReadingsCache();
        }
      }
    } catch (e) {
      print('Failed to cleanup old cache: $e');
    }
  }

  /// Check if device has sufficient storage
  Future<bool> hasStorageSpace() async {
    await _ensureInitialized();
    try {
      final cacheInfo = await getCacheInfo();
      final totalSize = cacheInfo['total'] ?? 0;

      // Consider 1MB as reasonable limit for cache
      return totalSize < (1024 * 1024);
    } catch (e) {
      print('Failed to check storage space: $e');
      return true; // Assume we have space if we can't check
    }
  }

  /// Get count of offline readings waiting to sync
  Future<int> getOfflineReadingsCount() async {
    final offlineReadings = await getOfflineReadings();
    return offlineReadings.length;
  }

  /// Check if there are any offline readings to sync
  Future<bool> hasOfflineReadings() async {
    final count = await getOfflineReadingsCount();
    return count > 0;
  }
}