import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tera_app/features/admin/services/queue_service.dart';
import 'package:tera_app/models/queue_item_model.dart';
import 'package:tera_app/core/widgets/firestore_error_widget.dart';

class QueueManagementScreen extends ConsumerWidget {
  const QueueManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final queueAsync = ref.watch(queueStreamProvider);

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => FirestoreErrorWidget(
        error: err,
        onRefresh: () => ref.invalidate(queueStreamProvider),
      ),
      data: (queueItems) {
        if (queueItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.queue_rounded, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'The queue is empty',
                  style: GoogleFonts.roboto(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: queueItems.length,
          itemBuilder: (context, index) {
            final item = queueItems[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  item.driverName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.plateNumber,
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionIcon(
                      Icons.arrow_upward_rounded,
                      index == 0 ? Colors.grey : Colors.blue,
                      index == 0
                          ? null
                          : () => ref
                                .read(queueServiceProvider)
                                .moveUp(item.driverId),
                    ),
                    _buildActionIcon(
                      Icons.arrow_downward_rounded,
                      index == queueItems.length - 1
                          ? Colors.grey
                          : Colors.blue,
                      index == queueItems.length - 1
                          ? null
                          : () => ref
                                .read(queueServiceProvider)
                                .moveDown(item.driverId),
                    ),
                    _buildActionIcon(
                      Icons.remove_circle_outline_rounded,
                      Colors.redAccent,
                      () => _showRemoveConfirmation(context, ref, item),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRemoveConfirmation(
    BuildContext context,
    WidgetRef ref,
    QueueItemModel item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Queue?'),
        content: Text('Are you sure you want to remove ${item.driverName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(queueServiceProvider).removeFromQueue(item.driverId);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback? onTap) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color, size: 20),
      onPressed: onTap,
    );
  }
}
