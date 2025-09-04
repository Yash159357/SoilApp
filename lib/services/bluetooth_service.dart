import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import 'package:permission_handler/permission_handler.dart';
import 'package:soil_app/const.dart';
import 'package:soil_app/models/soil_device.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/utils/mock_data_generator.dart';

/// Service class to handle Bluetooth operations and device communication
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  StreamSubscription<List<fb.ScanResult>>? _scanSubscription;
  fb.BluetoothDevice? _connectedDevice;
  List<fb.BluetoothCharacteristic> _characteristics = [];
  bool _isConnected = false;
  StreamSubscription<List<int>>? _dataSubscription;

  // Stream controllers for real-time updates
  final StreamController<List<SoilDevice>> _devicesController =
  StreamController<List<SoilDevice>>.broadcast();
  final StreamController<SoilReading> _readingsController =
  StreamController<SoilReading>.broadcast();
  final StreamController<DeviceConnectionStatus> _connectionStatusController =
  StreamController<DeviceConnectionStatus>.broadcast();

  List<SoilDevice> _discoveredDevices = [];
  SoilDevice? _currentConnectedDevice;
  bool _isScanning = false;

  // Getters
  Stream<List<SoilDevice>> get devicesStream => _devicesController.stream;
  Stream<SoilReading> get readingsStream => _readingsController.stream;
  Stream<DeviceConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;
  List<SoilDevice> get discoveredDevices => List.from(_discoveredDevices);
  SoilDevice? get connectedDevice => _currentConnectedDevice;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;

  /// Initialize Bluetooth service
  Future<void> initialize() async {
    try {
      // Add mock device for development
      final mockDevice = SoilDevice.mock();
      _discoveredDevices.add(mockDevice);
      _devicesController.add(_discoveredDevices);

      // Listen for Bluetooth state changes
      fb.FlutterBluePlus.adapterState.listen((state) {
        if (state == fb.BluetoothAdapterState.off) {
          _connectionStatusController.add(DeviceConnectionStatus.error);
        }
      });
    } catch (e) {
      print('Failed to initialize Bluetooth service: $e');
    }
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      return await fb.FlutterBluePlus.isOn;
    } catch (e) {
      print('Failed to check Bluetooth status: $e');
      return false;
    }
  }

  /// Enable Bluetooth (Android only)
  Future<bool> enableBluetooth() async {
    try {
      if (!await isBluetoothEnabled()) {
        await fb.FlutterBluePlus.turnOn();
        return true;
      }
      return true;
    } catch (e) {
      print('Failed to enable Bluetooth: $e');
      return false;
    }
  }

  /// Check and request required permissions
  Future<bool> checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        final permissions = [
          Permission.bluetooth,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.locationWhenInUse,
        ];

        Map<Permission, PermissionStatus> statuses = await permissions.request();

        return statuses.values.every(
              (status) => status == PermissionStatus.granted || status == PermissionStatus.limited,
        );
      }
      return true; // iOS handles permissions differently
    } catch (e) {
      print('Failed to check permissions: $e');
      return false;
    }
  }

  Future<void> startScan({Duration? timeout}) async {
    if (_isScanning) {
      print('Already scanning for devices');
      return;
    }

    try {
      // Check permissions first
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        throw Exception('Bluetooth permissions not granted');
      }

      // Check if Bluetooth is enabled
      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        throw Exception(AppConstants.errorBluetoothDisabled);
      }

      _isScanning = true;
      _discoveredDevices.clear();

      // Always add mock device for development
      final mockDevice = SoilDevice.mock();
      _discoveredDevices.add(mockDevice);
      _devicesController.add(_discoveredDevices);

      // Start scanning
      _scanSubscription = fb.FlutterBluePlus.scanResults.listen((results) {
        for (fb.ScanResult result in results) {
          final device = SoilDevice.bluetooth(
            id: result.device.remoteId.str,
            name: result.device.platformName.isEmpty ? 'Unknown Device' : result.device.platformName,
            address: result.device.remoteId.str,
            rssi: result.rssi,
          );

          if (_isSoilMonitoringDevice(device.name)) {
            final existingIndex = _discoveredDevices.indexWhere(
                  (d) => d.id == device.id,
            );

            if (existingIndex >= 0) {
              _discoveredDevices[existingIndex] = device;
            } else {
              _discoveredDevices.add(device);
            }

            _devicesController.add(_discoveredDevices);
          }
        }
      }, onError: (e) {
        print('Scan error: $e');
        _isScanning = false;
      });

      // Start scanning
      await fb.FlutterBluePlus.startScan(
        timeout: timeout ?? AppConstants.bluetoothScanTimeout,
      );

      // Stop scanning after timeout
      final scanTimeout = timeout ?? AppConstants.bluetoothScanTimeout;
      Timer(scanTimeout, () {
        stopScan();
      });
    } catch (e) {
      _isScanning = false;
      throw Exception('Failed to start device scan: $e');
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      _isScanning = false;
      await fb.FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch (e) {
      print('Failed to stop scan: $e');
    }
  }

  Future<bool> connectToDevice(SoilDevice device) async {
    if (_isConnected) {
      await disconnect();
    }

    try {
      _connectionStatusController.add(DeviceConnectionStatus.connecting);

      if (device.isMock) {
        // Simulate connection to mock device
        await Future.delayed(const Duration(seconds: 2));
        _currentConnectedDevice = device.copyWith(
          connectionStatus: DeviceConnectionStatus.connected,
          lastConnected: DateTime.now(),
        );
        _isConnected = true;
        _connectionStatusController.add(DeviceConnectionStatus.connected);

        // Start mock data streaming
        _startMockDataStream();
        return true;
      } else {
        // Connect to real Bluetooth device
        if (device.address == null) {
          throw Exception('Device address is required for connection');
        }

        // Get all available devices - Fixed: Use proper Future handling
        final List<fb.BluetoothDevice> systemDevices = await fb.FlutterBluePlus.systemDevices([]);
        fb.BluetoothDevice? targetDevice;

        // Find the device by address
        for (var d in systemDevices) {
          if (d.remoteId.str == device.address) {
            targetDevice = d;
            break;
          }
        }

        if (targetDevice == null) {
          throw Exception('Device not found');
        }

        // Connect to device
        await targetDevice.connect();
        _connectedDevice = targetDevice;

        // Discover services - Fixed: Use proper Future handling
        List<fb.BluetoothService> services = await targetDevice.discoverServices();

        // Find the service and characteristics
        _characteristics.clear();
        for (fb.BluetoothService service in services) {
          // Get all characteristics for this service - Fixed: characteristics is already a List
          _characteristics.addAll(service.characteristics);
        }

        if (_characteristics.isEmpty) {
          throw Exception('No characteristics found');
        }

        // Set up notifications for the first readable characteristic
        fb.BluetoothCharacteristic? readCharacteristic;
        for (var characteristic in _characteristics) {
          if (characteristic.properties.read) {
            readCharacteristic = characteristic;
            break;
          }
        }

        if (readCharacteristic == null) {
          throw Exception('No readable characteristic found');
        }

        // Set up notifications
        await readCharacteristic.setNotifyValue(true);
        _dataSubscription = readCharacteristic.onValueReceived.listen((data) {
          _handleIncomingData(data);
        });

        _currentConnectedDevice = device.copyWith(
          connectionStatus: DeviceConnectionStatus.connected,
          lastConnected: DateTime.now(),
        );
        _isConnected = true;
        _connectionStatusController.add(DeviceConnectionStatus.connected);

        return true;
      }
    } catch (e) {
      _connectionStatusController.add(DeviceConnectionStatus.error);
      throw Exception('${AppConstants.errorConnectionFailed}: $e');
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      _dataSubscription?.cancel();
      _dataSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }

      if (_currentConnectedDevice != null) {
        _currentConnectedDevice = _currentConnectedDevice!.copyWith(
          connectionStatus: DeviceConnectionStatus.disconnected,
        );
      }

      _isConnected = false;
      _connectionStatusController.add(DeviceConnectionStatus.disconnected);
    } catch (e) {
      print('Failed to disconnect: $e');
    }
  }

  /// Request a single soil reading from connected device
  Future<SoilReading> requestSoilReading(String userId, {bool forceMock = false}) async {
    // Always allow mock if requested
    if (forceMock) {
      final mockReading = MockDataGenerator.generateSoilReading(userId);
      _readingsController.add(mockReading);
      return mockReading;
    }

    // Block if not connected to a real device
    if (!_isConnected || _currentConnectedDevice == null) {
      throw Exception('No device connected');
    }

    try {
      if (_currentConnectedDevice!.isMock) {
        final mockReading = MockDataGenerator.generateSoilReading(userId);
        _readingsController.add(mockReading);

        _currentConnectedDevice = _currentConnectedDevice!.copyWith(
          lastDataReceived: DateTime.now(),
        );

        return mockReading;
      } else {
        return await _requestRealDeviceReading(userId);
      }
    } catch (e) {
      throw Exception('${AppConstants.errorDataReadFailed}: $e');
    }
  }

  /// Handle incoming data from Bluetooth device
  void _handleIncomingData(List<int> data) {
    try {
      final reading = _parseBluetoothData(Uint8List.fromList(data));
      if (reading != null) {
        _readingsController.add(reading);

        // Update device's last data received time
        _currentConnectedDevice = _currentConnectedDevice!.copyWith(
          lastDataReceived: DateTime.now(),
        );
      }
    } catch (e) {
      print('Failed to parse Bluetooth data: $e');
    }
  }

  /// Start mock data streaming for development
  void _startMockDataStream() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isConnected || _currentConnectedDevice?.isMock != true) {
        timer.cancel();
        return;
      }

      try {
        final mockReading = MockDataGenerator.generateSoilReading('mock_user');
        _readingsController.add(mockReading);

        // Update device's last data received time
        _currentConnectedDevice = _currentConnectedDevice!.copyWith(
          lastDataReceived: DateTime.now(),
        );
      } catch (e) {
        print('Failed to generate mock reading: $e');
      }
    });
  }

  /// Request reading from real Bluetooth device
  Future<SoilReading> _requestRealDeviceReading(String userId) async {
    if (_connectedDevice == null || !_isConnected) {
      throw Exception('Device not connected');
    }

    try {
      // Send command to request data (customize based on your device protocol)
      final command = 'GET_READING\n';

      // Find a writable characteristic
      fb.BluetoothCharacteristic? writeCharacteristic;
      for (var characteristic in _characteristics) {
        if (characteristic.properties.write) {
          writeCharacteristic = characteristic;
          break;
        }
      }

      if (writeCharacteristic != null) {
        await writeCharacteristic.write(utf8.encode(command));
      }

      // Wait for response with timeout
      final completer = Completer<SoilReading>();
      Timer? timeoutTimer;

      // Set up a one-time listener for the response
      StreamSubscription<List<int>>? responseSubscription;

      // Find a readable characteristic
      fb.BluetoothCharacteristic? readCharacteristic;
      for (var characteristic in _characteristics) {
        if (characteristic.properties.read || characteristic.properties.notify) {
          readCharacteristic = characteristic;
          break;
        }
      }

      if (readCharacteristic != null) {
        responseSubscription = readCharacteristic.onValueReceived.listen((data) {
          try {
            final reading = _parseBluetoothData(Uint8List.fromList(data), userId: userId);
            if (reading != null && !completer.isCompleted) {
              timeoutTimer?.cancel();
              responseSubscription?.cancel();
              completer.complete(reading);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              timeoutTimer?.cancel();
              responseSubscription?.cancel();
              completer.completeError(e);
            }
          }
        });
      }

      timeoutTimer = Timer(AppConstants.dataReadTimeout, () {
        responseSubscription?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(Exception('Data read timeout'));
        }
      });

      return await completer.future;
    } catch (e) {
      throw Exception('Failed to request device reading: $e');
    }
  }

  /// Parse incoming Bluetooth data into SoilReading
  SoilReading? _parseBluetoothData(Uint8List data, {String? userId}) {
    try {
      final dataString = utf8.decode(data).trim();
      print('Received data: $dataString'); // Debug log

      // Expected format: "TEMP:25.5,MOISTURE:65.2"
      final parts = dataString.split(',');
      if (parts.length != 2) return null;

      double? temperature;
      double? moisture;

      for (final part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length != 2) continue;

        final key = keyValue[0].toUpperCase();
        final value = double.tryParse(keyValue[1]);

        if (value == null) continue;

        if (key == 'TEMP' || key == 'TEMPERATURE') {
          temperature = value;
        } else if (key == 'MOISTURE' || key == 'HUMID' || key == 'HUMIDITY') {
          moisture = value;
        }
      }

      if (temperature != null && moisture != null) {
        return SoilReading(
          temperature: temperature,
          moisture: moisture,
          timestamp: DateTime.now(),
          userId: userId ?? 'unknown',
          deviceId: _currentConnectedDevice?.id,
        );
      }

      return null;
    } catch (e) {
      print('Failed to parse Bluetooth data: $e');
      return null;
    }
  }

  /// Check if device name suggests it's a soil monitoring device
  bool _isSoilMonitoringDevice(String deviceName) {
    final name = deviceName.toLowerCase();
    return name.contains('soil') ||
        name.contains('sensor') ||
        name.contains('monitor') ||
        name.contains('temp') ||
        name.contains('moisture') ||
        name.contains('humid');
  }

  /// Simulate device discovery for iOS or testing
  Future<void> _simulateDeviceDiscovery() async {
    // Simulate finding a few devices
    await Future.delayed(const Duration(seconds: 1));

    final simulatedDevices = [
      SoilDevice.bluetooth(
        id: 'sim_device_001',
        name: 'Soil Sensor Pro',
        address: '00:11:22:33:44:55',
        rssi: -45,
      ),
      SoilDevice.bluetooth(
        id: 'sim_device_002',
        name: 'AgriSense Monitor',
        address: '00:11:22:33:44:56',
        rssi: -60,
      ),
    ];

    for (final device in simulatedDevices) {
      await Future.delayed(const Duration(milliseconds: 500));
      _discoveredDevices.add(device);
      _devicesController.add(_discoveredDevices);
    }

    _isScanning = false;
  }

  /// Get bonded/paired devices (Android only)
  Future<List<SoilDevice>> getBondedDevices() async {
    try {
      // Fixed: Use proper Future handling for systemDevices
      final List<fb.BluetoothDevice> systemDevices = await fb.FlutterBluePlus.systemDevices([]);
      List<SoilDevice> bondedDevices = [];

      for (var device in systemDevices) {
        if (_isSoilMonitoringDevice(device.platformName)) {
          bondedDevices.add(SoilDevice.bluetooth(
            id: device.remoteId.str,
            name: device.platformName.isEmpty ? 'Unknown Device' : device.platformName,
            address: device.remoteId.str,
          ));
        }
      }

      return bondedDevices;
    } catch (e) {
      print('Failed to get bonded devices: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _dataSubscription?.cancel();
    _scanSubscription?.cancel();
    disconnect();
    _devicesController.close();
    _readingsController.close();
    _connectionStatusController.close();
  }
}