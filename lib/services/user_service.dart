// services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data users: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(id)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data user: $e');
    }
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Gagal update user: $e');
    }
  }

  // Suspend user (for admin)
  Future<void> suspendUser(String userId, String reason) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'status': 'suspended',
            'suspensionReason': reason,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Gagal menangguhkan user: $e');
    }
  }

  // Activate user (for admin)
  Future<void> activateUser(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'status': 'active',
            'suspensionReason': null,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Gagal mengaktifkan user: $e');
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '${query}z')
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Gagal mencari users: $e');
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil users by role: $e');
    }
  }

  // Update user statistics
  Future<void> updateUserStats(String userId, {int? reviewCount, int? favoriteCount}) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.now(),
      };
      
      if (reviewCount != null) {
        updateData['reviewCount'] = reviewCount;
      }
      
      if (favoriteCount != null) {
        updateData['favoriteCount'] = favoriteCount;
      }
      
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updateData);
    } catch (e) {
      throw Exception('Gagal update statistik user: $e');
    }
  }

  // Check if username exists
  Future<bool> usernameExists(String username) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Gagal mengecek username: $e');
    }
  }

  // Get user activity count
  Future<Map<String, int>> getUserActivityCount(String userId) async {
    try {
      // Get review count
      QuerySnapshot reviewSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Get reservation count
      QuerySnapshot reservationSnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Get favorite count
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      int favoriteCount = List.from(userDoc['favorites'] ?? []).length;
      
      return {
        'reviews': reviewSnapshot.docs.length,
        'reservations': reservationSnapshot.docs.length,
        'favorites': favoriteCount,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik aktivitas user: $e');
    }
  }
}