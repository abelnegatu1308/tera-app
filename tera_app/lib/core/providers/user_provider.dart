import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tera_app/features/auth/services/auth_service.dart';

enum UserRole { admin, driver, none }

enum DriverStatus { pending, approved, blocked, none }

class UserProfile {
  final UserRole role;
  final DriverStatus status;
  final Map<String, dynamic> data;

  UserProfile({required this.role, required this.status, required this.data});

  factory UserProfile.empty() =>
      UserProfile(role: UserRole.none, status: DriverStatus.none, data: {});
}

final adminDocStreamProvider = StreamProvider.family<DocumentSnapshot, String>((
  ref,
  uid,
) {
  return FirebaseFirestore.instance.collection('admins').doc(uid).snapshots();
});

final driverDocStreamProvider = StreamProvider.family<DocumentSnapshot, String>(
  (ref, uid) {
    return FirebaseFirestore.instance
        .collection('drivers')
        .doc(uid)
        .snapshots();
  },
);

final userProfileProvider = Provider<AsyncValue<UserProfile>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return AsyncValue.data(UserProfile.empty());
  }

  final adminAsync = ref.watch(adminDocStreamProvider(user.uid));
  final driverAsync = ref.watch(driverDocStreamProvider(user.uid));

  // If either is loading, we can return loading or handle it.
  if (adminAsync.isLoading || driverAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // If we have errors, we might want to expose them or fallback.
  if (adminAsync.hasError)
    return AsyncValue.error(adminAsync.error!, adminAsync.stackTrace!);
  if (driverAsync.hasError)
    return AsyncValue.error(driverAsync.error!, driverAsync.stackTrace!);

  final adminDoc = adminAsync.value;
  if (adminDoc != null && adminDoc.exists) {
    return AsyncValue.data(
      UserProfile(
        role: UserRole.admin,
        status: DriverStatus.none,
        data: adminDoc.data() as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final driverDoc = driverAsync.value;
  if (driverDoc != null && driverDoc.exists) {
    final data = driverDoc.data() as Map<String, dynamic>? ?? {};
    var statusStr = data['status'] ?? 'pending';

    // Backward compatibility or manual override check
    if (data['approved'] == true) {
      statusStr = 'approved';
    }

    DriverStatus status;
    switch (statusStr) {
      case 'approved':
        status = DriverStatus.approved;
        break;
      case 'blocked':
        status = DriverStatus.blocked;
        break;
      default:
        status = DriverStatus.pending;
    }

    return AsyncValue.data(
      UserProfile(role: UserRole.driver, status: status, data: data),
    );
  }

  return AsyncValue.data(UserProfile.empty());
});
