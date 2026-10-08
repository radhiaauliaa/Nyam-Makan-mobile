// services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import 'notification_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Check for spam rating (10x rating <2 ke resto yang sama)
  Future<void> checkUserSpamRating(String userId, String restaurantId) async {
    try {
      // Ambil review user ke resto ini
      final reviews = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('rating', isLessThan: 2.0)
          .get();

      if (reviews.docs.length >= 10) {
        // Create report otomatis
        await _createAutoReport(
          targetType: 'user',
          targetId: userId,
          reportType: ReportModel.typeUserSpam,
          reason:
              'User memberikan rating <2 sebanyak ${reviews.docs.length}x ke restoran yang sama',
          evidence: {
            'restaurantId': restaurantId,
            'reviewCount': reviews.docs.length,
            'reviewIds': reviews.docs.map((d) => d.id).toList(),
          },
        );
      }
    } catch (e) {
      print('Error checking spam rating: $e');
    }
  }

  // Check restaurant poor rating
  Future<void> checkRestaurantPoorRating(String restaurantId) async {
    try {
      // Get all reviews for restaurant
      final reviews = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      if (reviews.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += (doc.data()['rating'] ?? 0.0);
      }
      double avgRating = totalRating / reviews.docs.length;

      // Count low ratings
      int lowRatingCount = reviews.docs
          .where((doc) => (doc.data()['rating'] ?? 0.0) < 2.0)
          .length;

      // PERBAIKAN: Hanya check resto yang sudah verified dan punya minimal 5 ulasan
      final restaurant = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      final restaurantData = restaurant.data();
      final status = restaurantData?['status'] ?? '';

      // Skip jika bukan resto verified
      if (status != 'verified') {
        print('Skip checking: Restaurant not verified (status: $status)');
        return;
      }

      // Skip jika ulasan kurang dari 5
      if (reviews.docs.length < 5) {
        print(
          'Skip checking: Not enough reviews (${reviews.docs.length} reviews)',
        );
        return;
      }

      // If avg < 2 and more than 50% ulasan buruk
      if (avgRating < 2.0 && lowRatingCount >= (reviews.docs.length * 0.5)) {
        await _createAutoReport(
          targetType: 'restaurant',
          targetId: restaurantId,
          reportType: ReportModel.typeRestaurantPoorRating,
          reason:
              'Restoran mendapat rata-rata rating ${avgRating.toStringAsFixed(1)} dari ${reviews.docs.length} ulasan (${lowRatingCount} ulasan buruk)',
          evidence: {
            'averageRating': avgRating,
            'totalReviews': reviews.docs.length,
            'lowRatingCount': lowRatingCount,
            'restaurantName': restaurant.data()?['name'] ?? '',
          },
        );
      }
    } catch (e) {
      print('Error checking restaurant rating: $e');
    }
  }

  // Create auto-generated report
  Future<void> _createAutoReport({
    required String targetType,
    required String targetId,
    required String reportType,
    required String reason,
    required Map<String, dynamic> evidence,
  }) async {
    try {
      // Check if report already exists
      final existing = await _firestore
          .collection('reports')
          .where('targetId', isEqualTo: targetId)
          .where('reportType', isEqualTo: reportType)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) return; // Already reported

      // Get target name
      String targetName = '';
      if (targetType == 'user') {
        final user = await _firestore.collection('users').doc(targetId).get();
        targetName = user.data()?['name'] ?? 'Unknown User';
      } else {
        targetName = evidence['restaurantName'] ?? 'Unknown Restaurant';
      }

      // Create report
      final reportRef = await _firestore.collection('reports').add({
        'reportType': reportType,
        'targetType': targetType,
        'targetId': targetId,
        'targetName': targetName,
        'reportedBy': 'system',
        'reason': reason,
        'evidence': evidence,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify all admins
      await _notificationService.notifyAdminsAccountReported(
        reportRef.id,
        targetId,
        targetType,
      );
    } catch (e) {
      print('Error creating auto report: $e');
    }
  }

  // Manual report by owner (for abusive user review)
  Future<void> reportUserReview({
    required String userId,
    required String userName,
    required String reviewId,
    required String ownerId,
    required String reason,
  }) async {
    try {
      final reportRef = await _firestore.collection('reports').add({
        'reportType': ReportModel.typeUserAbusive,
        'targetType': 'user',
        'targetId': userId,
        'targetName': userName,
        'reportedBy': ownerId,
        'reason': reason,
        'evidence': {'reviewId': reviewId},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _notificationService.notifyAdminsAccountReported(
        reportRef.id,
        userId,
        'user',
      );
    } catch (e) {
      print('Error reporting user: $e');
      rethrow;
    }
  }

  // Get pending reports (for admin)
  Stream<List<ReportModel>> getPendingReportsStream() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Suspend account
  Future<void> suspendAccount(
    String accountId,
    String accountType,
    String reason,
    int duration,
  ) async {
    try {
      // Create suspension
      final suspensionRef = await _firestore.collection('suspensions').add({
        'accountId': accountId,
        'accountType': accountType,
        'reportId': '', // Will be linked if coming from report
        'reason': reason,
        'suspendedAt': FieldValue.serverTimestamp(),
        'appealDeadline': Timestamp.fromDate(
          DateTime.now().add(Duration(days: duration)),
        ),
        'status': 'active',
        'appealSubmitted': false,
      });

      // Update account status
      final collection = accountType == 'user' ? 'users' : 'restaurants';
      await _firestore.collection(collection).doc(accountId).update({
        'isSuspended': true,
        'suspensionId': suspensionRef.id,
      });

      // Notify account owner
      await _notificationService.notifyAccountSuspended(
        accountId,
        reason,
        duration,
      );
    } catch (e) {
      print('Error suspending account: $e');
      rethrow;
    }
  }

  // Dismiss report
  Future<void> dismissReport(String reportId, String adminNotes) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': 'dismissed',
      'adminNotes': adminNotes,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get suspension for account
  Future<AccountSuspension?> getAccountSuspension(String accountId) async {
    try {
      final snapshot = await _firestore
          .collection('suspensions')
          .where('accountId', isEqualTo: accountId)
          .where('status', whereIn: ['active', 'appealed'])
          .get();

      if (snapshot.docs.isEmpty) return null;
      return AccountSuspension.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting suspension: $e');
      return null;
    }
  }

  // Get reports stream for admin
  Stream<List<ReportModel>> getReportsStream({String? status}) {
    Query query = _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Resolve report (dismiss or accept)
  Future<void> resolveReport(String reportId, String status) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // Submit appeal
  Future<void> submitAppeal(String suspensionId, String appealMessage) async {
    await _firestore.collection('suspensions').doc(suspensionId).update({
      'status': 'appealed',
      'appealMessage': appealMessage,
      'appealedAt': FieldValue.serverTimestamp(),
      'appealSubmitted': true,
    });
  }

  // Auto-check expired appeals (call this periodically)
  Future<void> checkExpiredAppeals() async {
    final now = DateTime.now();
    final suspensions = await _firestore
        .collection('suspensions')
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in suspensions.docs) {
      final suspension = AccountSuspension.fromMap(doc.data(), doc.id);
      if (now.isAfter(suspension.appealDeadline)) {
        // Make permanent
        await _firestore.collection('suspensions').doc(doc.id).update({
          'status': 'permanent',
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
