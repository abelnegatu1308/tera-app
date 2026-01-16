import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/services/auth_service.dart';
import '../services/admin_settings_service.dart';
import '../../../models/admin_model.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(adminSettingsProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('QUEUE RULES'),
        _buildSettingCard(
          theme,
          child: settingsAsync.when(
            data: (settings) {
              final queueEnabled = settings['queueEnabled'] ?? true;
              final maxQueue = settings['maxQueueSize'] ?? 50;
              final hours = settings['operatingHours'] ?? '06:00 AM - 10:00 PM';

              return Column(
                children: [
                  _buildSwitchTile(
                    'Queue System Active',
                    'Enable or disable new entries globally',
                    queueEnabled,
                    (val) {
                      ref
                          .read(adminSettingsServiceProvider)
                          .setQueueEnabled(val);
                    },
                    theme,
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    'Max Drivers in Queue',
                    'Set to $maxQueue',
                    Icons.numbers_rounded,
                    theme,
                    onTap: () {
                      _showEditDialog(
                        context,
                        'Max Queue Size',
                        maxQueue.toString(),
                        (val) {
                          final intVal = int.tryParse(val);
                          if (intVal != null) {
                            ref
                                .read(adminSettingsServiceProvider)
                                .setMaxQueueSize(intVal);
                          }
                        },
                        isNumeric: true,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    'Operating Hours',
                    hours,
                    Icons.schedule_rounded,
                    theme,
                    onTap: () {
                      _showEditDialog(context, 'Operating Hours', hours, (val) {
                        ref
                            .read(adminSettingsServiceProvider)
                            .updateSetting('operatingHours', val);
                      });
                    },
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error: $err'),
            ),
          ),
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('APPEARANCE'),
        _buildSettingCard(
          theme,
          child: _buildSwitchTile(
            'Dark Mode',
            'Enable dark theme across the app',
            ref.watch(themeModeProvider) == ThemeMode.dark,
            (val) {
              ref.read(themeModeProvider.notifier).state = val
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
            theme,
          ),
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('ADMINISTRATION'),
        _buildSettingCard(
          theme,
          child: Column(
            children: [
              if (currentUser != null)
                ref
                    .watch(currentAdminProvider(currentUser.uid))
                    .when(
                      data: (adminProfile) {
                        final name = adminProfile?.name ?? 'Admin';
                        return _buildActionTile(
                          'Profile Information',
                          'Logged in as $name',
                          Icons.person_outline_rounded,
                          theme,
                          onTap: () {
                            if (adminProfile != null) {
                              _showEditProfileDialog(context, adminProfile);
                            }
                          },
                        );
                      },
                      loading: () =>
                          const ListTile(title: Text('Loading profile...')),
                      error: (err, _) => ListTile(title: Text('Error: $err')),
                    ),
              const Divider(height: 1),
              _buildActionTile(
                'Manage Admins',
                'Add or remove admin users',
                Icons.admin_panel_settings_outlined,
                theme,
                onTap: () => _showManageAdminsSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('SYSTEM'),
        _buildSettingCard(
          theme,
          child: Column(
            children: [
              _buildActionTile(
                'App Version',
                '1.0.0 (Build 42)',
                Icons.info_outline_rounded,
                theme,
              ),
              const Divider(height: 1),
              _buildActionTile(
                'Check for Updates',
                'Last checked: Today',
                Icons.system_update_rounded,
                theme,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () async {
              setState(() => _isLoading = true);
              await ref.read(authServiceProvider).signOut();
              if (mounted) setState(() => _isLoading = false);
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Sign Out',
                    style: GoogleFonts.outfit(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 48),
        Center(
          child: Text(
            'TERA ADMIN CONSOLE',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, AdminModel admin) {
    final controller = TextEditingController(text: admin.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ref
                    .read(adminSettingsServiceProvider)
                    .updateAdminProfile(admin.uid, newName);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showManageAdminsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _ManageAdminsSheet(),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String title,
    String currentVal,
    Function(String) onSave, {
    bool isNumeric = false,
  }) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFA000),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard(ThemeData theme, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.greenAccent,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    ThemeData theme, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

class _ManageAdminsSheet extends ConsumerStatefulWidget {
  const _ManageAdminsSheet();

  @override
  ConsumerState<_ManageAdminsSheet> createState() => _ManageAdminsSheetState();
}

class _ManageAdminsSheetState extends ConsumerState<_ManageAdminsSheet> {
  final _emailController = TextEditingController();
  final _uidController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final adminsAsync = ref.watch(allAdminsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Admins',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isAdding)
            _buildAddAdminForm()
          else
            Expanded(
              child: adminsAsync.when(
                data: (admins) => ListView.separated(
                  itemCount: admins.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, index) {
                    final admin = admins[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          admin.name.isNotEmpty ? admin.name[0] : 'A',
                        ),
                      ),
                      title: Text(admin.name),
                      subtitle: Text(admin.email),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, admin),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),

          if (!_isAdding)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isAdding = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Admin'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddAdminForm() {
    return Column(
      children: [
        TextField(
          controller: _uidController,
          decoration: const InputDecoration(
            labelText: 'Firebase UID (Required)',
            helperText: 'User must sign up first to get UID',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _isAdding = false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (_uidController.text.isEmpty) return;
                  await ref
                      .read(adminSettingsServiceProvider)
                      .addAdmin(
                        _uidController.text.trim(),
                        _emailController.text.trim(),
                        _nameController.text.trim(),
                      );
                  setState(() {
                    _isAdding = false;
                    _uidController.clear();
                    _nameController.clear();
                    _emailController.clear();
                  });
                },
                child: const Text('Add Admin'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, AdminModel admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Admin?'),
        content: Text(
          'Are you sure you want to remove ${admin.name}? They will lose access immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(adminSettingsServiceProvider)
                  .removeAdmin(admin.uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
