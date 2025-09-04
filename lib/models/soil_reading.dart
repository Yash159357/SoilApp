import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soil_app/const.dart';

/// Data model representing a soil reading with temperature and moisture values
class SoilReading {
  final String? id;
  final double temperature;
  final double moisture;
  final DateTime timestamp;
  final String userId;
  final String? deviceId;

  const SoilReading({
    this.id,
    required this.temperature,
    required this.moisture,
    required this.timestamp,
    required this.userId,
    this.deviceId,
  });

  /// Create a SoilReading from Firebase Firestore document
  factory SoilReading.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SoilReading(
      id: doc.id,
      temperature: (data[AppConstants.fieldTemperature] as num).toDouble(),
      moisture: (data[AppConstants.fieldMoisture] as num).toDouble(),
      timestamp: (data[AppConstants.fieldTimestamp] as Timestamp).toDate(),
      userId: data[AppConstants.fieldUserId] as String,
      deviceId: data[AppConstants.fieldDeviceId] as String?,
    );
  }

  /// Create a SoilReading from a Map (for JSON serialization)
  factory SoilReading.fromMap(Map<String, dynamic> map) {
    return SoilReading(
      id: map['id'] as String?,
      temperature: (map[AppConstants.fieldTemperature] as num).toDouble(),
      moisture: (map[AppConstants.fieldMoisture] as num).toDouble(),
      timestamp: map[AppConstants.fieldTimestamp] is Timestamp
          ? (map[AppConstants.fieldTimestamp] as Timestamp).toDate()
          : DateTime.parse(map[AppConstants.fieldTimestamp] as String),
      userId: map[AppConstants.fieldUserId] as String,
      deviceId: map[AppConstants.fieldDeviceId] as String?,
    );
  }

  /// Convert SoilReading to Map for Firebase Firestore
  Map<String, dynamic> toFirestore() {
    return {
      AppConstants.fieldTemperature: temperature,
      AppConstants.fieldMoisture: moisture,
      AppConstants.fieldTimestamp: Timestamp.fromDate(timestamp),
      AppConstants.fieldUserId: userId,
      if (deviceId != null) AppConstants.fieldDeviceId: deviceId,
    };
  }

  /// Convert SoilReading to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      AppConstants.fieldTemperature: temperature,
      AppConstants.fieldMoisture: moisture,
      AppConstants.fieldTimestamp: timestamp.toIso8601String(),
      AppConstants.fieldUserId: userId,
      if (deviceId != null) AppConstants.fieldDeviceId: deviceId,
    };
  }

  /// Create a copy of this SoilReading with some fields replaced
  SoilReading copyWith({
    String? id,
    double? temperature,
    double? moisture,
    DateTime? timestamp,
    String? userId,
    String? deviceId,
  }) {
    return SoilReading(
      id: id ?? this.id,
      temperature: temperature ?? this.temperature,
      moisture: moisture ?? this.moisture,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  /// Check if temperature reading is within normal range
  bool get isTemperatureNormal {
    return temperature >= AppConstants.minTemperature && 
           temperature <= AppConstants.maxTemperature;
  }

  /// Check if moisture reading is within normal range
  bool get isMoistureNormal {
    return moisture >= AppConstants.minMoisture && 
           moisture <= AppConstants.maxMoisture;
  }

  /// Check if both readings are within normal ranges
  bool get isReadingValid {
    return isTemperatureNormal && isMoistureNormal;
  }

  /// Get temperature status based on typical soil temperature ranges
  String get temperatureStatus {
    if (temperature < 0) return 'Frozen';
    if (temperature < 10) return 'Cold';
    if (temperature < 25) return 'Optimal';
    if (temperature < 35) return 'Warm';
    return 'Hot';
  }

  /// Get moisture status based on percentage
  String get moistureStatus {
    if (moisture < 20) return 'Dry';
    if (moisture < 40) return 'Low';
    if (moisture < 70) return 'Optimal';
    if (moisture < 85) return 'Moist';
    return 'Saturated';
  }

  /// Get formatted temperature string with unit
  String get formattedTemperature {
    return '${temperature.toStringAsFixed(1)}°C';
  }

  /// Get formatted moisture string with unit
  String get formattedMoisture {
    return '${moisture.toStringAsFixed(1)}%';
  }

  /// Get time ago string (e.g., "2 minutes ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  /// Compare two SoilReading objects for equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SoilReading) return false;

    return id == other.id &&
           temperature == other.temperature &&
           moisture == other.moisture &&
           timestamp == other.timestamp &&
           userId == other.userId &&
           deviceId == other.deviceId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      temperature,
      moisture,
      timestamp,
      userId,
      deviceId,
    );
  }

  @override
  String toString() {
    return 'SoilReading{'
           'id: $id, '
           'temperature: $temperature°C, '
           'moisture: $moisture%, '
           'timestamp: $timestamp, '
           'userId: $userId, '
           'deviceId: $deviceId'
           '}';
  }
}

/// Extension methods for collections of SoilReading
extension SoilReadingList on List<SoilReading> {
  /// Get the most recent reading from the list
  SoilReading? get mostRecent {
    if (isEmpty) return null;
    return reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
  }

  /// Get average temperature from all readings
  double get averageTemperature {
    if (isEmpty) return 0.0;
    return map((r) => r.temperature).reduce((a, b) => a + b) / length;
  }

  /// Get average moisture from all readings
  double get averageMoisture {
    if (isEmpty) return 0.0;
    return map((r) => r.moisture).reduce((a, b) => a + b) / length;
  }

  /// Filter readings within a date range
  List<SoilReading> filterByDateRange(DateTime start, DateTime end) {
    return where((reading) =>
        reading.timestamp.isAfter(start) && reading.timestamp.isBefore(end)
    ).toList();
  }

  /// Sort readings by timestamp (newest first)
  List<SoilReading> sortByNewest() {
    final sorted = List<SoilReading>.from(this);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  /// Sort readings by timestamp (oldest first)
  List<SoilReading> sortByOldest() {
    final sorted = List<SoilReading>.from(this);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }
}