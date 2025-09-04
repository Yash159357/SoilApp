import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/theme.dart';

class LineChartWidget extends StatefulWidget {
  final List<SoilReading> readings;
  final bool showTemperature;
  final bool showMoisture;

  const LineChartWidget({
    super.key,
    required this.readings,
    this.showTemperature = true,
    this.showMoisture = true,
  });

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  bool _showTemperature = true;
  bool _showMoisture = true;
  bool _showTooltip = true;

  @override
  void initState() {
    super.initState();
    _showTemperature = widget.showTemperature;
    _showMoisture = widget.showMoisture;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readings.isEmpty) {
      return _buildEmptyChart();
    }

    final sortedReadings = widget.readings..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      children: [
        _buildLegendAndControls(),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LineChart(
              _buildChartData(sortedReadings),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendAndControls() {
    return Row(
      children: [
        if (_showTemperature)
          _buildLegendItem(
            'Temperature',
            AppTheme.primaryColor,
            Icons.thermostat,
                () => setState(() => _showTemperature = !_showTemperature),
          ),
        const SizedBox(width: 16),
        if (_showMoisture)
          _buildLegendItem(
            'Moisture',
            AppTheme.secondaryColor,
            Icons.water_drop,
                () => setState(() => _showMoisture = !_showMoisture),
          ),
        const Spacer(),
        IconButton(
          icon: Icon(
            _showTooltip ? Icons.info : Icons.info_outline,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _showTooltip = !_showTooltip),
          tooltip: 'Toggle tooltips',
        ),
      ],
    );
  }

  Widget _buildLegendItem(
      String label,
      Color color,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 2,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            color: AppTheme.textHint,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'No data to display',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<SoilReading> readings) {
    final List<FlSpot> tempSpots = [];
    final List<FlSpot> moistureSpots = [];

    for (int i = 0; i < readings.length; i++) {
      final reading = readings[i];
      if (_showTemperature) {
        tempSpots.add(FlSpot(i.toDouble(), reading.temperature));
      }
      if (_showMoisture) {
        moistureSpots.add(FlSpot(i.toDouble(), reading.moisture));
      }
    }

    final lines = <LineChartBarData>[];

    if (_showTemperature && tempSpots.isNotEmpty) {
      lines.add(_buildTemperatureLine(tempSpots));
    }

    if (_showMoisture && moistureSpots.isNotEmpty) {
      lines.add(_buildMoistureLine(moistureSpots));
    }

    return LineChartData(
      gridData: _buildGridData(),
      titlesData: _buildTitlesData(readings),
      borderData: _buildBorderData(),
      lineBarsData: lines,
      lineTouchData: _buildTouchData(readings),
      minX: 0,
      maxX: readings.length > 1 ? (readings.length - 1).toDouble() : 1,
      minY: _getMinY(readings),
      maxY: _getMaxY(readings),
      // swapAnimationDuration: const Duration(milliseconds: 250),
    );
  }

  LineChartBarData _buildTemperatureLine(List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: AppTheme.primaryColor,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 10,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: AppTheme.primaryColor,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: AppTheme.primaryColor.withOpacity(0.1),
      ),
    );
  }

  LineChartBarData _buildMoistureLine(List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: AppTheme.secondaryColor,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 10,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: AppTheme.secondaryColor,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: AppTheme.secondaryColor.withOpacity(0.1),
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      drawHorizontalLine: true,
      horizontalInterval: null,
      verticalInterval: null,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppTheme.textHint.withOpacity(0.2),
          strokeWidth: 1,
          dashArray: [3, 3],
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: AppTheme.textHint.withOpacity(0.2),
          strokeWidth: 1,
          dashArray: [3, 3],
        );
      },
    );
  }

  FlTitlesData _buildTitlesData(List<SoilReading> readings) {
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        axisNameWidget: const Text("Time"),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: _getBottomInterval(readings.length),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= readings.length) return const SizedBox();

            final reading = readings[index];
            return Text(
              _formatTimeLabel(reading.timestamp),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
                fontSize: 10,
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        axisNameWidget: const Text("Value"),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
                fontSize: 10,
              ),
            );
          },
        ),
      ),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: AppTheme.textHint.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  LineTouchData _buildTouchData(List<SoilReading> readings) {
    return LineTouchData(
      enabled: _showTooltip,
      touchTooltipData: LineTouchTooltipData(
        // tooltipBgColor: Colors.white.withOpacity(0.95),
        // tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(12),
        tooltipMargin: 8,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final index = spot.x.toInt();
            if (index < 0 || index >= readings.length) return null;

            final reading = readings[index];
            final isTemp = (_showTemperature && _showMoisture && spot.barIndex == 0) ||
                (_showTemperature && !_showMoisture);

            String value;
            Color color;
            String unit;

            if (isTemp) {
              value = reading.temperature.toStringAsFixed(1);
              color = AppTheme.primaryColor;
              unit = '°C';
            } else {
              value = reading.moisture.toStringAsFixed(1);
              color = AppTheme.secondaryColor;
              unit = '%';
            }

            return LineTooltipItem(
              '${_formatTimeLabel(reading.timestamp)}\n$value$unit',
              TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }).toList();
        },
      ),
      touchCallback: (event, response) {
        // Handle touch events if needed
      },
    );
  }

  double _getMinY(List<SoilReading> readings) {
    if (readings.isEmpty) return 0;

    double min = double.infinity;

    if (_showTemperature) {
      final tempMin = readings.map((r) => r.temperature).reduce((a, b) => a < b ? a : b);
      min = min < tempMin ? min : tempMin;
    }

    if (_showMoisture) {
      final moistureMin = readings.map((r) => r.moisture).reduce((a, b) => a < b ? a : b);
      min = min < moistureMin ? min : moistureMin;
    }

    return (min - 5).clamp(0, double.infinity);
  }

  double _getMaxY(List<SoilReading> readings) {
    if (readings.isEmpty) return 100;

    double max = double.negativeInfinity;

    if (_showTemperature) {
      final tempMax = readings.map((r) => r.temperature).reduce((a, b) => a > b ? a : b);
      max = max > tempMax ? max : tempMax;
    }

    if (_showMoisture) {
      final moistureMax = readings.map((r) => r.moisture).reduce((a, b) => a > b ? a : b);
      max = max > moistureMax ? max : moistureMax;
    }

    return max + 5;
  }

  double _getBottomInterval(int dataLength) {
    if (dataLength <= 5) return 1;
    if (dataLength <= 10) return 2;
    if (dataLength <= 20) return 4;
    return (dataLength / 5).ceil().toDouble();
  }

  String _formatTimeLabel(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return DateFormat('dd/MM').format(timestamp);
    } else if (diff.inHours > 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return '${timestamp.minute}m';
    }
  }
}