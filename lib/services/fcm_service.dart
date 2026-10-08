// services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize FCM
  static Future<void> initialize() async {
    // Request permission untuk iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted FCM permission');
    }

    // Initialize local notifications untuk Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  // Get FCM token
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Save FCM token to Firestore
  static Future<void> saveTokenToFirestore(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'fcmToken': token, 'updatedAt': Timestamp.now()},
        );
        print('✅ FCM token saved to Firestore');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // Handle foreground message (app terbuka)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'Notifikasi',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Handle background message (app di background, user tap notif)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📩 Background message opened: ${message.notification?.title}');
    // Handle navigation berdasarkan message.data
  }

  // Show local notification (untuk foreground)
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'nyam_makanan_channel',
          'Nyam Makanan Notifications',
          channelDescription: 'Notifikasi dari aplikasi Nyam Makanan',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // ========== SEND NOTIFICATION FUNCTIONS ==========

  // 1. Reservasi Disetujui (Awaiting Payment)
  static Future<void> sendReservationApprovedNotification({
    required String userId,
    required String restaurantName,
    required String reservationDate,
    required String reservationTime,
    required String dpAmount,
  }) async {
    await _sendNotificationToUser(
      userId: userId,
      title: '✅ Reservasi Disetujui!',
      body:
          'Reservasi Anda di $restaurantName pada $reservationDate $reservationTime telah disetujui. Silakan bayar DP $dpAmount.',
      type: 'reservation_approved',
    );
  }

  // 2. Reservasi Ditolak
  static Future<void> sendReservationRejectedNotification({
    required String userId,
    required String restaurantName,
    required String rejectionReason,
  }) async {
    await _sendNotificationToUser(
      userId: userId,
      title: '❌ Reservasi Ditolak',
      body:
          'Mohon maaf, reservasi Anda di $restaurantName ditolak. Alasan: $rejectionReason',
      type: 'reservation_rejected',
    );
  }

  // 3. Reservasi Dikonfirmasi (Setelah Bayar DP)
  static Future<void> sendReservationConfirmedNotification({
    required String userId,
    required String restaurantName,
    required String reservationDate,
    required String reservationTime,
    required String tableNumber,
    required String area,
  }) async {
    await _sendNotificationToUser(
      userId: userId,
      title: '🎉 Reservasi Terkonfirmasi!',
      body:
          'Reservasi Anda di $restaurantName pada $reservationDate $reservationTime telah dikonfirmasi. Nomor Meja: $tableNumber ($area)',
      type: 'reservation_confirmed',
    );
  }

  // 4. Akun Ditangguhkan
  static Future<void> sendAccountSuspendedNotification({
    required String userId,
    required String suspensionReason,
    required String deletionDate,
  }) async {
    await _sendNotificationToUser(
      userId: userId,
      title: '⚠️ Akun Ditangguhkan',
      body:
          'Akun Anda telah ditangguhkan. Alasan: $suspensionReason. Akun akan dihapus pada $deletionDate jika tidak ada tindakan.',
      type: 'account_suspended',
    );
  }

  // 5. Restoran Ditangguhkan
  static Future<void> sendRestaurantSuspendedNotification({
    required String ownerId,
    required String restaurantName,
    required String suspensionReason,
    required String deletionDate,
    required String adminEmail,
  }) async {
    await _sendNotificationToUser(
      userId: ownerId,
      title: '⚠️ Restoran Ditangguhkan',
      body:
          'Restoran $restaurantName telah ditangguhkan. Alasan: $suspensionReason. Hubungi admin ($adminEmail) sebelum $deletionDate.',
      type: 'restaurant_suspended',
    );
  }

  // Helper: Send notification to specific user
  static Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('⚠️ User $userId does not have FCM token');
        return;
      }

      // Save notification to Firestore untuk history
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      print('✅ Notification saved to Firestore for user $userId');

      // NOTE: Untuk send notification ke FCM token tertentu,
      // perlu Cloud Functions atau external API karena Flutter tidak bisa
      // send FCM directly. Alternatif: pakai local notification saja
      // atau setup backend/Cloud Functions untuk send FCM.

      // Untuk sekarang, kita simpan di Firestore saja
      // dan user akan dapat notifikasi saat buka app (in-app notification)
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // Get unread notifications count (support both userId and recipientId)
  static Stream<int> getUnreadNotificationsCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get all notifications for user (support both userId and recipientId)
  static Stream<QuerySnapshot> getNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': Timestamp.now()});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }
}
