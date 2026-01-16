import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/driver_service.dart';
import '../../../models/driver_model.dart';
import 'driver_profile_detail_screen.dart';
import '../services/queue_service.dart';
import 'package:tera_app/core/widgets/firestore_error_widget.dart';

class DriverManagementScreen extends ConsumerStatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  ConsumerState<DriverManagementScreen> createState() =>
      _DriverManagementScreenState();
}

class _DriverManagementScreenState
    extends ConsumerState<DriverManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driversAsync = ref.watch(allDriversProvider);

    return Column(
      children: [
        // SEARCH & FILTER BAR
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by name or plate...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(Icons.filter_list_rounded),
                    onChanged: (value) {
                      setState(() => _selectedFilter = value!);
                    },
                    items: ['All', 'Pending', 'Approved', 'Blocked'].map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.roboto(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // DRIVER LIST
        Expanded(
          child: driversAsync.when(
            data: (drivers) {
              // Apply Filtering
              final filteredDrivers = drivers.where((driver) {
                final matchesSearch =
                    driver.name.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ) ||
                    driver.plateNumber.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    );
                final matchesFilter =
                    _selectedFilter == 'All' ||
                    driver.status.toLowerCase() ==
                        _selectedFilter.toLowerCase();
                return matchesSearch && matchesFilter;
              }).toList();

              if (filteredDrivers.isEmpty) {
                return Center(
                  child: Text(
                    'No drivers found',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filteredDrivers.length,
                itemBuilder: (context, index) {
                  final driver = filteredDrivers[index];
                  return _buildDriverCard(context, ref, theme, driver);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => FirestoreErrorWidget(
              error: err,
              onRefresh: () => ref.invalidate(allDriversProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    DriverModel driver,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        driver.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        driver.plateNumber,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildActionIconButton(
                      icon: Icons.visibility_outlined,
                      color: theme.colorScheme.primary,
                      tooltip: 'View Profile',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DriverProfileDetailScreen(driverId: driver.uid),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (driver.status == 'approved')
                      _buildActionIconButton(
                        icon: Icons.add_to_photos_outlined,
                        color: Colors.orangeAccent,
                        tooltip: 'Add to Queue',
                        onTap: () {
                          ref
                              .read(queueServiceProvider)
                              .addToQueue(
                                driver.uid,
                                driver.name,
                                driver.plateNumber,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${driver.name} to queue'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    if (driver.status == 'approved') const SizedBox(width: 8),
                    if (driver.status == 'pending')
                      _buildActionIconButton(
                        icon: Icons.check_circle_outline,
                        color: Colors.greenAccent,
                        tooltip: 'Approve',
                        onTap: () => ref
                            .read(driverServiceProvider)
                            .approveDriver(driver.uid),
                      ),
                    if (driver.status == 'pending') const SizedBox(width: 8),
                    if (driver.status != 'blocked')
                      _buildActionIconButton(
                        icon: Icons.block_flipped,
                        color: Colors.redAccent,
                        tooltip: 'Block',
                        onTap: () => ref
                            .read(driverServiceProvider)
                            .blockDriver(driver.uid),
                      ),
                    if (driver.status == 'blocked')
                      _buildActionIconButton(
                        icon: Icons.restore,
                        color: Colors.blueAccent,
                        tooltip: 'Unblock',
                        onTap: () => ref
                            .read(driverServiceProvider)
                            .approveDriver(driver.uid),
                      ),
                    const SizedBox(width: 8),
                    _buildActionIconButton(
                      icon: Icons.delete_outline,
                      color: Colors.grey,
                      tooltip: 'Delete',
                      onTap: () {
                        // Confirm Delete
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Driver?'),
                            content: Text(
                              'Are you sure you want to delete ${driver.name}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(driverServiceProvider)
                                      .deleteDriver(driver.uid);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusBadge(driver.status),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status.toUpperCase();
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.greenAccent;
        label = 'ACTIVE';
        break;
      case 'pending':
        color = const Color(0xFFFFA000);
        break;
      case 'blocked':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
