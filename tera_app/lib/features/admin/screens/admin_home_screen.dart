import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'admin_dashboard_screen.dart';
import 'queue_management_screen.dart';
import 'driver_management_screen.dart';
import 'reports_screen.dart';
import 'admin_settings_screen.dart';
import 'notification_screen.dart';
import 'add_driver_screen.dart';
import '../services/queue_service.dart';
import '../../auth/services/auth_service.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const AdminHomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  final GlobalKey<State<Scaffold>> _scaffoldKey = GlobalKey<State<Scaffold>>();
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const AdminDashboardScreen(),
    const QueueManagementScreen(),
    const DriverManagementScreen(),
    const NotificationScreen(),
    const ReportsScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: !isDesktop
          ? AppBar(
              title: Text(
                _getPageTitle(_selectedIndex),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              actions: _buildAppBarActions(context, theme),
            )
          : null,
      drawer: !isDesktop ? _buildDrawer(theme) : null,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(theme),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      floatingActionButton: _buildFAB(context, theme),
    );
  }

  List<Widget>? _buildAppBarActions(BuildContext context, ThemeData theme) {
    if (_selectedIndex == 1) {
      // Queue
      return [
        IconButton(
          onPressed: () => _showResetConfirmation(context),
          icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
          tooltip: 'Reset Queue',
        ),
      ];
    } else if (_selectedIndex == 2) {
      // Drivers
      return [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDriverScreen()),
          ),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          tooltip: 'Add New Driver',
        ),
      ];
    }
    return null;
  }

  Widget? _buildFAB(BuildContext context, ThemeData theme) {
    if (_selectedIndex == 1) {
      // Queue
      return FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Driver Management to pick a driver to add
          setState(() => _selectedIndex = 2);
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: Text(
          'Quick Add',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      );
    }
    return null;
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Queue?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will clear all drivers from the current queue. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(queueServiceProvider).resetQueue();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Reset Globally',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Queue';
      case 2:
        return 'Drivers';
      case 3:
        return 'Alerts';
      case 4:
        return 'Reports';
      case 5:
        return 'Settings';
      default:
        return 'Tera Admin';
    }
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: _buildSidebarContent(theme),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 280,
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF0F172A) // Premium Dark Slate
          : theme.scaffoldBackgroundColor,
      child: _buildSidebarContent(theme),
    );
  }

  Widget _buildSidebarContent(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 48),
        // BRANDING
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.taxi_alert_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TERA Admin',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // NAV ITEMS
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildNavItem(0, 'Dashboard', Icons.dashboard_rounded, theme),
              _buildNavItem(
                1,
                'Queue',
                Icons.format_list_numbered_rounded,
                theme,
              ),
              _buildNavItem(2, 'Drivers', Icons.people_rounded, theme),
              _buildNavItem(3, 'Alerts', Icons.notifications_rounded, theme),
              _buildNavItem(4, 'Reports', Icons.analytics_rounded, theme),
              _buildNavItem(5, 'Settings', Icons.settings_rounded, theme),
            ],
          ),
        ),

        // LOGOUT
        const Divider(height: 1),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          title: Text(
            'Logout',
            style: GoogleFonts.outfit(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () async {
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) context.go('/role-selection');
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData icon,
    ThemeData theme,
  ) {
    final isSelected = _selectedIndex == index;
    final activeColor = Colors.orange;
    final inactiveColor = theme.textTheme.bodySmall?.color?.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          setState(() => _selectedIndex = index);
          final dynamic state = _scaffoldKey.currentState;
          if (state != null && state.isDrawerOpen == true) {
            state.closeDrawer();
          }
        },
        leading: Icon(icon, color: isSelected ? activeColor : inactiveColor),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? activeColor : inactiveColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
