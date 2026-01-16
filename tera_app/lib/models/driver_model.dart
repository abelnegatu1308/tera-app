class DriverModel {
  final String uid;
  final String name;
  final String phone;
  final String plateNumber;
  final String licenseNumber;
  final String status; // pending, approved, blocked
  final String? photoUrl;

  DriverModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.plateNumber,
    required this.licenseNumber,
    required this.status,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'plateNumber': plateNumber,
      'licenseNumber': licenseNumber,
      'status': status,
      'photoUrl': photoUrl,
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      status: map['status'] ?? 'pending',
      photoUrl: map['photoUrl'],
    );
  }
}
