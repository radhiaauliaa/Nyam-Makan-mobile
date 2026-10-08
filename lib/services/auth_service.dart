// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<UserModel?> get currentUser {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        return await _getUserData(user.uid);
      }
      return null;
    });
  }

  // Login user
  Future<UserModel?> login(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      UserModel? user = await _getUserData(userCredential.user!.uid);
      
      if (user != null && user.role == role) {
        return user;
      } else {
        await _auth.signOut();
        throw Exception('Role tidak sesuai');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Login gagal: $e');
    }
  }

  // Register user
  Future<UserModel> register(String email, String password, String username, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      UserModel user = UserModel(
        id: userCredential.user!.uid,
        username: username,
        email: email,
        role: role,
        status: 'active',
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap());
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Registrasi gagal: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<UserModel?> _getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data user: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Gagal mengirim email reset password: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Gagal update profil: $e');
    }
  }

  // Helper method for auth error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun dinonaktifkan';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }
}