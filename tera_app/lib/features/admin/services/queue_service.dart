import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tera_app/models/queue_item_model.dart';

final queueServiceProvider = Provider<QueueService>((ref) {
  return QueueService(FirebaseFirestore.instance);
});

final queueStreamProvider = StreamProvider<List<QueueItemModel>>((ref) {
  return ref.watch(queueServiceProvider).getQueue();
});

class QueueService {
  final FirebaseFirestore _firestore;

  QueueService(this._firestore);

  // Get real-time queue
  Stream<List<QueueItemModel>> getQueue() {
    return _firestore.collection('queue').orderBy('order').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return QueueItemModel.fromMap(doc.data());
      }).toList();
    });
  }

  // Add driver to queue (Admin only usually, or driver join)
  Future<void> addToQueue(String driverId, String name, String plate) async {
    // Get the current highest order
    final query = await _firestore
        .collection('queue')
        .orderBy('order', descending: true)
        .limit(1)
        .get();

    int nextOrder = 1;
    if (query.docs.isNotEmpty) {
      nextOrder = (query.docs.first.data()['order'] as int) + 1;
    }

    final queueItem = QueueItemModel(
      driverId: driverId,
      driverName: name,
      plateNumber: plate,
      order: nextOrder,
      joinedAt: DateTime.now(),
      status: 'waiting',
    );

    await _firestore.collection('queue').doc(driverId).set(queueItem.toMap());
  }

  // Swap positions
  Future<void> moveUp(String driverId) async {
    final doc = await _firestore.collection('queue').doc(driverId).get();
    if (!doc.exists) return;
    final currentOrder = doc.data()!['order'] as int;
    if (currentOrder <= 1) return;

    // Find the document directly above
    final aboveQuery = await _firestore
        .collection('queue')
        .where('order', isLessThan: currentOrder)
        .orderBy('order', descending: true)
        .limit(1)
        .get();

    if (aboveQuery.docs.isEmpty) return;

    final aboveDoc = aboveQuery.docs.first;
    final aboveId = aboveDoc.id;
    final aboveOrder = aboveDoc.data()['order'] as int;

    // Transaction to swap
    await _firestore.runTransaction((transaction) async {
      transaction.update(_firestore.collection('queue').doc(driverId), {
        'order': aboveOrder,
      });
      transaction.update(_firestore.collection('queue').doc(aboveId), {
        'order': currentOrder,
      });
    });
  }

  Future<void> moveDown(String driverId) async {
    final doc = await _firestore.collection('queue').doc(driverId).get();
    if (!doc.exists) return;
    final currentOrder = doc.data()!['order'] as int;

    // Find the document directly below
    final belowQuery = await _firestore
        .collection('queue')
        .where('order', isGreaterThan: currentOrder)
        .orderBy('order', descending: false)
        .limit(1)
        .get();

    if (belowQuery.docs.isEmpty) return;

    final belowDoc = belowQuery.docs.first;
    final belowId = belowDoc.id;
    final belowOrder = belowDoc.data()['order'] as int;

    // Transaction to swap
    await _firestore.runTransaction((transaction) async {
      transaction.update(_firestore.collection('queue').doc(driverId), {
        'order': belowOrder,
      });
      transaction.update(_firestore.collection('queue').doc(belowId), {
        'order': currentOrder,
      });
    });
  }

  // Remove from queue
  Future<void> removeFromQueue(String driverId) async {
    await _firestore.collection('queue').doc(driverId).delete();
  }

  // Reset entire queue
  Future<void> resetQueue() async {
    final query = await _firestore.collection('queue').get();
    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
