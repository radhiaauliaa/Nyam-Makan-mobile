// screens/common/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final userId = authProvider.user?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return provider.unreadCount > 0
                  ? TextButton.icon(
                      onPressed: () => provider.markAllAsRead(userId),
                      icon: const Icon(
                        Icons.done_all,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Tandai Semua',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  : const SizedBox();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationProvider.getNotificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi akan muncul di sini',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          // Group notifications by date
          final groupedNotifications = _groupNotificationsByDate(notifications);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groupedNotifications.length,
            itemBuilder: (context, index) {
              final group = groupedNotifications[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      group['date'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // Notifications
                  ...group['notifications'].map<Widget>((notif) {
                    return _buildNotificationItem(notif, notificationProvider);
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(
    List<NotificationModel> notifications,
  ) {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();

    for (var notif in notifications) {
      String dateKey;
      if (_isSameDay(notif.createdAt, now)) {
        dateKey = 'Hari Ini';
      } else if (_isSameDay(
        notif.createdAt,
        now.subtract(const Duration(days: 1)),
      )) {
        dateKey = 'Kemarin';
      } else if (now.difference(notif.createdAt).inDays < 7) {
        dateKey = _getDayName(notif.createdAt);
      } else {
        dateKey = _formatDate(notif.createdAt);
      }

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(notif);
    }

    return grouped.entries
        .map((e) => {'date': e.key, 'notifications': e.value})
        .toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getDayName(DateTime date) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return days[date.weekday % 7];
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Optional: implement delete notification
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : AppColors.primaryOrange,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    notification.iconData,
                    style: const TextStyle(fontSize: 24),
                  ),
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
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
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
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.createdAt, locale: 'id'),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case NotificationModel.typeReservationApproved:
      case NotificationModel.typePaymentVerified:
        return Colors.green;
      case NotificationModel.typeReservationRejected:
      case NotificationModel.typePaymentRejected:
        return Colors.red;
      case NotificationModel.typeReservationNew:
        return Colors.blue;
      case NotificationModel.typeReviewNew:
        return Colors.amber;
      case NotificationModel.typeAccountSuspended:
        return Colors.red;
      case NotificationModel.typeAccountReported:
        return AppColors.primaryOrange;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Navigate based on notification type
    // TODO: Implement navigation to relevant screens
    switch (notification.type) {
      case NotificationModel.typeReservationNew:
      case NotificationModel.typeReservationApproved:
      case NotificationModel.typePaymentVerified:
        // Navigate to reservation detail
        final reservationId = notification.data['reservationId'];
        print('Navigate to reservation: $reservationId');
        break;
      case NotificationModel.typeReviewNew:
        // Navigate to reviews
        final restaurantId = notification.data['restaurantId'];
        print('Navigate to restaurant reviews: $restaurantId');
        break;
      case NotificationModel.typeAccountSuspended:
        // Navigate to appeal screen
        final suspensionId = notification.data['suspensionId'];
        print('Navigate to appeal: $suspensionId');
        break;
      case NotificationModel.typeAccountReported:
        // Navigate to reports (admin only)
        final reportId = notification.data['reportId'];
        print('Navigate to report: $reportId');
        break;
    }
  }
}
