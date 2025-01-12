class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final String address;
  final DateTime birthDate;
  final String gender;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.address,
    required this.birthDate,
    required this.gender,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'address': address,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      birthDate: DateTime.parse(map['birthDate'] ?? DateTime.now().toIso8601String()),
      gender: map['gender'] ?? '',
    );
  }
}