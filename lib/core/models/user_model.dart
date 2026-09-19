class UserModel { // represent 1 registered user
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'customer' or 'vendor'
  final DateTime createdAt;
  final double? customerLatitude; // ni yang save custtomer location
  final double? customerLongitude; // ni jugak
  final String? customerLocationLabel; // dan ini
  final bool customerLocationIsManual;  //ini kalau manual / xletak apa2 (nu;ll)

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.customerLatitude,
    this.customerLongitude,
    this.customerLocationLabel,
    this.customerLocationIsManual = false,
  });

  bool get hasCustomerLocation => // check cust location valid or tak
      customerLatitude != null &&
      customerLongitude != null &&
      customerLatitude!.isFinite &&
      customerLongitude!.isFinite &&
      customerLatitude! >= -90 &&
      customerLatitude! <= 90 &&
      customerLongitude! >= -180 &&
      customerLongitude! <= 180;

  // Convert Firestore Document to UserModel Object
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final customerLocation = map['customerLocation'];
    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'customer',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      customerLatitude: customerLocation is Map
          ? (customerLocation['latitude'] as num?)?.toDouble()
          : null,
      customerLongitude: customerLocation is Map
          ? (customerLocation['longitude'] as num?)?.toDouble()
          : null,
      customerLocationLabel:
          customerLocation is Map ? customerLocation['label'] as String? : null,
      customerLocationIsManual: customerLocation is Map
          ? customerLocation['isManual'] == true
          : false,
    );
  }

  // Convert UserModel Object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt,
      if (hasCustomerLocation)
        'customerLocation': {
          'latitude': customerLatitude,
          'longitude': customerLongitude,
          'label': customerLocationLabel ?? 'Selected location',
          'isManual': customerLocationIsManual,
        },
    };
  }
}
