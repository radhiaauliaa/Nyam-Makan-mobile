// models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String
  reportType; // 'user_spam', 'user_abusive', 'restaurant_poor_rating'
  final String targetType; // 'user' or 'restaurant'
  final String targetId; // ID dari user/restaurant yang dilaporkan
  final String targetName;
  final String reportedBy; // ID yang melaporkan (bisa system/owner/user)
  final String reason;
  final Map<String, dynamic>
  evidence; // Bukti (rating history, review list, dll)
  final String status; // 'pending', 'reviewed', 'action_taken', 'dismissed'
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? actionTaken; // 'suspended', 'warned', 'dismissed'

  ReportModel({
    required this.id,
    required this.reportType,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.reportedBy,
    required this.reason,
    this.evidence = const {},
    this.status = 'pending',
    this.adminNotes,
    required this.createdAt,
    this.reviewedAt,
    this.actionTaken,
  });

  // Report Types
  static const String typeUserSpam = 'user_spam'; // 10x rating <2 ke resto sama
  static const String typeUserAbusive = 'user_abusive'; // Komentar jahat
  static const String typeRestaurantPoorRating =
      'restaurant_poor_rating'; // Rating <2 dari banyak user

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      reportType: map['reportType'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      reason: map['reason'] ?? '',
      evidence: Map<String, dynamic>.from(map['evidence'] ?? {}),
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      actionTaken: map['actionTaken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportType': reportType,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'reportedBy': reportedBy,
      'reason': reason,
      'evidence': evidence,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'actionTaken': actionTaken,
    };
  }

  ReportModel copyWith({
    String? id,
    String? reportType,
    String? targetType,
    String? targetId,
    String? targetName,
    String? reportedBy,
    String? reason,
    Map<String, dynamic>? evidence,
    String? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? actionTaken,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reportType: reportType ?? this.reportType,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      reportedBy: reportedBy ?? this.reportedBy,
      reason: reason ?? this.reason,
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Review';
      case 'reviewed':
        return 'Sudah Direview';
      case 'action_taken':
        return 'Tindakan Diambil';
      case 'dismissed':
        return 'Ditolak';
      default:
        return status;
    }
  }
}

// Model untuk suspend account
class AccountSuspension {
  final String? id;
  final String accountId;
  final String accountType; // 'user' or 'restaurant'
  final String reason;
  final String reportId; // Link ke report yang menyebabkan suspend
  final DateTime suspendedAt;
  final DateTime appealDeadline; // 1 minggu dari suspendedAt
  final String status; // 'active', 'appealed', 'permanent', 'lifted'
  final String? appealMessage;
  final bool appealSubmitted;
  final DateTime? appealedAt;
  final String? adminResponse;
  final DateTime? resolvedAt;

  AccountSuspension({
    this.id,
    required this.accountId,
    required this.accountType,
    required this.reason,
    required this.reportId,
    required this.suspendedAt,
    required this.appealDeadline,
    this.status = 'active',
    this.appealMessage,
    this.appealSubmitted = false,
    this.appealedAt,
    this.adminResponse,
    this.resolvedAt,
  });

  factory AccountSuspension.fromMap(Map<String, dynamic> map, String id) {
    return AccountSuspension(
      id: id,
      accountId: map['accountId'] ?? '',
      accountType: map['accountType'] ?? '',
      reason: map['reason'] ?? '',
      reportId: map['reportId'] ?? '',
      suspendedAt: (map['suspendedAt'] as Timestamp).toDate(),
      appealDeadline: (map['appealDeadline'] as Timestamp).toDate(),
      status: map['status'] ?? 'active',
      appealMessage: map['appealMessage'],
      appealSubmitted: map['appealSubmitted'] ?? false,
      appealedAt: map['appealedAt'] != null
          ? (map['appealedAt'] as Timestamp).toDate()
          : null,
      adminResponse: map['adminResponse'],
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'accountType': accountType,
      'reason': reason,
      'reportId': reportId,
      'suspendedAt': Timestamp.fromDate(suspendedAt),
      'appealDeadline': Timestamp.fromDate(appealDeadline),
      'status': status,
      'appealMessage': appealMessage,
      'appealSubmitted': appealSubmitted,
      'appealedAt': appealedAt != null ? Timestamp.fromDate(appealedAt!) : null,
      'adminResponse': adminResponse,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  bool get canAppeal {
    return status == 'active' &&
        DateTime.now().isBefore(appealDeadline) &&
        !appealSubmitted;
  }

  bool get isPermanent {
    return status == 'permanent';
  }

  AccountSuspension copyWith({
    String? id,
    String? accountId,
    String? accountType,
    String? reason,
    String? reportId,
    DateTime? suspendedAt,
    DateTime? appealDeadline,
    String? status,
    String? appealMessage,
    bool? appealSubmitted,
    DateTime? appealedAt,
    String? adminResponse,
    DateTime? resolvedAt,
  }) {
    return AccountSuspension(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      accountType: accountType ?? this.accountType,
      reason: reason ?? this.reason,
      reportId: reportId ?? this.reportId,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      appealDeadline: appealDeadline ?? this.appealDeadline,
      status: status ?? this.status,
      appealMessage: appealMessage ?? this.appealMessage,
      appealSubmitted: appealSubmitted ?? this.appealSubmitted,
      appealedAt: appealedAt ?? this.appealedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
