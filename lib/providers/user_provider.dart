// providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<UserModel> get activeUsers => _users.where((u) => u.isActive).toList();
  List<UserModel> get suspendedUsers => _users.where((u) => u.isSuspended).toList();
  List<UserModel> get regularUsers => _users.where((u) => u.isUser).toList();
  List<UserModel> get ownerUsers => _users.where((u) => u.isOwner).toList();

  // Load all users (for admin)
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await _userService.getAllUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Suspend user (for admin)
  Future<bool> suspendUser(String userId, String reason) async {
    try {
      await _userService.suspendUser(userId, reason);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(status: 'suspended');
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Activate user (for admin)
  Future<bool> activateUser(String userId) async {
    try {
      await _userService.activateUser(userId);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(status: 'active');
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(UserModel user) async {
    try {
      await _userService.updateUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _userService.searchUsers(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Extension untuk copyWith method
extension UserModelCopyWith on UserModel {
  UserModel copyWith({
    String? username,
    String? email,
    String? phone,
    String? profileImage,
    String? status,
    int? reviewCount,
    int? favoriteCount,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      reviewCount: reviewCount ?? this.reviewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}