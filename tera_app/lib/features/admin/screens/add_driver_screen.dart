import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _saveDriver() async {
    setState(() => _isLoading = true);

    try {
      // Create a new document in 'drivers' collection
      // Since we don't have a UID yet (admin adding manually), we let Firestore generate one,
      // or we could use phone number as ID. Let's use auto-ID for now,
      // but store fields that allow matching later if needed.
      await FirebaseFirestore.instance.collection('drivers').add({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'plateNumber': _plateController.text.trim(),
        'vehicleModel': _modelController.text.trim(),
        'status': 'approved', // Admin added, so auto-approved
        'approved': true, // Backward compatibility
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': 'admin',
        // 'uid': '', // No auth UID yet
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding driver: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Add New Driver',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            // Confirm & Save
            _saveDriver();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == 2 ? 'CONFIRM & SAVE' : 'NEXT STEP',
                          ),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _isLoading ? null : details.onStepCancel,
                    child: const Text('BACK'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Details'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                _buildField(
                  'Full Name',
                  Icons.person_outline_rounded,
                  theme,
                  _nameController,
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Phone Number',
                  Icons.phone_iphone_rounded,
                  theme,
                  _phoneController,
                ),
                const SizedBox(height: 16),
                _buildField(
                  'License Number',
                  Icons.credit_card_rounded,
                  theme,
                  _licenseController,
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Vehicle'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                _buildField(
                  'Plate Number',
                  Icons.directions_car_filled_outlined,
                  theme,
                  _plateController,
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Vehicle Model',
                  Icons.info_outline_rounded,
                  theme,
                  _modelController,
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Confirm'),
            isActive: _currentStep >= 2,
            content: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready to Save',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please review the details before finalizing the registration.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    ThemeData theme,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
