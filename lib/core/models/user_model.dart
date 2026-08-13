class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'customer' or 'vendor'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  // Convert Firestore Document to UserModel Object
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'customer',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convert UserModel Object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
