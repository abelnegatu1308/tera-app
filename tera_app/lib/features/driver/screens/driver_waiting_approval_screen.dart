import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/user_provider.dart';

class DriverWaitingApprovalScreen extends ConsumerWidget {
  const DriverWaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userProfileAsync = ref.watch(userProfileProvider);

    // We can rely on the router to handle the redirection, but for better UX
    // we can also listen here or just show a loading state if approved while redirecting.

    // Check if we are approved
    final userProfile = userProfileAsync.valueOrNull;
    if (userProfile != null && userProfile.status == DriverStatus.approved) {
      // Router should redirect, but we can double ensure or show a success message.
      // We'll let the router handling the redirection to avoid conflicts or double navigation.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 48),

            Text(
              'Approval Pending',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'Your application is being reviewed by our team. This usually takes less than 24 hours.',
              style: GoogleFonts.roboto(
                color: Colors.grey[400],
                height: 1.6,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Status: Pending Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              'Checking for updates...',
              style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 12),
            ),

            const SizedBox(height: 40),

            TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: Text(
                'Logout',
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
