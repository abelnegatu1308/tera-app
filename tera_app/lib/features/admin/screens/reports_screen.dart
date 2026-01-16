import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/services/driver_service.dart';
import '../../../models/trip_model.dart'; // Ensure TripModel is imported
import 'package:tera_app/core/widgets/firestore_error_widget.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allTripsAsync = ref.watch(allTripsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE FILTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overview',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: const Text('Last 7 Days'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CHART SECTION
          Container(
            height: 300,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: allTripsAsync.when(
              skipError: true,
              data: (trips) => _buildChart(context, trips),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => FirestoreErrorWidget(
                error: err,
                onRefresh: () => ref.invalidate(allTripsProvider),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // STATS GRID
          allTripsAsync.when(
            skipError: true,
            data: (trips) {
              final completedCount = trips.length;
              final busyHour = _calculateBusyHour(trips);

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildMiniStat(
                    theme,
                    'Avg Wait Time',
                    '~25m', // Still estimated as we don't have queue_join_time in TripModel yet
                    Icons.timer_outlined,
                    Colors.blue,
                  ),
                  _buildMiniStat(
                    theme,
                    'Completed Trips',
                    completedCount.toString(),
                    Icons.task_alt_rounded,
                    Colors.green,
                  ),
                  _buildMiniStat(
                    theme,
                    'Cancelled',
                    '0',
                    Icons.cancel_outlined,
                    Colors.red,
                  ),
                  _buildMiniStat(
                    theme,
                    'Busy Hour',
                    busyHour,
                    Icons.bolt_rounded,
                    Colors.orange,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.only(top: 24),
              child: FirestoreErrorWidget(
                error: err,
                onRefresh: () => ref.invalidate(allTripsProvider),
              ),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: allTripsAsync.when(
              data: (trips) => OutlinedButton.icon(
                onPressed: trips.isEmpty
                    ? null
                    : () => PdfService.generateAndShareReport(trips),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export PDF Report'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<TripModel> trips) {
    // 1. Process data: Get counts for last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );

    // Map of date string "MM-dd" to count
    final Map<String, int> dailyCounts = {};
    for (var date in last7Days) {
      final key = DateFormat('MM-dd').format(date);
      dailyCounts[key] = 0;
    }

    for (var trip in trips) {
      final tripDate = trip.completedAt;
      // potentially filter by range if needed, here we just check if it's in our map keys
      final key = DateFormat('MM-dd').format(tripDate);
      if (dailyCounts.containsKey(key)) {
        dailyCounts[key] = dailyCounts[key]! + 1;
      }
    }

    // Convert to BarGroups
    final barGroups = last7Days.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final key = DateFormat('MM-dd').format(date);
      final count = dailyCounts[key] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: const Color(0xFFFFA000), // Primary Orange
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: (dailyCounts.values.reduce((a, b) => a > b ? a : b) + 2)
                  .toDouble(), // Max + buffer
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly Activity',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            // Show total for week
            Text(
              '${trips.where((t) => t.completedAt.isAfter(today.subtract(const Duration(days: 7)))).length} trips',
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  (dailyCounts.values.isEmpty
                          ? 10
                          : dailyCounts.values.reduce((a, b) => a > b ? a : b) +
                                2)
                      .toDouble(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final date = last7Days[group.x.toInt()];
                    final dateStr = DateFormat('MMM d').format(date);
                    return BarTooltipItem(
                      '$dateStr\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${rod.toY.toInt()} Trips',
                          style: const TextStyle(
                            color: Color(0xFFFFA000),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = last7Days[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('d').format(date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  String _calculateBusyHour(List<TripModel> trips) {
    if (trips.isEmpty) return 'N/A';

    // Count occurrences of each hour
    final hourCounts = <int, int>{};
    for (var trip in trips) {
      final hour = trip.completedAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    if (hourCounts.isEmpty) return 'N/A';

    // Find max
    var maxHour = 0;
    var maxCount = -1;
    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        maxHour = hour;
      }
    });

    // Format like "2 PM" or "10 AM"
    final dt = DateTime(2024, 1, 1, maxHour); // Dummy date
    return DateFormat('h a').format(dt);
  }

  Widget _buildMiniStat(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    // ... existing implementation ...
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
