import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState
    extends ConsumerState<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();

  bool isLoading = false;

  Future<void> submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error: No user logged in')));
      return;
    }

    setState(() => isLoading = true);

    try {
      debugPrint('📝 Submitting registration for UID: ${user.uid}');
      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).set({
        'uid': user.uid,
        'name': nameController.text.trim(),
        'phone': user.phoneNumber,
        'plateNumber': plateController.text.trim(),
        'licenseNumber': licenseController.text.trim(),
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      debugPrint('✅ Registration saved! Redirecting to waiting-approval...');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted! Waiting for approval...'),
          backgroundColor: Colors.green,
        ),
      );

      // Small delay to let Firestore update
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.go('/waiting-approval');
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... UI stays mostly the same ...
    final theme = Theme.of(context);
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Driver Registration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your Profile',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phone: $phone',
                style: GoogleFonts.roboto(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              // DEBUG: Show UID for troubleshooting
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ DEBUG: Your User ID',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      FirebaseAuth.instance.currentUser?.uid ?? 'No UID',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If you are an Admin, create an "admins" document in Firestore with this EXACT ID.',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // FULL NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter full name' : null,
              ),

              const SizedBox(height: 20),

              // TAXI PLATE NUMBER
              TextFormField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'Taxi Plate Number',
                  hintText: 'A12345',
                  prefixIcon: Icon(Icons.drive_eta_outlined),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter plate number'
                    : null,
              ),

              const SizedBox(height: 20),

              // LICENSE NUMBER
              TextFormField(
                controller: licenseController,
                decoration: const InputDecoration(
                  labelText: 'Driver License Number',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter license number'
                    : null,
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitRegistration,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Registration',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
