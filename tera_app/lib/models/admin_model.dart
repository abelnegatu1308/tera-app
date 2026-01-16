class AdminModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'super_admin' or 'admin'
  final DateTime createdAt;

  AdminModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map, String id) {
    return AdminModel(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? 'Admin',
      role: map['role'] ?? 'admin',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}
