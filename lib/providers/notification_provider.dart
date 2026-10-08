// providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Get notifications stream (use in StreamBuilder)
  Stream<List<NotificationModel>> getNotificationsStream(String recipientId) {
    return _notificationService.getNotificationsStream(recipientId);
  }

  // Listen to unread count
  void listenToUnreadCount(String recipientId) {
    _notificationService.getUnreadCountStream(recipientId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String recipientId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _notificationService.markAllAsRead(recipientId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error marking all as read: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _unreadCount = 0;
    notifyListeners();
  }
}
