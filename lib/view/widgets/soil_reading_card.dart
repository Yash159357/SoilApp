import 'package:flutter/material.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/theme.dart';
import 'package:soil_app/utils/time_formatter.dart';

class SoilReadingCard extends StatelessWidget {
  final SoilReading reading;
  final bool showDeviceInfo;
  final bool isMockData;
  final VoidCallback? onTap;
  final bool compact;

  const SoilReadingCard({
    super.key,
    required this.reading,
    this.showDeviceInfo = false,
    this.isMockData = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: compact ? 2 : 6,
      shadowColor: AppTheme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(compact ? 16 : 20),
          child: compact ? _buildCompactLayout() : _buildFullLayout(),
        ),
      ),
    );
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildReadingValues(),
        const SizedBox(height: 16),
        _buildStatusIndicators(),
        if (showDeviceInfo) ...[
          const SizedBox(height: 16),
          _buildDeviceInfo(),
        ],
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTemperatureCompact()),
            const SizedBox(width: 12),
            Expanded(child: _buildMoistureCompact()),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.grass,
            color: _getStatusColor(),
            size: compact ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Soil Reading',
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                TimeFormatter.formatReadingTime(reading.timestamp),
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isMockData)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warningColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              'DEMO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.warningColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReadingValues() {
    return Row(
      children: [
        Expanded(child: _buildTemperatureSection()),
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 60,
          color: AppTheme.textHint.withOpacity(0.3),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildMoistureSection()),
      ],
    );
  }

  Widget _buildTemperatureSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.thermostat,
              color: AppTheme.temperatureColor,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              reading.temperature.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.temperatureColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '°C',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.temperatureColor.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Temperature',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          reading.temperatureStatus,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _getTemperatureStatusColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildMoistureSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.water_drop,
              color: AppTheme.moistureColor,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              reading.moisture.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.moistureColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.moistureColor.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Moisture',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          reading.moistureStatus,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _getMoistureStatusColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureCompact() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.temperatureColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.temperatureColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.thermostat,
                color: AppTheme.temperatureColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${reading.temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.temperatureColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reading.temperatureStatus,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _getTemperatureStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoistureCompact() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.moistureColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.moistureColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                color: AppTheme.moistureColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${reading.moisture.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.moistureColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reading.moistureStatus,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _getMoistureStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _getTemperatureStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getTemperatureStatusIcon(),
                  color: _getTemperatureStatusColor(),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  reading.temperatureStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getTemperatureStatusColor(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _getMoistureStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getMoistureStatusIcon(),
                  color: _getMoistureStatusColor(),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  reading.moistureStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getMoistureStatusColor(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textHint.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reading.deviceId != null ? Icons.bluetooth : Icons.developer_mode,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Device Information',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDeviceInfoRow('Device ID', reading.deviceId ?? 'Mock Device'),
          _buildDeviceInfoRow('User ID', reading.userId),
          _buildDeviceInfoRow('Reading Time', TimeFormatter.formatDetailedTime(reading.timestamp)),
          if (isMockData)
            _buildDeviceInfoRow('Data Type', 'Demo/Mock Data'),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textHint,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for status colors and icons

  Color _getStatusColor() {
    if (!reading.isTemperatureNormal || !reading.isMoistureNormal) {
      return AppTheme.warningColor;
    }
    return AppTheme.successColor;
  }

  Color _getTemperatureStatusColor() {
    final temp = reading.temperature;
    if (temp < 0) return AppTheme.infoColor; // Frozen - Blue
    if (temp < 10) return AppTheme.infoColor; // Cold - Blue
    if (temp < 25) return AppTheme.successColor; // Optimal - Green
    if (temp < 35) return AppTheme.warningColor; // Warm - Orange
    return AppTheme.errorColor; // Hot - Red
  }

  Color _getMoistureStatusColor() {
    final moisture = reading.moisture;
    if (moisture < 20) return AppTheme.errorColor; // Dry - Red
    if (moisture < 40) return AppTheme.warningColor; // Low - Orange
    if (moisture < 70) return AppTheme.successColor; // Optimal - Green
    if (moisture < 85) return AppTheme.infoColor; // Moist - Blue
    return AppTheme.warningColor; // Saturated - Orange
  }

  IconData _getTemperatureStatusIcon() {
    final temp = reading.temperature;
    if (temp < 0) return Icons.ac_unit; // Frozen
    if (temp < 10) return Icons.thermostat; // Cold
    if (temp < 25) return Icons.eco; // Optimal
    if (temp < 35) return Icons.wb_sunny; // Warm
    return Icons.local_fire_department; // Hot
  }

  IconData _getMoistureStatusIcon() {
    final moisture = reading.moisture;
    if (moisture < 20) return Icons.water_drop_outlined; // Dry
    if (moisture < 40) return Icons.opacity; // Low
    if (moisture < 70) return Icons.water_drop; // Optimal
    if (moisture < 85) return Icons.waves; // Moist
    return Icons.flood; // Saturated
  }
}