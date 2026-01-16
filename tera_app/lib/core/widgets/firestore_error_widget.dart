import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FirestoreErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRefresh;
  final String? message;
  final bool compact;

  const FirestoreErrorWidget({
    super.key,
    required this.error,
    required this.onRefresh,
    this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorStr = error.toString().toLowerCase();
    final isPermissionDenied =
        errorStr.contains('permission-denied') ||
        errorStr.contains('permission denied');
    final isIndexError =
        errorStr.contains('failed-precondition') || errorStr.contains('index');

    if (compact) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIndexError
                    ? Icons.build_circle_outlined
                    : (isPermissionDenied
                          ? Icons.lock_person_rounded
                          : Icons.error_outline_rounded),
                color: isPermissionDenied ? Colors.redAccent : Colors.orange,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                isIndexError
                    ? 'Preparing Data...'
                    : (isPermissionDenied ? 'Access Denied' : 'Load Error'),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isIndexError
                    ? 'Building database index'
                    : 'Something went wrong',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  isIndexError ? 'Check Progress' : 'Retry',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPermissionDenied
                    ? Colors.redAccent.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIndexError
                    ? Icons.build_circle_outlined
                    : (isPermissionDenied
                          ? Icons.lock_person_rounded
                          : Icons.error_outline_rounded),
                color: isPermissionDenied ? Colors.redAccent : Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isIndexError
                  ? 'Preparing Chart Data'
                  : (isPermissionDenied ? 'Access Denied' : 'Data Load Error'),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message ??
                  (isIndexError
                      ? 'We\'re building a database index to speed up reports. This usually takes about 5 minutes.'
                      : (isPermissionDenied
                            ? 'You don\'t have permission to access this data. Please ensure you are signed in as an admin.'
                            : 'An error occurred while fetching data. Please try again.')),
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            if (!isPermissionDenied && !isIndexError && message == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                isIndexError ? 'Check Progress' : 'Refresh',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
