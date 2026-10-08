// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String role; // 'Pengguna', 'Pemilik Resto', 'Admin'
  final String status; // 'active', 'suspended'
  final String? phone;
  final String? address;
  final String? profileImage;
  final int reviewCount;
  final int favoriteCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.status = 'active',
    this.phone,
    this.address,
    this.profileImage,
    this.reviewCount = 0,
    this.favoriteCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      status: map['status'] ?? 'active',
      phone: map['phone'],
      address: map['address'],
      profileImage: map['profileImage'],
      reviewCount: map['reviewCount'] ?? 0,
      favoriteCount: map['favoriteCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'status': status,
      'phone': phone,
      'address': address,
      'profileImage': profileImage,
      'reviewCount': reviewCount,
      'favoriteCount': favoriteCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get displayRole {
    switch (role) {
      case 'Pengguna':
        return 'Pengguna';
      case 'Pemilik Resto':
        return 'Pemilik Restoran';
      case 'Admin':
        return 'Administrator';
      default:
        return role;
    }
  }

  bool get isAdmin => role == 'Admin';
  bool get isOwner => role == 'Pemilik Resto';
  bool get isUser => role == 'Pengguna';
  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? status,
    String? phone,
    String? address,
    String? profileImage,
    int? reviewCount,
    int? favoriteCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      reviewCount: reviewCount ?? this.reviewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
