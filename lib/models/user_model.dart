import 'dart:ffi';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  // final Array list 
  UserModel(
      {required this.uid,
      required this.email,
      required this.displayName,
      required this.phoneNumber});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}
