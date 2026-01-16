import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tera_app/features/auth/services/auth_service.dart';
import 'package:tera_app/core/providers/user_provider.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        await ref
            .read(authServiceProvider)
            .signInWithEmailPassword(_email, _password);

        // AUTH SUCCESSFUL - Now wait 2 seconds for Firestore to catch up
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          final profileAsync = ref.read(userProfileProvider);

          // Check if there was an error fetching the profile (like permission denied)
          if (profileAsync is AsyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Auth Success! But Firestore profile error: ${profileAsync.error}',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 10),
              ),
            );
          } else {
            final profile = profileAsync.value;
            // If profile is not found or not an admin, show a helpful warning
            if (profile == null || profile.role != UserRole.admin) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Auth Success! But you are not listed as an Admin in Firestore. Check the "admins" collection document ID.',
                  ),
                  backgroundColor: Colors.blueAccent,
                  duration: Duration(seconds: 8),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Login Failed';
          if (e is FirebaseAuthException) {
            errorMessage =
                e.message ?? 'An unknown authentication error occurred.';
          } else {
            errorMessage = e.toString();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Portal',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your administrator credentials to manage the taxi queue.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Security Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'Access Dashboard',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Not an admin? Go back',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
