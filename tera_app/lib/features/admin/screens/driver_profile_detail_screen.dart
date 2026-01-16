import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/driver_service.dart';
import '../../../models/driver_model.dart';

class DriverProfileDetailScreen extends ConsumerStatefulWidget {
  final String driverId;
  const DriverProfileDetailScreen({super.key, required this.driverId});

  @override
  ConsumerState<DriverProfileDetailScreen> createState() =>
      _DriverProfileDetailScreenState();
}

class _DriverProfileDetailScreenState
    extends ConsumerState<DriverProfileDetailScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _plateController;
  late TextEditingController _licenseController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _plateController = TextEditingController();
    _licenseController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  void _initializeControllers(DriverModel driver) {
    if (_nameController.text.isEmpty) _nameController.text = driver.name;
    if (_phoneController.text.isEmpty) _phoneController.text = driver.phone;
    if (_plateController.text.isEmpty)
      _plateController.text = driver.plateNumber;
    if (_licenseController.text.isEmpty)
      _licenseController.text = driver.licenseNumber;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _saveProfile(DriverModel originalDriver) async {
    setState(() => _isLoading = true);

    try {
      String? photoUrl = originalDriver.photoUrl;

      if (_imageFile != null) {
        // Updated to use Cloudinary upload (no driverId needed)
        photoUrl = await ref
            .read(driverServiceProvider)
            .uploadProfileImage(_imageFile!);
      }

      final updatedDriver = DriverModel(
        uid: originalDriver.uid,
        name: _nameController.text,
        phone: _phoneController.text,
        plateNumber: _plateController.text,
        licenseNumber: _licenseController.text,
        status: originalDriver.status,
        photoUrl: photoUrl,
      );

      await ref.read(driverServiceProvider).updateDriver(updatedDriver);

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driversAsync = ref.watch(allDriversProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Driver Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                // If cancelling edit, clear image selection
                if (!_isEditing) _imageFile = null;
              });
            },
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
          ),
          if (_isEditing)
            IconButton(
              onPressed: _isLoading ? null : () {}, // Handled in body
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            ),
        ],
      ),
      body: driversAsync.when(
        data: (drivers) {
          final driver = drivers.firstWhere(
            (d) => d.uid == widget.driverId,
            orElse: () => DriverModel(
              uid: '',
              name: 'Unknown',
              phone: '',
              plateNumber: '',
              licenseNumber: '',
              status: '',
            ),
          );

          if (driver.uid.isEmpty) {
            return const Center(child: Text('Driver not found'));
          }

          // Initialize controllers only once or when switching to edit mode
          if (!_isEditing && _nameController.text != driver.name) {
            _initializeControllers(driver);
          } else if (_isEditing && _nameController.text.isEmpty) {
            _initializeControllers(driver);
          }

          if (_nameController.text.isEmpty) _initializeControllers(driver);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // HEADER
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.1,
                        ),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (driver.photoUrl != null &&
                                  driver.photoUrl!.isNotEmpty)
                            ? NetworkImage(driver.photoUrl!) as ImageProvider
                            : null,
                        child:
                            (_imageFile == null &&
                                (driver.photoUrl == null ||
                                    driver.photoUrl!.isEmpty))
                            ? Text(
                                driver.name.isNotEmpty
                                    ? driver.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!_isEditing) ...[
                  Text(
                    driver.name,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ID: ${driver.uid}',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                ],

                const SizedBox(height: 24),

                // DETAILS SECTIONS
                _buildInfoCard(theme, 'CONTACT DETAILS', [
                  _isEditing
                      ? _buildTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          icon: Icons.phone_rounded,
                        )
                      : _buildInfoRow(
                          Icons.phone_rounded,
                          'Phone',
                          driver.phone,
                          theme,
                        ),
                ]),
                const SizedBox(height: 16),
                _buildInfoCard(theme, 'VEHICLE INFO', [
                  _isEditing
                      ? _buildTextField(
                          controller: _plateController,
                          label: 'Plate Number',
                          icon: Icons.directions_car_rounded,
                        )
                      : _buildInfoRow(
                          Icons.directions_car_rounded,
                          'Plate',
                          driver.plateNumber,
                          theme,
                        ),
                  const Divider(),
                  _isEditing
                      ? _buildTextField(
                          controller: _licenseController,
                          label: 'License Number',
                          icon: Icons.badge_outlined,
                        )
                      : _buildInfoRow(
                          Icons.badge_outlined,
                          'License',
                          driver.licenseNumber,
                          theme,
                        ),
                ]),
                const SizedBox(height: 16),
                if (!_isEditing)
                  _buildInfoCard(theme, 'STATUS', [
                    _buildInfoRow(
                      Icons.info_outline_rounded,
                      'Current Status',
                      driver.status.toUpperCase(),
                      theme,
                    ),
                  ]),

                const SizedBox(height: 32),

                // SAVE BUTTON
                if (_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _saveProfile(driver),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('SAVE CHANGES'),
                    ),
                  ),

                // ADMIN ACTIONS (Only show if not editing)
                if (!_isEditing)
                  Row(
                    children: [
                      if (driver.status != 'blocked')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(driverServiceProvider)
                                  .blockDriver(driver.uid);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.block_flipped, size: 20),
                            label: const Text('BLOCK DRIVER'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (driver.status == 'blocked')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(driverServiceProvider)
                                  .approveDriver(driver.uid);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.restore, size: 20),
                            label: const Text('UNBLOCK DRIVER'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.blueAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (driver.status == 'pending') const SizedBox(width: 16),
                      if (driver.status == 'pending')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ref
                                  .read(driverServiceProvider)
                                  .approveDriver(driver.uid);
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                            ),
                            label: const Text('APPROVE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }
}
