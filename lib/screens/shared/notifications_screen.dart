// screens/shared/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../services/fcm_service.dart';
import '../../utils/theme.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              await FCMService.markAllAsRead(userId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi ditandai telah dibaca'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Tandai Semua Dibaca'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FCMService.getNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final data = notif.data() as Map<String, dynamic>;

              return _buildNotificationCard(
                context,
                notificationId: notif.id,
                title: data['title'] ?? '',
                body: data['body'] ?? '',
                type: data['type'] ?? '',
                isRead: data['isRead'] ?? false,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String notificationId,
    required String title,
    required String body,
    required String type,
    required bool isRead,
    DateTime? createdAt,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppColors.lightOrange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (!isRead) {
              await FCMService.markAsRead(notificationId);
            }
            // Handle navigation based on type
            _handleNotificationTap(context, type);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        body,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          timeago.format(createdAt, locale: 'id'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'reservation_approved':
        return Icons.check_circle;
      case 'reservation_rejected':
        return Icons.cancel;
      case 'reservation_confirmed':
        return Icons.event_available;
      case 'account_suspended':
        return Icons.block;
      case 'restaurant_suspended':
        return Icons.store_mall_directory_outlined;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'reservation_approved':
      case 'reservation_confirmed':
        return Colors.green;
      case 'reservation_rejected':
      case 'account_suspended':
      case 'restaurant_suspended':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _handleNotificationTap(BuildContext context, String type) {
    // Handle navigation based on notification type
    switch (type) {
      case 'reservation_approved':
      case 'reservation_rejected':
      case 'reservation_confirmed':
        // Navigate to reservations list
        // Navigator.pushNamed(context, '/reservations');
        break;
      case 'account_suspended':
        // Show suspension details
        break;
      case 'restaurant_suspended':
        // Navigate to restaurant management
        break;
      default:
        break;
    }
  }
}
