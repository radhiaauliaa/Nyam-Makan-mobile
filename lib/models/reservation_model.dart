// models/reservation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantImageUrl;
  final String customerName;
  final String customerPhone;
  final int guestCount;
  final DateTime date;
  final String time;
  final String area;
  final List<Map<String, dynamic>> menuItems;
  final double totalAmount;
  final double dpAmount;
  final String paymentMethod;
  final String? paymentProofUrl;
  final String? promoId;
  final String? promoTitle;
  final double? discount;
  final String
  status; // 'pending_review', 'waiting_user_response', 'awaiting_payment', 'payment_review', 'payment_rejected', 'confirmed', 'rejected', 'expired', 'completed', 'cancelled'
  final String? tableGroup;
  final String? tableNumber;
  final String? rejectionReason;
  final String? alternativeTime; // Jam alternatif yang ditawarkan resto
  final bool? paymentVerified; // Apakah bukti transfer sudah diverifikasi
  final DateTime createdAt;
  final DateTime? updatedAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImageUrl,
    required this.customerName,
    required this.customerPhone,
    required this.guestCount,
    required this.date,
    required this.time,
    required this.area,
    required this.menuItems,
    required this.totalAmount,
    required this.dpAmount,
    required this.paymentMethod,
    this.paymentProofUrl,
    this.promoId,
    this.promoTitle,
    this.discount,
    required this.status,
    this.tableGroup,
    this.tableNumber,
    this.rejectionReason,
    this.alternativeTime,
    this.paymentVerified,
    required this.createdAt,
    this.updatedAt,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status'] ?? 'pending_review';
    final paymentProofUrl = map['paymentProofUrl'] as String?;
    final alternativeTime = map['alternativeTime'] as String?;
    String status = rawStatus;

    if (status == 'pending') status = 'pending_review';
    if (status == 'accepted') status = 'confirmed';
    if (status == 'awaiting_payment') {
      if (paymentProofUrl != null && paymentProofUrl.isNotEmpty) {
        status = 'payment_review';
      } else if (alternativeTime != null && alternativeTime.isNotEmpty) {
        status = 'waiting_user_response';
      }
    }

    return Reservation(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      restaurantImageUrl: map['restaurantImageUrl'],
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      guestCount: (map['guestCount'] ?? 0) as int,
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      area: map['area'] ?? 'Indoor',
      menuItems: List<Map<String, dynamic>>.from(map['menuItems'] ?? []),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      dpAmount: (map['dpAmount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'transfer',
      paymentProofUrl: paymentProofUrl,
      promoId: map['promoId'],
      promoTitle: map['promoTitle'],
      discount: map['discount'] != null
          ? (map['discount'] as num).toDouble()
          : null,
      status: status,
      tableGroup: map['tableGroup'],
      tableNumber: map['tableNumber'],
      rejectionReason: map['rejectionReason'],
      alternativeTime: alternativeTime,
      paymentVerified: map['paymentVerified'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImageUrl': restaurantImageUrl,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'guestCount': guestCount,
      'date': Timestamp.fromDate(date),
      'time': time,
      'area': area,
      'menuItems': menuItems,
      'totalAmount': totalAmount,
      'dpAmount': dpAmount,
      'paymentMethod': paymentMethod,
      'paymentProofUrl': paymentProofUrl,
      'promoId': promoId,
      'promoTitle': promoTitle,
      'discount': discount,
      'status': status,
      'tableGroup': tableGroup,
      'tableNumber': tableNumber,
      'rejectionReason': rejectionReason,
      'alternativeTime': alternativeTime,
      'paymentVerified': paymentVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTime {
    return time;
  }

  // Status helpers
  bool get isPendingReview => status == 'pending_review' || status == 'pending';
  bool get isWaitingUserResponse =>
      status == 'waiting_user_response' ||
      (status == 'awaiting_payment' && alternativeTime != null);
  bool get isAwaitingPayment =>
      status == 'awaiting_payment' &&
      (paymentProofUrl == null || paymentProofUrl!.isEmpty) &&
      alternativeTime == null;
  bool get isPaymentReview =>
      status == 'payment_review' ||
      (status == 'awaiting_payment' &&
          paymentProofUrl != null &&
          paymentProofUrl!.isNotEmpty);
  bool get isPaymentRejected => status == 'payment_rejected';
  bool get isConfirmed => status == 'confirmed' || status == 'accepted';
  bool get isRejected =>
      status == 'rejected' || status == 'expired' || status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  // Legacy support for tabs
  // isPending = pending_review + awaiting_payment (masih dalam proses)
  bool get isPending =>
      status == 'pending' ||
      status == 'pending_review' ||
      status == 'waiting_user_response' ||
      status == 'awaiting_payment' ||
      status == 'payment_review' ||
      status == 'payment_rejected';
  // isAccepted = hanya confirmed (benar-benar sudah diterima/selesai)
  bool get isAccepted => status == 'accepted' || status == 'confirmed';

  String get statusLabel {
    switch (status) {
      case 'pending_review':
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'waiting_user_response':
        return 'Menunggu Jawaban Pengguna';
      case 'awaiting_payment':
        if (paymentProofUrl != null && paymentProofUrl!.isNotEmpty) {
          return 'Cek Pembayaran';
        }
        return 'Menunggu Pembayaran';
      case 'payment_review':
        return 'Cek Pembayaran';
      case 'payment_rejected':
        return 'Pembayaran Ditolak';
      case 'confirmed':
      case 'accepted':
        return 'Telah Diterima';
      case 'rejected':
        return 'Ditolak';
      case 'expired':
        return 'Kedaluwarsa';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
