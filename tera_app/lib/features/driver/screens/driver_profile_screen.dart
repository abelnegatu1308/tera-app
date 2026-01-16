import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../admin/services/driver_service.dart';
import '../../../models/driver_model.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
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
    _nameController.text = driver.name;
    _phoneController.text = driver.phone;
    _plateController.text = driver.plateNumber;
    _licenseController.text = driver.licenseNumber;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile(DriverModel originalDriver) async {
    setState(() => _isLoading = true);

    try {
      String? photoUrl = originalDriver.photoUrl;

      if (_imageFile != null) {
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
        _imageFile = null; // Reset image file after save
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
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final currentUser = ref.watch(authServiceProvider).currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Not logged in'));
    }

    final driverAsync = ref.watch(driverStreamProvider(currentUser.uid));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) _imageFile = null; // Clear if cancelled
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
      body: driverAsync.when(
        data: (driver) {
          if (driver == null) {
            return const Center(child: Text('Driver profile not found'));
          }

          // Initialize controllers if not editing and text is different
          if (!_isEditing && _nameController.text != driver.name) {
            _initializeControllers(driver);
          } else if (_isEditing && _nameController.text.isEmpty) {
            _initializeControllers(driver);
          }
          if (_nameController.text.isEmpty) _initializeControllers(driver);

          return SizedBox(
            height: double.infinity, // Fill height for safe area scrolling
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // PROFILE HEADER
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _isEditing ? _pickImage : null,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (driver.photoUrl != null &&
                                            driver.photoUrl!.isNotEmpty)
                                      ? NetworkImage(driver.photoUrl!)
                                            as ImageProvider
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
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
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
                        const SizedBox(height: 20),

                        if (!_isEditing) ...[
                          Text(
                            driver.name,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            driver.phone,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              driver.status.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ] else ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                          ),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            icon: Icons.phone_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // VEHICLE DETAILS SECTION
                  _buildSettingsGroup(context, 'VEHICLE DETAILS', [
                    _isEditing
                        ? _buildTextField(
                            controller: _plateController,
                            label: 'Plate Number',
                            icon: Icons.directions_car_rounded,
                          )
                        : _buildSettingsItem(
                            context,
                            'Plate Number',
                            trailingText: driver.plateNumber,
                          ),
                    _isEditing
                        ? _buildTextField(
                            controller: _licenseController,
                            label: 'License ID',
                            icon: Icons.badge_outlined,
                            isLast: true,
                          )
                        : _buildSettingsItem(
                            context,
                            'License ID',
                            trailingText: driver.licenseNumber,
                            isLast: true,
                          ),
                  ]),

                  const SizedBox(height: 24),

                  if (_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _saveProfile(driver),
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
                    const SizedBox(height: 32),
                  ],

                  // APP SETTINGS SECTION
                  if (!_isEditing) ...[
                    _buildSettingsGroup(context, 'APP SETTINGS', [
                      _buildSettingsItem(
                        context,
                        'Language',
                        trailingText: 'English',
                        trailingColor: theme.colorScheme.primary,
                      ),
                      _buildSettingsItem(
                        context,
                        'Dark Mode',
                        isLast: true,
                        trailingWidget: Switch(
                          value: isDarkMode,
                          activeThumbColor: Colors.greenAccent,
                          onChanged: (value) {
                            ref.read(themeModeProvider.notifier).state = value
                                ? ThemeMode.dark
                                : ThemeMode.light;
                          },
                        ),
                        trailingText: isDarkMode ? 'On' : 'Off',
                        trailingColor: Colors.greenAccent,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // LOGOUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) {
                            context.go('/role-selection');
                          }
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFF05151),
                        ),
                        label: Text(
                          'Logout',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF05151),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF323644)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String label, {
    String? trailingText,
    Color? trailingColor,
    Widget? trailingWidget,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (trailingWidget != null)
            Row(
              children: [
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          trailingColor ??
                          Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(width: 12),
                trailingWidget,
              ],
            )
          else if (trailingText != null)
            Text(
              trailingText,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: trailingColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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

// Ensure this provider exists or is accessible
final driverStreamProvider = StreamProvider.family<DriverModel?, String>((
  ref,
  uid,
) {
  return ref.watch(driverServiceProvider).getDriver(uid);
});
