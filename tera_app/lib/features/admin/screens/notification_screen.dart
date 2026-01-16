import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../driver/services/notification_service.dart';
import '../services/driver_service.dart';
import 'package:tera_app/core/widgets/firestore_error_widget.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedTarget = 'All Drivers';
  String? _specificDriverUid;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driversAsync = ref.watch(allDriversProvider); // Watch all drivers

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BROADCAST SECTION
          Text(
            'Send Broadcast',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value:
                      [
                        'All Drivers',
                        'Queued Drivers Only',
                        'Active Drivers',
                        'Specific Driver',
                      ].contains(_selectedTarget)
                      ? _selectedTarget
                      : 'All Drivers', // Fallback
                  decoration: InputDecoration(
                    labelText: 'Recipients',
                    prefixIcon: const Icon(Icons.people_outline_rounded),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items:
                      [
                            'All Drivers',
                            'Queued Drivers Only',
                            'Active Drivers',
                            'Specific Driver',
                          ]
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _selectedTarget = val!),
                ),

                // Show Driver Dropdown if "Specific Driver" is selected
                if (_selectedTarget == 'Specific Driver') ...[
                  const SizedBox(height: 16),
                  driversAsync.when(
                    data: (drivers) {
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Driver',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor.withOpacity(
                            0.5,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: drivers.map((driver) {
                          return DropdownMenuItem(
                            value: driver.uid,
                            child: Text(
                              '${driver.name} (${driver.plateNumber})',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          // Store the actual UID in a separate variable if needed,
                          // or just use this strictly for selection.
                          // For simplicity, let's use a temp variable for the UID.
                          _specificDriverUid = val;
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => FirestoreErrorWidget(
                      error: e,
                      onRefresh: () => ref.invalidate(allDriversProvider),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your message here...',
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_messageController.text.isEmpty) return;

                      String target;
                      if (_selectedTarget == 'All Drivers') {
                        target = 'all';
                      } else if (_selectedTarget == 'Queued Drivers Only' ||
                          _selectedTarget == 'Active Drivers') {
                        // Assuming 'active' covers queue/active capable drivers
                        target = 'active';
                      } else {
                        if (_specificDriverUid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a driver'),
                            ),
                          );
                          return;
                        }
                        target = _specificDriverUid!;
                      }

                      await ref
                          .read(notificationServiceProvider)
                          .sendNotification(
                            title: 'Admin Message', // OR Make this an input too
                            body: _messageController.text,
                            target: target,
                          );

                      _messageController.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notification Sent!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Notification'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // HISTORY SECTION (Placeholders)
          Text(
            'Sent History',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // ... (Existing History List Code or Empty)
          const Center(child: Text("History not implemented yet")),
        ],
      ),
    );
  }
}
