import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _auth.currentUser != null;

  // Muat user aktif saat app dibuka / rebuild
  Future<void> loadCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!doc.exists) return;

      final data = doc.data()!;
      DateTime createdAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      } else {
        createdAt = DateTime.now();
      }

      DateTime? updatedAt;
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      }

      // Normalisasi role
      String userRole = data['role'] ?? 'user';
      if (userRole == 'owner') userRole = 'Pemilik Resto';
      if (userRole == 'user') userRole = 'Pengguna';
      if (userRole == 'admin') userRole = 'Admin';

      _user = UserModel(
        id: currentUser.uid,
        email: data['email'] ?? '',
        username: data['username'] ?? '',
        role: userRole,
        status: data['status'] ?? 'active',
        phone: data['phone'],
        address: data['address'],
        profileImage: data['profileImage'],
        reviewCount: data['reviewCount'] ?? 0,
        favoriteCount: data['favoriteCount'] ?? 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      notifyListeners();
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  // Login pakai username dan password
  Future<void> login(String username, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Cari user berdasarkan username
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Username tidak ditemukan');
      }

      final userData = querySnapshot.docs.first.data();
      final email = userData['email'];
      final userId = querySnapshot.docs.first.id;

      // CEK STATUS AKUN DULU SEBELUM LOGIN
      final userStatus = userData['status'] ?? 'active';
      if (userStatus == 'suspended') {
        // Cek apakah ini pemilik resto yang ditolak
        final storedRole = userData['role'] ?? '';
        String normalizedStoredRole = storedRole;
        if (storedRole == 'owner') normalizedStoredRole = 'Pemilik Resto';
        
        if (normalizedStoredRole == 'Pemilik Resto') {
          // Cari info resto untuk mendapatkan alasan penolakan
          final restoSnapshot = await _firestore
              .collection('restaurants')
              .where('ownerId', isEqualTo: userId)
              .limit(1)
              .get();
          
          String message = 'Akun Anda telah dinonaktifkan karena pengajuan restoran ditolak.';
          
          if (restoSnapshot.docs.isNotEmpty) {
            final restoData = restoSnapshot.docs.first.data();
            final restoName = restoData['name'] ?? 'restoran Anda';
            final restoStatus = restoData['status'] ?? '';
            
            if (restoStatus == 'rejected') {
              message = 'Pengajuan restoran "$restoName" ditolak.\n\n' +
                  'Akun Anda telah dinonaktifkan.\n\n' +
                  'Silakan hubungi admin untuk informasi lebih lanjut: admin@nyammakan.com';
            }
          }
          
          throw Exception(message);
        } else {
          throw Exception('Akun Anda telah ditangguhkan. Silakan hubungi admin.');
        }
      }

      // Login pakai email dan password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Cek role cocok
      final storedRole = userData['role'] ?? '';
      String normalizedStoredRole = storedRole;
      if (storedRole == 'owner') normalizedStoredRole = 'Pemilik Resto';
      if (storedRole == 'user') normalizedStoredRole = 'Pengguna';
      if (storedRole == 'admin') normalizedStoredRole = 'Admin';

      if (normalizedStoredRole != role) {
        await _auth.signOut();
        throw Exception(
          'Role tidak sesuai. Silakan login sebagai $normalizedStoredRole',
        );
      }

      // Simpan user ke state provider
      DateTime createdAt;
      if (userData['createdAt'] is Timestamp) {
        createdAt = (userData['createdAt'] as Timestamp).toDate();
      } else {
        createdAt = DateTime.now();
      }

      DateTime? updatedAt;
      if (userData['updatedAt'] is Timestamp) {
        updatedAt = (userData['updatedAt'] as Timestamp).toDate();
      }

      String finalRole = storedRole;
      if (storedRole == 'owner') finalRole = 'Pemilik Resto';
      if (storedRole == 'user') finalRole = 'Pengguna';
      if (storedRole == 'admin') finalRole = 'Admin';

      _user = UserModel(
        id: userId,
        email: email,
        username: userData['username'] ?? '',
        role: finalRole,
        status: userData['status'] ?? 'active',
        phone: userData['phone'],
        address: userData['address'],
        profileImage: userData['profileImage'],
        reviewCount: userData['reviewCount'] ?? 0,
        favoriteCount: userData['favoriteCount'] ?? 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      print('Login success: ${_user?.username} (${_user?.role})');
      _isLoading = false;
      notifyListeners();

      // Save FCM token
      if (_user?.id != null) {
        try {
          await FCMService.saveTokenToFirestore(_user!.id);
        } catch (e) {
          print('Warning: Failed to save FCM token: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      throw Exception(e.message ?? 'Firebase Auth error');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception(e.toString());
    }
  }

  // 🔹 Register
  Future<void> register(
    String email,
    String password,
    String username,
    String role,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Cek username
      final usernameDoc = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameDoc.docs.isNotEmpty) {
        throw 'Username already exists';
      }

      // Buat user baru
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        id: userCredential.user!.uid,
        email: email,
        username: username,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());

      _user = user;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e.toString();
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    try {
      print('AuthProvider: Starting logout...');

      // Reset state SEBELUM signOut
      _isLoading = false;
      _error = null;
      _user = null; // CLEAR USER
      notifyListeners();

      print('AuthProvider: State cleared, now signing out from Firebase...');

      // Perform logout
      await _auth.signOut();

      print('AuthProvider: Logout completed successfully');
    } catch (e) {
      print('AuthProvider: Logout error - $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update user's role (used during role selection / onboarding)
  Future<void> updateUserRole(String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid ?? _user?.id;
      if (uid == null) throw Exception('No authenticated user');

      // Update Firestore document
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local copy if available
      if (_user != null) {
        _user = _user!.copyWith(role: role, updatedAt: DateTime.now());
      } else {
        // reload user if needed
        await loadCurrentUser();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // providers/auth_provider.dart - tambahkan method ini
  Future<bool> hasRestaurant() async {
    if (_user == null ||
        (_user!.role != 'owner' && _user!.role != 'Pemilik Resto'))
      return false;

    try {
      final querySnapshot = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: _user!.id)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking restaurant: $e');
      return false;
    }
  }

  // Refresh user data dari Firestore
  Future<void> refreshUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      DateTime createdAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      } else {
        createdAt = DateTime.now();
      }

      DateTime? updatedAt;
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      }

      // Normalisasi role
      String userRole = data['role'] ?? 'user';
      if (userRole == 'owner') userRole = 'Pemilik Resto';
      if (userRole == 'user') userRole = 'Pengguna';
      if (userRole == 'admin') userRole = 'Admin';

      _user = UserModel(
        id: currentUser.uid,
        email: data['email'] ?? '',
        username: data['username'] ?? '',
        role: userRole,
        status: data['status'] ?? 'active',
        phone: data['phone'],
        address: data['address'],
        profileImage: data['profileImage'],
        reviewCount: data['reviewCount'] ?? 0,
        favoriteCount: data['favoriteCount'] ?? 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      notifyListeners();
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 🔹 Google Sign-In
  Future<UserCredential?> signInWithGoogle(String role) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Sign out first to always show account picker
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user document for first-time Google sign-in
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'username':
              userCredential.user!.displayName ??
              userCredential.user!.email!.split('@')[0],
          'role': role,
          'status': 'active',
          'profileImage': userCredential.user!.photoURL,
          'phone': userCredential.user!.phoneNumber,
          'reviewCount': 0,
          'favoriteCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Cek apakah user ditangguhkan
        final userData = userDoc.data()!;
        final userStatus = userData['status'] ?? 'active';
        if (userStatus == 'suspended') {
          await _auth.signOut();
          throw Exception(
            'Akun Anda telah ditangguhkan. Silakan hubungi admin.',
          );
        }

        // Cek role cocok
        String storedRole = userData['role'] ?? '';
        String normalizedStoredRole = storedRole;
        if (storedRole == 'owner') normalizedStoredRole = 'Pemilik Resto';
        if (storedRole == 'user') normalizedStoredRole = 'Pengguna';
        if (storedRole == 'admin') normalizedStoredRole = 'Admin';

        if (normalizedStoredRole != role) {
          await _auth.signOut();
          throw Exception(
            'Role tidak sesuai. Silakan login sebagai $normalizedStoredRole',
          );
        }
      }

      // Load user data
      await loadCurrentUser();

      // Save FCM token
      if (_user?.id != null) {
        try {
          await FCMService.saveTokenToFirestore(_user!.id);
        } catch (e) {
          print('Warning: Failed to save FCM token: $e');
        }
      }

      _isLoading = false;
      notifyListeners();

      return userCredential;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      print('Google Sign-In Error: $e');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Get Google account email only (for registration form)
  Future<String?> getGoogleAccountEmail() async {
    try {
      // Sign out first to always show account picker
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Return email and sign out (don't create Firebase account yet)
      final email = googleUser.email;
      await _googleSignIn.signOut();

      return email;
    } catch (e) {
      print('Get Google Email Error: $e');
      return null;
    }
  }

  // 🔹 Send Password Reset Email (Firebase Native)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('Send reset email error: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw Exception('Email tidak terdaftar');
      } else if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid');
      } else {
        throw Exception('Gagal mengirim email reset password');
      }
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // 🔹 Verify Password Reset Code
  Future<bool> verifyPasswordResetCode(String code) async {
    try {
      await _auth.verifyPasswordResetCode(code);
      return true;
    } catch (e) {
      print('Invalid reset code: $e');
      return false;
    }
  }

  // 🔹 Confirm Password Reset with Code
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      print('Password reset successful');
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.code} - ${e.message}');
      if (e.code == 'expired-action-code') {
        throw Exception('Kode verifikasi sudah kadaluarsa');
      } else if (e.code == 'invalid-action-code') {
        throw Exception('Kode verifikasi tidak valid');
      } else if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah');
      } else {
        throw Exception('Gagal mereset password');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // 🔹 Get Email from Username (untuk forgot password)
  Future<String?> getEmailFromUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.data()['email'];
    } catch (e) {
      print('Error getting email from username: $e');
      return null;
    }
  }

  // 🔹 Get Email from Phone (untuk forgot password)
  Future<String?> getEmailFromPhone(String phone) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.data()['email'];
    } catch (e) {
      print('Error getting email from phone: $e');
      return null;
    }
  }
}
