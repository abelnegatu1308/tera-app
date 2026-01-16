import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/driver_service.dart';
import '../services/queue_service.dart';
import '../services/admin_settings_service.dart';
import '../../../models/trip_model.dart';
import 'package:tera_app/core/widgets/firestore_error_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allDriversAsync = ref.watch(allDriversProvider);
    final queueItemsAsync = ref.watch(queueStreamProvider);
    final allTripsAsync = ref.watch(allTripsProvider);
    final settingsAsync = ref.watch(adminSettingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Overview',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              settingsAsync.when(
                data: (settings) => Transform.scale(
                  scale: 0.8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Queue',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (settings['queueEnabled'] ?? true)
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                      Switch(
                        value: settings['queueEnabled'] ?? true,
                        onChanged: (val) => ref
                            .read(adminSettingsServiceProvider)
                            .setQueueEnabled(val),
                        activeColor: Colors.greenAccent,
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, _) => IconButton(
                  onPressed: () => ref.invalidate(adminSettingsProvider),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.orange),
                  tooltip: 'Retry loading settings',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Statistics Cards
          Row(
            children: [
              _buildStatCard(
                context,
                'In Queue',
                queueItemsAsync.when(
                  data: (items) => items.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '!',
                ),
                theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Total Trips',
                allTripsAsync.when(
                  skipError: true,
                  data: (trips) => trips.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '!',
                ),
                Colors.greenAccent,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Drivers',
                allDriversAsync.when(
                  data: (drivers) => drivers.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '!',
                ),
                Colors.blueAccent,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // WEEKLY ACTIVITY CHART (Promoted from Reports)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              TextButton(
                onPressed: () => context.go(
                  '/admin-dashboard',
                ), // In a real app we'd switch tab index
                child: const Text('Full Reports'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            ),
            child: allTripsAsync.when(
              skipError: true,
              data: (trips) => _buildDashboardChart(context, trips),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => FirestoreErrorWidget(
                error: err,
                onRefresh: () => ref.invalidate(allTripsProvider),
                compact: true,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Queue Preview',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin-dashboard/queue'),
                child: const Text('Manage Queue'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          queueItemsAsync.when(
            data: (items) => _buildLiveQueuePreview(theme, items),
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (err, _) => FirestoreErrorWidget(
              error: err,
              onRefresh: () => ref.invalidate(queueStreamProvider),
              compact: true,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Activity & Health',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'System',
            'Queue monitoring active',
            'Real-time',
            Icons.sensors_rounded,
            Colors.greenAccent,
          ),
          _buildActivityItem(
            'Database',
            'Connected to Firestore',
            'Live',
            Icons.cloud_done_rounded,
            Colors.blueAccent,
          ),

          const SizedBox(height: 32),
          Text(
            'Management',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),

          _buildActionTile(
            context,
            'Queue Management',
            'Control live queue order and status',
            Icons.format_list_numbered_rounded,
            theme.colorScheme.primary,
            () => context.go('/admin-dashboard/queue'),
          ),
          _buildActionTile(
            context,
            'Driver Approvals',
            'Verify and approve new registrations',
            Icons.how_to_reg_rounded,
            Colors.greenAccent,
            () => context.go('/admin-dashboard/drivers'),
          ),

          const SizedBox(height: 16),
          Text(
            'Quick Actions',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickButton(
                context,
                'Add Driver',
                Icons.person_add_rounded,
                theme.colorScheme.primary,
                () => context.go('/admin-dashboard/add-driver'),
              ),
              const SizedBox(width: 12),
              _buildQuickButton(
                context,
                'Send Alert',
                Icons.notification_add_rounded,
                Colors.orange,
                () => context.go('/admin-dashboard/alerts'),
              ),
              const SizedBox(width: 12),
              _buildQuickButton(
                context,
                'Reset Queue',
                Icons.refresh_rounded,
                Colors.redAccent,
                () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset Queue?'),
                      content: const Text(
                        'Are you sure you want to clear the entire queue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(queueServiceProvider).resetQueue();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveQueuePreview(ThemeData theme, List<dynamic> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            'Queue is empty',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    final previewItems = items.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: List.generate(
          previewItems.length,
          (index) => _buildPreviewRow(theme, previewItems[index], index),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(ThemeData theme, dynamic item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${item.driverName} (${item.plateNumber})',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Active',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardChart(BuildContext context, List<TripModel> trips) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );

    final Map<String, int> dailyCounts = {};
    for (var date in last7Days) {
      dailyCounts[DateFormat('MM-dd').format(date)] = 0;
    }

    for (var trip in trips) {
      final key = DateFormat('MM-dd').format(trip.completedAt);
      if (dailyCounts.containsKey(key)) {
        dailyCounts[key] = dailyCounts[key]! + 1;
      }
    }

    final barGroups = last7Days.asMap().entries.map((entry) {
      final key = DateFormat('MM-dd').format(entry.value);
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: (dailyCounts[key] ?? 0).toDouble(),
            color: const Color(0xFFFFA000),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceAround,
        maxY:
            (dailyCounts.values.isEmpty
                    ? 5
                    : dailyCounts.values.reduce((a, b) => a > b ? a : b) + 2)
                .toDouble(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) => Text(
                DateFormat('d').format(last7Days[val.toInt()]),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildActivityItem(
    String type,
    String desc,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$type • $time',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.roboto(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24),
        ),
      ),
    );
  }
}
