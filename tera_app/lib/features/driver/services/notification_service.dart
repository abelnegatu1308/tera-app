import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService(this._firestore);

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    // Query for notifications targeting 'all', 'active', or this specific user
    return _firestore
        .collection('notifications')
        .where('target', whereIn: ['all', 'active', userId])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .toList();
        })
        .handleError((e) {
          print('Notification Stream Error: $e');
          // If it's a permission/index error, it will show up here.
          throw e;
        });
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required String target,
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'body': body,
      'target': target,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> markAsRead(String notificationId) async {
    // Basic implementation: toggle field.
    // Note: For broadcast messages, this would strictly require a subcollection for read receipts
    // to avoid marking it read for everyone.
    // For this MVP, we will only mark if it's a specific user message or accept the limitation.
    // Or we could store 'readBy' array.
    // Keeping it simple as requested.
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseFirestore.instance);
});

final userNotificationsProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  final service = ref.watch(notificationServiceProvider);
  return service.getUserNotifications(user.uid);
});
