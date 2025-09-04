import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soil_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:soil_app/blocs/soil_reading_bloc/soil_reading_bloc.dart';
import 'package:soil_app/models/soil_device.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/services/bluetooth_service.dart';
import 'package:soil_app/theme.dart';
import 'package:soil_app/view/history_screen.dart';
import 'package:soil_app/view/widgets/soil_reading_card.dart';
import 'package:soil_app/utils/time_formatter.dart';
import 'package:permission_handler/permission_handler.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final BluetoothService _bluetoothService = BluetoothService();
  SoilDevice? _connectedDevice;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeBluetoothService();
    _loadConnectedDevice();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _initializeBluetoothService() async {
    await _bluetoothService.initialize();
  }

  void _loadConnectedDevice() {
    setState(() {
      _connectedDevice = _bluetoothService.connectedDevice;
    });
  }
  Future<bool> _requestBluetoothPermission() async {
    final status = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();

    if (status.isGranted && connectStatus.isGranted) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth permission required'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SoilReadingBloc, SoilReadingState>(
      listener: (context, state) {
        if (state is ReadingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ReadingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reading captured successfully!'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is DeviceConnected) {
          setState(() {
            _connectedDevice = state.device;
          });
        } else if (state is DeviceDisconnected) {
          setState(() {
            _connectedDevice = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildAppBar(),
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBody(),
              ),
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Soil Health Monitor'),
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              context.read<AuthBloc>().add(LogoutRequested());
            } else if (value == 'settings') {
              // Navigate to settings if implemented
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildDeviceStatusCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildLatestReadingSection(),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Monitor your soil health',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _connectedDevice?.isConnected == true
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: _connectedDevice?.isConnected == true
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_connectedDevice != null) ...[
              _buildDeviceInfo('Device', _connectedDevice!.displayName),
              _buildDeviceInfo('Status', _connectedDevice!.connectionStatusDescription),
              if (_connectedDevice!.batteryLevel != null)
                _buildDeviceInfo('Battery', '${_connectedDevice!.batteryLevel}%'),
              if (_connectedDevice!.lastConnected != null)
                _buildDeviceInfo('Last Connected', _connectedDevice!.lastConnectedFormatted),
            ] else ...[
              Text(
                'No device connected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _scanForDevices,
                icon: _isScanning
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.search),
                label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTestButton()),
            const SizedBox(width: 16),
            Expanded(child: _buildReportsButton()),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.read<SoilReadingBloc>().add(FetchReading(useMockData: true));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.bug_report),
          label: const Text("Generate Mock Reading"),
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return BlocBuilder<SoilReadingBloc, SoilReadingState>(
      builder: (context, state) {
        final isLoading = state is ReadingLoading;

        return Container(
          height: 120,
          child: ElevatedButton(
            onPressed: isLoading ? null : _performTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: AppTheme.primaryColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Icon(Icons.science, size: 32),
                const SizedBox(height: 8),
                Text(
                  isLoading ? 'Testing...' : 'Test',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isLoading)
                  Text(
                    'Get Reading',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsButton() {
    return Container(
      height: 120,
      child: ElevatedButton(
        onPressed: _navigateToReports,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppTheme.secondaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 32),
            SizedBox(height: 8),
            Text(
              'Reports',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'View History',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestReadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Reading',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<SoilReadingBloc, SoilReadingState>(
          builder: (context, state) {
            if (state is ReadingSuccess) {
              return SoilReadingCard(
                reading: state.reading,
                showDeviceInfo: true,
                isMockData: state.isMockData,
              );
            } else if (state is ReadingError) {
              return _buildErrorCard(state.message);
            } else if (state is ReadingLoading) {
              return _buildLoadingCard();
            } else {
              return _buildEmptyStateCard();
            }
          },
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Reading soil data...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.sensors_off,
              color: AppTheme.textHint,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No readings yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the Test button to get your first soil reading',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen())),
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.history, color: Colors.white),
    );
  }

  Future<void> _refreshData() async {
    // Refresh device status and latest reading
    _loadConnectedDevice();

    // If we have a connected device, try to get the latest reading
    if (_connectedDevice?.isConnected == true) {
      context.read<SoilReadingBloc>().add(FetchReading(useMockData: false));
    }

    await Future.delayed(const Duration(seconds: 1));
  }

  void _performTest() async {
    final useMockData = _connectedDevice == null || !_connectedDevice!.isConnected;

    if (!useMockData) {
      final granted = await _requestBluetoothPermission();
      if (!granted) return;
    }

    context.read<SoilReadingBloc>().add(FetchReading(useMockData: useMockData));
  }

  void _navigateToReports() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
  }

  void _scanForDevices() async {
    final granted = await _requestBluetoothPermission();
    if (!granted) return;

    setState(() {
      _isScanning = true;
    });

    try {
      await _bluetoothService.startScan();

      // Listen for discovered devices
      _bluetoothService.devicesStream.listen((devices) {
        if (devices.isNotEmpty) {
          // Show device selection dialog
          _showDeviceSelectionDialog(devices);
        }
      });

      // Auto-stop scanning after timeout
      Future.delayed(const Duration(seconds: 10), () {
        setState(() {
          _isScanning = false;
        });
        _bluetoothService.stopScan();
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to scan for devices: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showDeviceSelectionDialog(List<SoilDevice> devices) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Device'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: Icon(
                  device.isMock ? Icons.developer_mode : Icons.bluetooth,
                  color: AppTheme.primaryColor,
                ),
                title: Text(device.displayName),
                subtitle: device.isMock
                    ? const Text('Mock Device')
                    : Text('RSSI: ${device.signalStrengthDescription}'),
                trailing: device.isMock
                    ? const Chip(
                  label: Text('DEMO'),
                  backgroundColor: AppTheme.successColor,
                )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _connectToDevice(device);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _connectToDevice(SoilDevice device) {
    if (device.isMock) {
      context.read<SoilReadingBloc>().add(UseMockDevice());
    } else {
      context.read<SoilReadingBloc>().add(ConnectToDevice(device));
    }
  }
}