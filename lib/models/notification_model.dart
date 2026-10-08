// models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId; // User/Owner/Admin yang terima notifikasi
  final String recipientType; // 'user', 'owner', 'admin'
  final String type; // Tipe notifikasi
  final String title;
  final String message;
  final Map<String, dynamic>
  data; // Data tambahan (reservationId, restaurantId, dll)
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  // Notification Types
  // Reservations
  static const String typeReservationCreated = 'reservation_created';
  static const String typeReservationApproved = 'reservation_approved';
  static const String typeReservationRejected = 'reservation_rejected';
  static const String typeReservationNew = 'reservation_new';
  static const String typeReservationAlternativeTime =
      'reservation_alternative_time';
  static const String typeReservationConfirmed = 'reservation_confirmed';
  // Payments
  static const String typePaymentReceived = 'payment_received';
  static const String typePaymentVerified = 'payment_verified';
  static const String typePaymentRejected = 'payment_rejected';
  // Reviews
  static const String typeReviewNew = 'review_new';
  static const String typeReviewReply = 'review_reply';
  // Restaurant
  static const String typeRestaurantNew = 'restaurant_new';
  static const String typeRestaurantApproved = 'restaurant_approved';
  static const String typeRestaurantRejected = 'restaurant_rejected';
  static const String typeRestaurantSuspended = 'restaurant_suspended';
  // Account
  static const String typeAccountReported = 'account_reported';
  static const String typeAccountSuspended = 'account_suspended';
  static const String typeAppealSubmitted = 'appeal_submitted';
  static const String typeAppealApproved = 'appeal_approved';
  static const String typeAppealRejected = 'appeal_rejected';

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      recipientId: map['recipientId'] ?? '',
      recipientType: map['recipientType'] ?? 'user',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'recipientType': recipientType,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? recipientType,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get iconData {
    switch (type) {
      case typeReservationApproved:
      case typePaymentVerified:
        return '✅';
      case typeReservationRejected:
      case typePaymentRejected:
        return '❌';
      case typeReservationNew:
        return '📅';
      case typeReviewNew:
        return '⭐';
      case typeRestaurantNew:
        return '🍽️';
      case typeAccountReported:
        return '⚠️';
      case typeAccountSuspended:
        return '🚫';
      case typeAppealSubmitted:
        return '📝';
      case typeAppealApproved:
        return '✔️';
      case typeAppealRejected:
        return '✖️';
      default:
        return '🔔';
    }
  }
}
