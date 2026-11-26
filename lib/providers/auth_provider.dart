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

  String _normalizeRole(String role) {
    switch (role) {
      case 'owner':
      case 'Pemilik Restoran':
        return 'Pemilik Resto';
      case 'user':
        return 'Pengguna';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  // Muat user aktif saat app dibuka / rebuild
  Future<UserModel?> restoreSession() async {
    final currentUser = await _auth.authStateChanges().first;
    if (currentUser == null) {
      _user = null;
      return null;
    }

    return loadCurrentUser(authenticatedUser: currentUser);
  }

  Future<UserModel?> loadCurrentUser({User? authenticatedUser}) async {
    final currentUser = authenticatedUser ?? _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!doc.exists) {
        _user = null;
        return null;
      }

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
      final userRole = _normalizeRole(data['role']?.toString() ?? 'user');

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
      return _user;
    } catch (e) {
      print('Error loading current user: $e');
      rethrow;
    }
  }

  // Login pakai username dan password
  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    _user = null;
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
      final storedRole = _normalizeRole(userData['role']?.toString() ?? '');
      if (!['Pengguna', 'Pemilik Resto', 'Admin'].contains(storedRole)) {
        throw Exception('Role akun tidak valid. Hubungi administrator.');
      }

      // CEK STATUS AKUN DULU SEBELUM LOGIN
      final userStatus = userData['status'] ?? 'active';
      if (userStatus == 'suspended') {
        // Cek apakah ini pemilik resto yang ditolak

        if (storedRole == 'Pemilik Resto') {
          // Cari info resto untuk mendapatkan alasan penolakan
          final restoSnapshot = await _firestore
              .collection('restaurants')
              .where('ownerId', isEqualTo: userId)
              .limit(1)
              .get();

          String message =
              'Akun Anda telah dinonaktifkan karena pengajuan restoran ditolak.';

          if (restoSnapshot.docs.isNotEmpty) {
            final restoData = restoSnapshot.docs.first.data();
            final restoName = restoData['name'] ?? 'restoran Anda';
            final restoStatus = restoData['status'] ?? '';

            if (restoStatus == 'rejected') {
              message =
                  'Pengajuan restoran "$restoName" ditolak.\n\n' +
                  'Akun Anda telah dinonaktifkan.\n\n' +
                  'Silakan hubungi admin untuk informasi lebih lanjut: admin@nyammakan.com';
            }
          }

          throw Exception(message);
        } else {
          throw Exception(
            'Akun Anda telah ditangguhkan. Silakan hubungi admin.',
          );
        }
      }

      // Login pakai email dan password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

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

      _user = UserModel(
        id: userId,
        email: email,
        username: userData['username'] ?? '',
        role: storedRole,
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
      final message = _getLoginAuthErrorMessage(e.code);
      _error = message;
      _isLoading = false;
      notifyListeners();
      throw Exception(message);
    } on FirebaseException catch (e) {
      final message = switch (e.code) {
        'unavailable' || 'deadline-exceeded' =>
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda, lalu coba lagi.',
        _ => 'Terjadi kendala saat login. Silakan coba lagi beberapa saat.',
      };
      _error = message;
      _isLoading = false;
      notifyListeners();
      throw Exception(message);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _error = message;
      _isLoading = false;
      notifyListeners();
      throw Exception(message);
    }
  }

  String _getLoginAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Username atau password yang dimasukkan salah. Periksa kembali lalu coba lagi.';
      case 'user-not-found':
        return 'Username tidak ditemukan. Periksa kembali username Anda.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan. Silakan hubungi admin untuk bantuan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Tunggu beberapa saat sebelum mencoba lagi.';
      case 'network-request-failed':
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda, lalu coba lagi.';
      case 'invalid-email':
        return 'Format email akun tidak valid. Silakan hubungi admin untuk bantuan.';
      default:
        return 'Login gagal. Periksa kembali username dan password Anda, lalu coba lagi.';
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

      await _auth.signOut();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
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
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // providers/auth_provider.dart - tambahkan method ini
  Future<bool> hasRestaurant() async {
    if (_user == null ||
        (_user!.role != 'owner' && _user!.role != 'Pemilik Resto')) {
      return false;
    }

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
      final userRole = _normalizeRole(data['role']?.toString() ?? 'user');

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
  Future<UserCredential?> signInWithGoogle() async {
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

      final registeredUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: googleUser.email)
          .limit(1)
          .get();
      if (registeredUser.docs.isEmpty) {
        throw Exception(
          'Akun belum terdaftar. Silakan daftar terlebih dahulu.',
        );
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
        await _auth.signOut();
        throw Exception(
          'Akun belum terdaftar. Silakan daftar terlebih dahulu.',
        );
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

        final storedRole = _normalizeRole(userData['role']?.toString() ?? '');
        if (!['Pengguna', 'Pemilik Resto', 'Admin'].contains(storedRole)) {
          await _auth.signOut();
          throw Exception('Role akun tidak valid. Hubungi administrator.');
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
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
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
