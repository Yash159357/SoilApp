import 'package:soil_app/const.dart';

enum DeviceConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// type of soil monitoring device
enum DeviceType {
  real,
  mock,
}

class SoilDevice {
  final String id;
  final String name;
  final DeviceType type;
  final String? address; // Bluetooth MAC address for real devices
  final int? rssi; // Signal strength (RSSI) for Bluetooth devices
  final DeviceConnectionStatus connectionStatus;
  final DateTime? lastConnected;
  final DateTime? lastDataReceived;
  final String? firmwareVersion;
  final int? batteryLevel; // Battery percentage (0-100)

  const SoilDevice({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.rssi,
    this.connectionStatus = DeviceConnectionStatus.disconnected,
    this.lastConnected,
    this.lastDataReceived,
    this.firmwareVersion,
    this.batteryLevel,
  });

  factory SoilDevice.mock() {
    return const SoilDevice(
      id: AppConstants.mockDeviceId,
      name: AppConstants.mockDeviceName,
      type: DeviceType.mock,
      connectionStatus: DeviceConnectionStatus.connected,
      batteryLevel: 85,
      firmwareVersion: '1.0.0-mock',
    );
  }

  factory SoilDevice.bluetooth({
    required String id,
    required String name,
    required String address,
    int? rssi,
  }) {
    return SoilDevice(
      id: id,
      name: name,
      type: DeviceType.real,
      address: address,
      rssi: rssi,
      connectionStatus: DeviceConnectionStatus.disconnected,
    );
  }

  factory SoilDevice.fromMap(Map<String, dynamic> map) {
    return SoilDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      type: DeviceType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => DeviceType.real,
      ),
      address: map['address'] as String?,
      rssi: map['rssi'] as int?,
      connectionStatus: DeviceConnectionStatus.values.firstWhere(
            (e) => e.name == map['connectionStatus'],
        orElse: () => DeviceConnectionStatus.disconnected,
      ),
      lastConnected: map['lastConnected'] != null
          ? DateTime.parse(map['lastConnected'] as String)
          : null,
      lastDataReceived: map['lastDataReceived'] != null
          ? DateTime.parse(map['lastDataReceived'] as String)
          : null,
      firmwareVersion: map['firmwareVersion'] as String?,
      batteryLevel: map['batteryLevel'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'address': address,
      'rssi': rssi,
      'connectionStatus': connectionStatus.name,
      'lastConnected': lastConnected?.toIso8601String(),
      'lastDataReceived': lastDataReceived?.toIso8601String(),
      'firmwareVersion': firmwareVersion,
      'batteryLevel': batteryLevel,
    };
  }

  SoilDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? address,
    int? rssi,
    DeviceConnectionStatus? connectionStatus,
    DateTime? lastConnected,
    DateTime? lastDataReceived,
    String? firmwareVersion,
    int? batteryLevel,
  }) {
    return SoilDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      rssi: rssi ?? this.rssi,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastConnected: lastConnected ?? this.lastConnected,
      lastDataReceived: lastDataReceived ?? this.lastDataReceived,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }

  bool get isConnected => connectionStatus == DeviceConnectionStatus.connected;

  bool get isConnecting => connectionStatus == DeviceConnectionStatus.connecting;

  bool get hasError => connectionStatus == DeviceConnectionStatus.error;

  bool get isMock => type == DeviceType.mock;

  bool get isReal => type == DeviceType.real;

  String get signalStrengthDescription {
    if (rssi == null || isMock) return 'N/A';

    if (rssi! >= -50) return 'Excellent';
    if (rssi! >= -60) return 'Good';
    if (rssi! >= -70) return 'Fair';
    if (rssi! >= -80) return 'Poor';
    return 'Very Poor';
  }

  String get batteryStatus {
    if (batteryLevel == null) return 'Unknown';

    if (batteryLevel! >= 80) return 'High';
    if (batteryLevel! >= 50) return 'Medium';
    if (batteryLevel! >= 20) return 'Low';
    return 'Critical';
  }

  String get connectionStatusDescription {
    switch (connectionStatus) {
      case DeviceConnectionStatus.disconnected:
        return 'Disconnected';
      case DeviceConnectionStatus.connecting:
        return 'Connecting...';
      case DeviceConnectionStatus.connected:
        return 'Connected';
      case DeviceConnectionStatus.error:
        return 'Connection Error';
    }
  }

  String get lastConnectedFormatted {
    if (lastConnected == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastConnected!);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  String get lastDataReceivedFormatted {
    if (lastDataReceived == null) return 'No data';

    final now = DateTime.now();
    final difference = now.difference(lastDataReceived!);

    if (difference.inSeconds < 30) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  bool get isDataStale {
    if (lastDataReceived == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastDataReceived!);
    return difference.inMinutes > 30; // Consider stale after 30 minutes
  }

  String get displayName {
    if (name.length <= 20) return name;
    return '${name.substring(0, 17)}...';
  }

  String get shortId {
    if (id.length <= 8) return id;
    return id.substring(id.length - 8);
  }

  bool get canConnect {
    return connectionStatus == DeviceConnectionStatus.disconnected &&
        (isReal ? address != null : true);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SoilDevice) return false;

    return id == other.id &&
        name == other.name &&
        type == other.type &&
        address == other.address &&
        rssi == other.rssi &&
        connectionStatus == other.connectionStatus &&
        lastConnected == other.lastConnected &&
        lastDataReceived == other.lastDataReceived &&
        firmwareVersion == other.firmwareVersion &&
        batteryLevel == other.batteryLevel;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      type,
      address,
      rssi,
      connectionStatus,
      lastConnected,
      lastDataReceived,
      firmwareVersion,
      batteryLevel,
    );
  }

  @override
  String toString() {
    return 'SoilDevice{'
        'id: $id, '
        'name: $name, '
        'type: $type, '
        'address: $address, '
        'connectionStatus: $connectionStatus, '
        'batteryLevel: $batteryLevel%'
        '}';
  }
}

extension SoilDeviceList on List<SoilDevice> {
  List<SoilDevice> get connected {
    return where((device) => device.isConnected).toList();
  }

  List<SoilDevice> get mockDevices {
    return where((device) => device.isMock).toList();
  }

  List<SoilDevice> get realDevices {
    return where((device) => device.isReal).toList();
  }

  List<SoilDevice> sortBySignalStrength() {
    final sorted = List<SoilDevice>.from(this);
    sorted.sort((a, b) {
      if (a.rssi == null && b.rssi == null) return 0;
      if (a.rssi == null) return 1;
      if (b.rssi == null) return -1;
      return b.rssi!.compareTo(a.rssi!);
    });
    return sorted;
  }

  List<SoilDevice> sortByLastConnected() {
    final sorted = List<SoilDevice>.from(this);
    sorted.sort((a, b) {
      if (a.lastConnected == null && b.lastConnected == null) return 0;
      if (a.lastConnected == null) return 1;
      if (b.lastConnected == null) return -1;
      return b.lastConnected!.compareTo(a.lastConnected!);
    });
    return sorted;
  }

  SoilDevice? findById(String deviceId) {
    try {
      return firstWhere((device) => device.id == deviceId);
    } catch (e) {
      return null;
    }
  }

  SoilDevice? findByAddress(String address) {
    try {
      return firstWhere((device) => device.address == address);
    } catch (e) {
      return null;
    }
  }
}