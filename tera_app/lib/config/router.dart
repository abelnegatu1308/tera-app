import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tera_app/features/common/screens/role_selection_screen.dart';
import 'package:tera_app/features/common/screens/splash_screen.dart';
import 'package:tera_app/features/auth/screens/login_screen.dart';
import 'package:tera_app/features/auth/screens/admin_login_screen.dart';
import 'package:tera_app/features/auth/screens/otp_screen.dart';
import 'package:tera_app/features/driver/screens/driver_home_screen.dart';
import 'package:tera_app/features/admin/screens/admin_home_screen.dart';
import 'package:tera_app/features/admin/screens/add_driver_screen.dart';
import 'package:tera_app/features/auth/services/auth_service.dart';
import 'package:tera_app/core/providers/user_provider.dart';
import 'package:tera_app/features/driver/screens/driver_waiting_approval_screen.dart';
import 'package:tera_app/features/driver/screens/driver_registration_screen.dart';
import 'package:tera_app/features/driver/screens/driver_notifications_screen.dart';

// Provider for the router notifier to handle refresh logic
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final userProfileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value != null;

      // If we are logged in but profile is still loading, stay on current page (or Splash)
      if (isLoggedIn && userProfileAsync.isLoading) return null;

      final profile = userProfileAsync.value ?? UserProfile.empty();

      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/admin-login' ||
          state.matchedLocation == '/role-selection' ||
          state.matchedLocation == '/' ||
          state.matchedLocation.startsWith('/otp');

      // 1. Handle Unauthenticated users
      if (!isLoggedIn) {
        return isLoggingIn ? null : '/role-selection';
      }

      // 2. Handle Authenticated users
      if (isLoggingIn) {
        // If logged in but no profile found, redirect to registration
        if (profile.role == UserRole.none) {
          return '/registration';
        }

        // Redirection based on role
        if (profile.role == UserRole.admin) {
          return '/admin-dashboard';
        }

        if (profile.role == UserRole.driver) {
          if (profile.status == DriverStatus.approved) {
            return '/driver-home';
          } else {
            return '/waiting-approval';
          }
        }

        return null;
      }

      // 3. New User Protection: If logged in but no profile, force registration
      if (profile.role == UserRole.none &&
          state.matchedLocation != '/registration') {
        return '/registration';
      }

      // 4. Handle Status Changes while inside the app (e.g. driver gets approved/blocked)
      if (profile.role == UserRole.driver) {
        final onWaitingPage = state.matchedLocation == '/waiting-approval';
        if (profile.status == DriverStatus.approved && onWaitingPage) {
          return '/driver-home';
        }
        if (profile.status != DriverStatus.approved &&
            !onWaitingPage &&
            state.matchedLocation.startsWith('/driver')) {
          return '/waiting-approval';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const DriverLoginPage(),
      ),
      GoRoute(
        path: '/registration',
        builder: (context, state) => const DriverRegistrationScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, String>;
          return OtpVerificationPage(
            verificationId: extras['verificationId']!,
            phoneNumber: extras['phoneNumber']!,
          );
        },
      ),
      GoRoute(
        path: '/waiting-approval',
        builder: (context, state) => const DriverWaitingApprovalScreen(),
      ),
      GoRoute(
        path: '/driver-home',
        builder: (context, state) => const DriverHomeScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const DriverNotificationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin-login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'queue',
            builder: (context, state) => const AdminHomeScreen(initialIndex: 1),
          ),
          GoRoute(
            path: 'drivers',
            builder: (context, state) => const AdminHomeScreen(initialIndex: 2),
          ),
          GoRoute(
            path: 'alerts',
            builder: (context, state) => const AdminHomeScreen(initialIndex: 3),
          ),
          GoRoute(
            path: 'add-driver',
            builder: (context, state) => const AddDriverScreen(),
          ),
        ],
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen to auth state changes
    _ref.listen(authStateProvider, (previous, next) {
      if (previous?.value != next.value) {
        notifyListeners();
      }
    });

    // Also listen to profile changes (e.g. status changes from pending to approved)
    _ref.listen(userProfileProvider, (_, __) {
      notifyListeners();
    });
  }
}
