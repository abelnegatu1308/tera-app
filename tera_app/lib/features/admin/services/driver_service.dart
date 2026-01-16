import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/driver_model.dart';
import '../../../models/trip_model.dart';

class DriverService {
  final FirebaseFirestore _firestore;

  DriverService(this._firestore);

  // Get all drivers (Stream)
  Stream<List<DriverModel>> getAllDrivers() {
    return _firestore
        .collection('drivers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DriverModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get pending drivers (Stream)
  Stream<List<DriverModel>> getPendingDrivers() {
    return _firestore
        .collection('drivers')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DriverModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Approve a driver
  Future<void> approveDriver(String uid) async {
    await _firestore.collection('drivers').doc(uid).update({
      'status': 'approved',
    });
  }

  // Block a driver
  Future<void> blockDriver(String uid) async {
    await _firestore.collection('drivers').doc(uid).update({
      'status': 'blocked',
    });
  }

  // Delete/Remove a driver
  Future<void> deleteDriver(String uid) async {
    await _firestore.collection('drivers').doc(uid).delete();
  }

  // Get single driver (Stream)
  Stream<DriverModel?> getDriver(String uid) {
    return _firestore.collection('drivers').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return DriverModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Upload Profile Image to Cloudinary
  Future<String> uploadProfileImage(File imageFile) async {
    const cloudName = 'drngwjmmw';
    const uploadPreset = 'ay6egrgd';

    print('Starting upload to Cloudinary...');
    print('Cloud Name: $cloudName');
    print('Preset: $uploadPreset');
    print('File Path: ${imageFile.path}');

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      print('Response Status: ${response.statusCode}');

      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      print('Response Body: $responseString');

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        throw Exception(
          'Cloudinary Error: ${response.statusCode} - $responseString',
        );
      }
    } catch (e) {
      print('Upload Exception: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Update Driver Profile
  Future<void> updateDriver(DriverModel driver) async {
    await _firestore
        .collection('drivers')
        .doc(driver.uid)
        .update(driver.toMap());
  }
  // --- TRIP LOGIC ---

  // Get today's trips for a driver
  Stream<List<TripModel>> getTodayTrips(String driverId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TripModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Complete a trip
  Future<void> completeTrip(String driverId) async {
    await _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .add({
          'driverId': driverId,
          'completedAt': FieldValue.serverTimestamp(),
          'status': 'completed',
        });
  }

  // Get ALL trips for a specific driver (History)
  Stream<List<TripModel>> getDriverHistory(String driverId) {
    return _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('trips')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TripModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get ALL completed trips system-wide (Admin Reports)
  // Requires Firestore Index likely
  Stream<List<TripModel>> getAllCompletedTrips() {
    return _firestore
        .collectionGroup('trips')
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TripModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }
}

final driverServiceProvider = Provider<DriverService>((ref) {
  return DriverService(FirebaseFirestore.instance);
});

final allDriversProvider = StreamProvider<List<DriverModel>>((ref) {
  return ref.watch(driverServiceProvider).getAllDrivers();
});

final pendingDriversProvider = StreamProvider<List<DriverModel>>((ref) {
  return ref.watch(driverServiceProvider).getPendingDrivers();
});

final todayTripsProvider = StreamProvider.family<List<TripModel>, String>((
  ref,
  driverId,
) {
  if (driverId.isEmpty) return Stream.value([]);
  return ref.watch(driverServiceProvider).getTodayTrips(driverId);
});

final driverHistoryProvider = StreamProvider.family<List<TripModel>, String>((
  ref,
  driverId,
) {
  if (driverId.isEmpty) return Stream.value([]);
  return ref.watch(driverServiceProvider).getDriverHistory(driverId);
});

final allTripsProvider = StreamProvider<List<TripModel>>((ref) {
  return ref.watch(driverServiceProvider).getAllCompletedTrips();
});
