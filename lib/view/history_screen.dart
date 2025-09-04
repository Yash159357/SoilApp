import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soil_app/blocs/history_bloc/history_bloc.dart';
import 'package:soil_app/blocs/soil_reading_bloc/soil_reading_bloc.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/theme.dart';
import 'package:soil_app/view/widgets/soil_reading_card.dart';
import 'package:soil_app/view/widgets/line_chart_widget.dart';
import 'package:soil_app/utils/time_formatter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  bool _showChart = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchHistory() {
    context.read<HistoryBloc>().add(FetchHistory(
      limit: 50,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLatestSection(),
                _buildHistorySection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Soil History'),
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _showDatePicker,
          icon: const Icon(Icons.date_range),
          tooltip: 'Filter by date',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'refresh') {
              _fetchHistory();
            } else if (value == 'toggle_chart') {
              setState(() {
                _showChart = !_showChart;
              });
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_chart',
              child: Row(
                children: [
                  Icon(_showChart ? Icons.list : Icons.show_chart, size: 18),
                  const SizedBox(width: 8),
                  Text(_showChart ? 'Show List' : 'Show Chart'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(
            icon: Icon(Icons.eco),
            text: 'Latest',
          ),
          Tab(
            icon: Icon(Icons.history),
            text: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildLatestSection() {
    return BlocBuilder<SoilReadingBloc, SoilReadingState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<SoilReadingBloc>().add(FetchReading(useMockData: false));
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLatestReadingCard(state),
                const SizedBox(height: 24),
                _buildQuickStats(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLatestReadingCard(SoilReadingState state) {
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sensors,
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
                        'Latest Reading',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (state is ReadingSuccess)
                        Text(
                          state.reading.timeAgo,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state is ReadingSuccess) ...[
              SoilReadingCard(
                reading: state.reading,
                showDeviceInfo: false,
                isMockData: state.isMockData,
              ),
            ] else if (state is ReadingLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ),
            ] else if (state is ReadingError) ...[
              _buildErrorMessage(state.message),
            ] else ...[
              _buildEmptyMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoaded && state.readings.isNotEmpty) {
          final readings = state.readings;
          final avgTemp = readings.averageTemperature;
          final avgMoisture = readings.averageMoisture;
          final totalReadings = readings.length;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Stats',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Total Readings',
                          totalReadings.toString(),
                          Icons.assessment,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Avg Temperature',
                          '${avgTemp.toStringAsFixed(1)}°C',
                          Icons.thermostat,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Avg Moisture',
                          '${avgMoisture.toStringAsFixed(1)}%',
                          Icons.water_drop,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            _fetchHistory();
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedDateRange != null) _buildDateRangeFilter(),
                if (state is HistoryLoaded && state.readings.isNotEmpty) ...[
                  if (_showChart) ...[
                    _buildChartSection(state.readings),
                    const SizedBox(height: 24),
                  ],
                  _buildReadingsList(state.readings),
                ] else if (state is HistoryLoading) ...[
                  _buildLoadingState(),
                ] else if (state is HistoryError) ...[
                  _buildErrorMessage(state.message),
                ] else ...[
                  _buildEmptyHistoryState(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateRangeFilter() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'From ${TimeFormatter.formatReadingTime(_selectedDateRange!.start)} '
                    'to ${TimeFormatter.formatReadingTime(_selectedDateRange!.end)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDateRange = null;
                });
                _fetchHistory();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(List<SoilReading> readings) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChartWidget(readings: readings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsList(List<SoilReading> readings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'All Readings (${readings.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: readings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final reading = readings[index];
            return SoilReadingCard(
              reading: reading,
              showDeviceInfo: true,
              isMockData: reading.deviceId == 'mock_device',
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.sensors_off,
              color: AppTheme.textHint,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No reading available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a test to see your latest reading here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              color: AppTheme.textHint,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your soil readings will appear here once you start taking measurements',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.science),
              label: const Text('Take First Reading'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        context.read<SoilReadingBloc>().add(FetchReading(useMockData: false));
      },
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.refresh, color: Colors.white),
      tooltip: 'Take new reading',
    );
  }

  Future<void> _showDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchHistory();
    }
  }
}