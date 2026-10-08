// services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Create notification (compatible with FCMService format)
  Future<void> createNotification({
    required String recipientId,
    required String recipientType,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'userId': recipientId, // FCMService uses 'userId'
        'recipientId': recipientId, // Keep for backward compatibility
        'recipientType': recipientType,
        'type': type,
        'title': title,
        'body': message, // FCMService uses 'body'
        'message': message, // Keep for backward compatibility
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Notification created: $title -> $recipientId');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  // Get notifications stream
  Stream<List<NotificationModel>> getNotificationsStream(String recipientId) {
    return _firestore
        .collection(_collection)
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get unread count stream
  Stream<int> getUnreadCountStream(String recipientId) {
    return _firestore
        .collection(_collection)
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all as read
  Future<void> markAllAsRead(String recipientId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection(_collection)
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // NOTIFICATION HELPERS - Reservation
  Future<void> notifyReservationCreated(
    String userId,
    String restaurantName,
    String reservationId,
  ) async {
    await createNotification(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationModel.typeReservationCreated,
      title: 'Reservasi Menunggu Persetujuan',
      message:
          'Reservasi Anda di $restaurantName sedang menunggu persetujuan dari pihak restoran.',
      data: {'reservationId': reservationId},
    );
  }

  Future<void> notifyReservationApproved(
    String userId,
    String restaurantName,
    String reservationId,
  ) async {
    await createNotification(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationModel.typeReservationApproved,
      title: 'Reservasi Anda Telah Disetujui!',
      message:
          'Reservasi Anda di $restaurantName telah disetujui. Silakan lanjutkan untuk melakukan pembayaran.',
      data: {'reservationId': reservationId},
    );
  }

  Future<void> notifyReservationRejected(
    String userId,
    String restaurantName,
    String reservationId,
    String? reason,
  ) async {
    await createNotification(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationModel.typeReservationRejected,
      title: 'Reservasi Anda Ditolak',
      message:
          'Mohon maaf, reservasi Anda di $restaurantName ditolak. ${reason != null && reason.isNotEmpty ? 'Alasan: $reason' : 'Silakan coba reservasi di waktu lain.'}',
      data: {'reservationId': reservationId},
    );
  }

  Future<void> notifyNewReservation(
    String ownerId,
    String customerName,
    String reservationId,
  ) async {
    await createNotification(
      recipientId: ownerId,
      recipientType: 'owner',
      type: NotificationModel.typeReservationNew,
      title: 'Reservasi Baru Telah Masuk!',
      message:
          'Reservasi baru dari $customerName telah masuk. Silakan segera diproses.',
      data: {'reservationId': reservationId},
    );
  }

  Future<void> notifyReservationConfirmed(
    String userId,
    String restaurantName,
    String reservationDate,
    String reservationTime,
    String reservationId,
  ) async {
    await createNotification(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationModel.typeReservationConfirmed,
      title: 'Reservasi Anda Telah Dikonfirmasi!',
      message:
          'Selamat! Pembayaran Anda telah dikonfirmasi oleh $restaurantName. Reservasi Anda pada $reservationDate pukul $reservationTime telah terkonfirmasi. Kami tunggu kedatangan Anda!',
      data: {'reservationId': reservationId},
    );
  }

  Future<void> notifyPaymentReceived(
    String ownerId,
    String reservationId,
  ) async {
    await createNotification(
      recipientId: ownerId,
      recipientType: 'owner',
      type: NotificationModel.typePaymentReceived,
      title: 'Pembayaran Baru Diterima!',
      message:
          'Reservasi ID: $reservationId telah melakukan pembayaran. Harap segera dikonfirmasi untuk menyelesaikan proses reservasi.',
      data: {'reservationId': reservationId},
    );
  }

  Future<void> notifyAlternativeTime(
    String userId,
    String restaurantName,
    String alternativeTime,
    String reservationId,
  ) async {
    await createNotification(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationModel.typeReservationAlternativeTime,
      title: 'Penawaran Waktu Alternatif',
      message: '$restaurantName menawarkan waktu: $alternativeTime',
      data: {'reservationId': reservationId},
    );
  }

  Future<void> notifyPaymentVerified(
    String userId,
    String restaurantName,
    String reservationId,
  ) async {
    await createNotification(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationModel.typePaymentVerified,
      title: 'Pembayaran Terverifikasi',
      message:
          'Pembayaran di $restaurantName terverifikasi. Reservasi dikonfirmasi!',
      data: {'reservationId': reservationId},
    );
  }

  Future<void> notifyPaymentRejected(
    String userId,
    String restaurantName,
    String reservationId,
    String reason,
  ) async {
    await createNotification(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationModel.typePaymentRejected,
      title: 'Pembayaran Ditolak',
      message:
          'Bukti pembayaran di $restaurantName ditolak. Silakan upload ulang.',
      data: {'reservationId': reservationId},
    );
  }

  // NOTIFICATION HELPERS - Review
  Future<void> notifyNewReview(
    String ownerId,
    String userName,
    String restaurantId,
    double rating,
  ) async {
    await createNotification(
      recipientId: ownerId,
      recipientType: 'owner',
      type: NotificationModel.typeReviewNew,
      title: 'Ulasan Baru Telah Masuk!',
      message: '$userName memberikan ulasan $rating⭐ untuk restoran Anda.',
      data: {'restaurantId': restaurantId},
    );
  }

  Future<void> notifyReviewReply(
    String userId,
    String restaurantName,
    String reviewId,
  ) async {
    await createNotification(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationModel.typeReviewReply,
      title: 'Ulasan Anda Dibalas!',
      message:
          '$restaurantName telah membalas ulasan Anda. Lihat balasan dari pemilik restoran.',
      data: {'reviewId': reviewId},
    );
  }

  // NOTIFICATION HELPERS - Admin & Restaurant
  Future<void> notifyAdminsNewRestaurant(
    String restaurantName,
    String restaurantId,
  ) async {
    try {
      print(
        '🔔 Sending notification to admins for restaurant: $restaurantName',
      );

      // Check ALL users first to debug
      final allUsers = await _firestore.collection('users').get();
      print('📋 Total users in database: ${allUsers.docs.length}');

      for (var user in allUsers.docs) {
        final userData = user.data();
        print('   User ${user.id}: role = "${userData['role']}"');
      }

      // Query for Admin role (sesuai database)
      final allAdmins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Admin')
          .get();

      print('📋 Found ${allAdmins.docs.length} admins with role "Admin"');

      if (allAdmins.docs.isEmpty) {
        print('⚠️ No admin users found with role "Admin"!');
        print(
          '⚠️ Please check your database and ensure at least one user has role set to "Admin"',
        );
        return;
      }

      print('📋 Total admins found: ${allAdmins.docs.length}');

      for (var admin in allAdmins.docs) {
        final adminData = admin.data() as Map<String, dynamic>;
        print(
          '✉️ Sending notification to admin: ${admin.id} (${adminData['email']})',
        );
        await createNotification(
          recipientId: admin.id,
          recipientType: 'admin',
          type: NotificationModel.typeRestaurantNew,
          title: 'Restoran Baru Telah Terdaftar!',
          message:
              'Restoran "$restaurantName" telah mendaftar dan menunggu verifikasi. Harap segera diproses.',
          data: {'restaurantId': restaurantId},
        );
        print('✅ Notification sent to admin: ${admin.id}');
      }

      print('🎉 All admin notifications sent successfully!');
    } catch (e) {
      print('❌ Error sending admin notifications: $e');
    }
  }

  Future<void> notifyRestaurantSuspended(
    String ownerId,
    String restaurantName,
    String reason,
  ) async {
    await createNotification(
      recipientId: ownerId,
      recipientType: 'owner',
      type: NotificationModel.typeRestaurantSuspended,
      title: 'Akun Restoran Ditangguhkan!',
      message:
          'Akun restoran "$restaurantName" telah ditangguhkan. Alasan: $reason. Mohon tingkatkan kualitas pelayanan Anda agar rating meningkat!',
      data: {'reason': reason},
    );
  }

  Future<void> notifyAdminsAccountReported(
    String reportId,
    String accountId,
    String accountType,
  ) async {
    final admins = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Admin')
        .get();
    for (var admin in admins.docs) {
      await createNotification(
        recipientId: admin.id,
        recipientType: 'admin',
        type: NotificationModel.typeAccountReported,
        title: 'Laporan Akun',
        message: 'Akun $accountType bermasalah perlu ditinjau.',
        data: {'reportId': reportId, 'accountId': accountId},
      );
    }
  }

  Future<void> notifyAccountSuspended(
    String accountId,
    String reason,
    int duration,
  ) async {
    await createNotification(
      recipientId: accountId,
      recipientType: 'user',
      type: NotificationModel.typeAccountSuspended,
      title: 'Akun Ditangguhkan',
      message:
          'Akun Anda ditangguhkan selama $duration hari. Alasan: $reason. Mohon patuhi ketentuan yang berlaku. Anda dapat mengajukan banding dalam 7 hari ke depan.',
      data: {'reason': reason, 'duration': duration},
    );
  }

  Future<void> notifyAppealSubmitted(
    String accountId,
    String accountType,
    String appealMessage,
  ) async {
    // Notify all admins
    final admins = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Admin')
        .get();
    for (var admin in admins.docs) {
      await createNotification(
        recipientId: admin.id,
        recipientType: 'admin',
        type: NotificationModel.typeAppealSubmitted,
        title: 'Banding Diajukan',
        message: 'Akun $accountType mengajukan banding penangguhan.',
        data: {'accountId': accountId, 'appealMessage': appealMessage},
      );
    }
  }
}
