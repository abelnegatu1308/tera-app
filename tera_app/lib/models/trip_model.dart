import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TripModel {
  final String id;
  final String driverId;
  final DateTime completedAt;
  final String status;

  TripModel({
    required this.id,
    required this.driverId,
    required this.completedAt,
    required this.status,
  });

  factory TripModel.fromMap(String id, Map<String, dynamic> map) {
    return TripModel(
      id: id,
      driverId: map['driverId'] ?? '',
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : DateTime.now(), // Fallback to now if null (pending write)
      status: map['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'completedAt': Timestamp.fromDate(completedAt),
      'status': status,
    };
  }

  String get dateString => DateFormat('MMM d').format(completedAt);
  String get timeString => DateFormat('h:mm a').format(completedAt);
  String get queueDuration => '25 min'; // Placeholder
}
