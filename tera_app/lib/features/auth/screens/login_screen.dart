import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tera_app/features/auth/services/auth_service.dart';

class DriverLoginPage extends ConsumerStatefulWidget {
  const DriverLoginPage({super.key});

  @override
  ConsumerState<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends ConsumerState<DriverLoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _phoneNumber = '';
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        debugPrint('📱 Starting phone verification for: $_phoneNumber');
        await ref
            .read(authServiceProvider)
            .verifyPhoneNumber(
              phoneNumber: _phoneNumber,
              verificationCompleted: (phoneAuthCredential) async {
                debugPrint('✅ Auto-verification completed');
                await ref
                    .read(authServiceProvider)
                    .signInWithCredential(phoneAuthCredential);
              },
              verificationFailed: (error) {
                debugPrint(
                  '❌ Verification failed: ${error.code} - ${error.message}',
                );
                setState(() => _isLoading = false);
                // Show detailed error dialog
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Verification Failed'),
                    content: SelectableText(
                      'Code: ${error.code}\n\nMessage: ${error.message}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              codeSent: (verificationId, resendToken) {
                debugPrint('📨 Code sent! Verification ID: $verificationId');
                setState(() => _isLoading = false);
                context.push(
                  '/otp',
                  extra: {
                    'verificationId': verificationId,
                    'phoneNumber': _phoneNumber,
                  },
                );
              },
              codeAutoRetrievalTimeout: (verificationId) {
                debugPrint('⏰ Auto-retrieval timeout');
              },
            );
      } catch (e) {
        debugPrint('🚨 Exception during verification: $e');
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error'),
              content: SelectableText('Exception: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                'Welcome Back',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please enter your phone number to sign in to your driver account.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: theme.textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              Text(
                'Phone Number',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: '+251 9XX XXX XXX',
                  prefixIcon: Icon(Icons.phone_iphone_rounded, size: 24),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
                onSaved: (value) => _phoneNumber = value!,
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
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'Continue',
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
                    'Not a driver? Go back',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
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
