import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream để theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký tài khoản mới
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required String address,
    required DateTime birthDate,
    required String gender,
  }) async {
    try {
      // Tạo user authentication
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user != null) {
        // Tạo user profile trong Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': displayName,
          'address': address,
          'birthDate': birthDate.toIso8601String(),
          'gender': gender,
          'createdAt': DateTime.now().toIso8601String(),
        });
        // Trả về UserModel với đầy đủ thông tin
        return UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          phone: phone,
          address: address,
          birthDate: birthDate,
          gender: gender,
        );
      }
    } catch (e) {
      print('Lỗi đăng ký: ${e.toString()}');
      throw e;
    }
  }

  // Đăng nhập
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      if (user != null) {
        // Lấy thông tin user từ Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
    return null;
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Lấy thông tin user hiện tại
  Future<UserModel?> getCurrentUser() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
