import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/admin_model.dart';

class AdminSettingsService {
  final FirebaseFirestore _firestore;

  AdminSettingsService(this._firestore);

  // Reference to the global settings document
  // We use 'queue/settings' because existing rules allow Admins to write to 'queue/{id}'
  DocumentReference get _settingsRef =>
      _firestore.collection('queue').doc('settings');

  // Stream of settings data
  Stream<Map<String, dynamic>> getSettings() {
    return _settingsRef.snapshots().map((doc) {
      if (!doc.exists) {
        // Return defaults if document doesn't exist
        return {
          'queueEnabled': true,
          'maxQueueSize': 50,
          'operatingHours': '06:00 AM - 10:00 PM',
        };
      }
      return doc.data() as Map<String, dynamic>;
    });
  }

  // Update specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    // defined merge: true to avoid overwriting other fields if we use set
    // but update() fails if doc doesn't exist.
    // So we use set with merge.
    await _settingsRef.set({key: value}, SetOptions(merge: true));
  }

  // Toggle Queue Status
  Future<void> setQueueEnabled(bool enabled) async {
    await updateSetting('queueEnabled', enabled);
  }

  // Set Max Drivers
  Future<void> setMaxQueueSize(int size) async {
    await updateSetting('maxQueueSize', size);
  }

  // --- ADMIN MANAGEMENT ---

  // Get Current Admin Profile
  Stream<AdminModel?> getAdminProfile(String uid) {
    return _firestore.collection('admins').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return AdminModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Update Admin Details
  Future<void> updateAdminProfile(String uid, String name) async {
    await _firestore.collection('admins').doc(uid).update({'name': name});
  }

  // Get All Admins
  Stream<List<AdminModel>> getAllAdmins() {
    return _firestore.collection('admins').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Add New Admin (Note: effectively just creates the doc, user still needs auth)
  Future<void> addAdmin(String uid, String email, String name) async {
    await _firestore.collection('admins').doc(uid).set({
      'email': email,
      'name': name,
      'role': 'admin',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Remove Admin
  Future<void> removeAdmin(String uid) async {
    await _firestore.collection('admins').doc(uid).delete();
  }
}

final adminSettingsServiceProvider = Provider<AdminSettingsService>((ref) {
  return AdminSettingsService(FirebaseFirestore.instance);
});

final adminSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminSettingsServiceProvider).getSettings();
});

// Admin Management Providers
final currentAdminProvider = StreamProvider.family<AdminModel?, String>((
  ref,
  uid,
) {
  return ref.watch(adminSettingsServiceProvider).getAdminProfile(uid);
});

final allAdminsProvider = StreamProvider<List<AdminModel>>((ref) {
  return ref.watch(adminSettingsServiceProvider).getAllAdmins();
});
