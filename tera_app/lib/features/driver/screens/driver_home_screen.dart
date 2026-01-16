import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'driver_queue_screen.dart';
import 'driver_history_screen.dart';
import 'driver_profile_screen.dart';
import '../../admin/services/queue_service.dart';
import '../../admin/services/driver_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/providers/user_provider.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _DriverHomeContent(),
    const DriverQueueScreen(),
    const DriverHistoryScreen(),
    const DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F121E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, 'Home', 0),
          _navItem(Icons.format_list_numbered, 'Queue', 1),
          _navItem(Icons.history_toggle_off, 'History', 2),
          _navItem(Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent, // Ensures the whole area is tappable
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFFFA000) : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFFFFA000) : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverHomeContent extends ConsumerWidget {
  const _DriverHomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.textTheme.bodySmall?.color;

    final userProfile = ref.watch(userProfileProvider);
    final queueItemsAsync = ref.watch(queueStreamProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      child: userProfile.when(
        data: (profile) {
          final driverName = profile.data['name'] ?? 'Driver';
          // Watch today's trips
          final tripsAsync = ref.watch(todayTripsProvider(currentUserId ?? ''));

          return queueItemsAsync.when(
            data: (items) {
              final queueIndex = items.indexWhere(
                (item) => item.driverId == currentUserId,
              );
              final isInQueue = queueIndex != -1;
              final position = isInQueue ? (queueIndex + 1).toString() : '—';
              final statusLabel = isInQueue
                  ? items[queueIndex].status.toUpperCase()
                  : 'NOT IN QUEUE';
              final estWait = isInQueue ? '${(queueIndex + 1) * 5} min' : '--';

              return Column(
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hello, $driverName',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '👋',
                                  style: TextStyle(fontSize: 24),
                                ),
                              ],
                            ),
                            Text(
                              "Let's get back on the road.",
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            context.push('/driver-home/notifications');
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.notifications_none,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // MAIN POSITION CARD
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // CIRCULAR POSITION INDICATOR
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isInQueue
                                          ? colorScheme.primary
                                          : Colors.grey[800]!,
                                      width: 8,
                                    ),
                                    boxShadow: isInQueue
                                        ? [
                                            BoxShadow(
                                              color: colorScheme.primary
                                                  .withOpacity(0.2),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'POSITION',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      Text(
                                        position,
                                        style: GoogleFonts.outfit(
                                          fontSize: 72,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // STATS ROW IN POSITION CARD
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildCardStat(
                                      context,
                                      'EST. WAIT',
                                      estWait,
                                      Colors.white,
                                    ),
                                    _buildCardStat(
                                      context,
                                      'STATUS',
                                      statusLabel,
                                      isInQueue
                                          ? colorScheme.primary
                                          : Colors.grey,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                // ACTION BUTTONS
                                SizedBox(
                                  width: double.infinity,
                                  child: isInQueue
                                      ? Column(
                                          children: [
                                            // Always show Leave Queue if in queue
                                            SizedBox(
                                              width: double.infinity,
                                              height: 60,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFF05151,
                                                  ), // Red
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  ref
                                                      .read(
                                                        queueServiceProvider,
                                                      )
                                                      .removeFromQueue(
                                                        currentUserId!,
                                                      );
                                                },
                                                child: Text(
                                                  'Leave Queue',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // If position is 1 (index 0), ALSO show Complete Trip
                                            if (queueIndex == 0) ...[
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 60,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        colorScheme.primary,
                                                    foregroundColor:
                                                        Colors.black,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    try {
                                                      if (currentUserId == null)
                                                        return;

                                                      // 1. Mark trip as complete
                                                      // Step 1: Mark trip as complete
                                                      try {
                                                        await ref
                                                            .read(
                                                              driverServiceProvider,
                                                            )
                                                            .completeTrip(
                                                              currentUserId!,
                                                            );
                                                      } catch (e) {
                                                        throw Exception(
                                                          'Step 1 (Save Trip) Failed: $e',
                                                        );
                                                      }

                                                      // Step 2: Remove from Queue
                                                      try {
                                                        await ref
                                                            .read(
                                                              queueServiceProvider,
                                                            )
                                                            .removeFromQueue(
                                                              currentUserId!,
                                                            );
                                                      } catch (e) {
                                                        throw Exception(
                                                          'Step 2 (Leave Queue) Failed: $e',
                                                        );
                                                      }

                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Trip Completed!',
                                                            ),
                                                            backgroundColor:
                                                                Colors.green,
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            title: const Text(
                                                              'Error',
                                                            ),
                                                            content:
                                                                SingleChildScrollView(
                                                                  child: Text(
                                                                    'Failed to complete trip.\n\nUser ID: $currentUserId\n\nError: $e',
                                                                  ),
                                                                ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'OK',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: Text(
                                                    'Complete Trip',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        )
                                      : SizedBox(
                                          height: 60,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  colorScheme.primary,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            onPressed: () {
                                              ref
                                                  .read(queueServiceProvider)
                                                  .addToQueue(
                                                    currentUserId!,
                                                    profile.data['name'] ??
                                                        'Unknown',
                                                    profile.data['plateNumber'] ??
                                                        '',
                                                  );
                                            },
                                            child: Text(
                                              'Join Queue',
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // BOTTOM STATS ROW
                          Row(
                            children: [
                              _buildBottomStatCard(
                                context,
                                'Today\'s Hours',
                                '4h 30m',
                                Icons.access_time,
                                Colors.blueAccent,
                              ),
                              const SizedBox(width: 16),
                              tripsAsync.when(
                                data: (trips) => _buildBottomStatCard(
                                  context,
                                  'Trips Today',
                                  trips.length.toString(), // Real Data
                                  Icons.history,
                                  Colors.greenAccent,
                                ),
                                loading: () => _buildBottomStatCard(
                                  context,
                                  'Trips Today',
                                  '...',
                                  Icons.history,
                                  Colors.greenAccent,
                                ),
                                error: (err, _) => _buildBottomStatCard(
                                  context,
                                  'Trips Today',
                                  '-',
                                  Icons.history,
                                  Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _buildErrorState(context, ref, err),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(context, ref, err),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    final theme = Theme.of(context);
    final errorStr = err.toString().toLowerCase();
    final isPermissionError =
        errorStr.contains('permission-denied') ||
        errorStr.contains('insufficient permissions');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPermissionError
                  ? Icons.lock_person_rounded
                  : Icons.error_outline_rounded,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              isPermissionError ? 'Access Denied' : 'Something went wrong',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPermissionError
                  ? 'There was a problem syncing your permissions. This usually happens right after login.'
                  : 'We couldn\'t load your driver dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Invalidate all related providers to force a fresh fetch
                ref.invalidate(userProfileProvider);
                ref.invalidate(queueStreamProvider);
                if (FirebaseAuth.instance.currentUser != null) {
                  ref.invalidate(
                    todayTripsProvider(FirebaseAuth.instance.currentUser!.uid),
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStat(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
