import 'package:cloud_firestore/cloud_firestore.dart';

class QueueItemModel {
  final String driverId;
  final String driverName;
  final String plateNumber;
  final int order;
  final DateTime joinedAt;
  final String status; // waiting, next, called, skipped

  QueueItemModel({
    required this.driverId,
    required this.driverName,
    required this.plateNumber,
    required this.order,
    required this.joinedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'plateNumber': plateNumber,
      'order': order,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status,
    };
  }

  factory QueueItemModel.fromMap(Map<String, dynamic> map) {
    return QueueItemModel(
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? 'Unknown',
      plateNumber: map['plateNumber'] ?? '',
      order: map['order'] ?? 0,
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'waiting',
    );
  }
}
