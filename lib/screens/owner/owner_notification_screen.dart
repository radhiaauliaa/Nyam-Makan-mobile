// screens/owner/owner_notification_screen.dart
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class OwnerNotificationScreen extends StatefulWidget {
  const OwnerNotificationScreen({super.key});

  @override
  State<OwnerNotificationScreen> createState() => _OwnerNotificationScreenState();
}

class _OwnerNotificationScreenState extends State<OwnerNotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'reservation',
      'title': 'Reservasi Baru Masuk!',
      'message': 'De Pani melakukan reservasi untuk 2 orang pada 29 September 2025 20.15',
      'time': '5 menit yang lalu',
      'isRead': false,
      'reservationId': 'STY001',
    },
    {
      'id': '2',
      'type': 'review',
      'title': 'Ulasan Baru!',
      'message': 'BingBung memberikan rating 3 bintang untuk Kari Ramen',
      'time': '1 jam yang lalu',
      'isRead': false,
      'reviewId': 'REV001',
    },
    {
      'id': '3',
      'type': 'system',
      'title': 'Rating Resto Turun',
      'message': 'Rating restoran Anda turun menjadi 4.8. Periksa ulasan terbaru untuk meningkatkan kualitas',
      'time': '2 hari yang lalu',
      'isRead': true,
    },
    {
      'id': '4',
      'type': 'reservation',
      'title': 'Reservasi Dibatalkan',
      'message': 'Sari Wijaya membatalkan reservasi untuk 4 orang',
      'time': '3 hari yang lalu',
      'isRead': true,
      'reservationId': 'STY003',
    },
    {
      'id': '5',
      'type': 'system',
      'title': 'Peringatan Admin',
      'message': 'Restoran Anda memiliki rating buruk. Admin akan menghubungi dalam 1 minggu',
      'time': '1 minggu yang lalu',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              } else if (value == 'clear_all') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Tandai Semua Dibaca'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Hapus Semua'),
              ),
            ],
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Stats
                _buildNotificationStats(),
                
                // Notifications List
                Expanded(
                  child: _buildNotificationsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Notifikasi baru akan muncul di sini',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStats() {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Notifikasi ($unreadCount belum dibaca)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tandai Semua Dibaca',
                style: TextStyle(color: AppColors.primaryOrange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(_notifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification['isRead'] ? Colors.white : Colors.blue[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildNotificationIcon(notification['type']),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (!notification['isRead'])
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
                notification['message'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification['time'],
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_read') {
                _markAsRead(notification);
              } else if (value == 'delete') {
                _deleteNotification(notification);
              }
            },
            itemBuilder: (context) => [
              if (!notification['isRead'])
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Text('Tandai Dibaca'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus'),
              ),
            ],
          ),
          onTap: () {
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'reservation':
        icon = Icons.event_available;
        color = Colors.blue;
        break;
      case 'review':
        icon = Icons.reviews;
        color = AppColors.primaryOrange;
        break;
      case 'system':
        icon = Icons.info;
        color = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read when tapped
    if (!notification['isRead']) {
      _markAsRead(notification);
    }

    // Navigate based on notification type
    switch (notification['type']) {
      case 'reservation':
        // Navigate to reservation details
        _showReservationDetails(notification);
        break;
      case 'review':
        // Navigate to review details
        _showReviewDetails(notification);
        break;
      case 'system':
        // Show system notification details
        _showSystemNotification(notification);
        break;
    }
  }

  void _showReservationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message']),
            const SizedBox(height: 16),
            const Text(
              'Tindakan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to manage reservation screen
                    },
                    child: const Text('Lihat Reservasi'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showReviewDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message']),
            const SizedBox(height: 16),
            const Text(
              'Tindakan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to view reviews screen
                    },
                    child: const Text('Lihat Ulasan'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSystemNotification(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: Text(notification['message']),
        actions: [
          if (notification['title'].contains('Peringatan'))
            TextButton(
              onPressed: () {
                // Contact admin or take action
                Navigator.pop(context);
              },
              child: const Text('Hubungi Admin'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _markAsRead(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai sebagai dibaca'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    setState(() {
      _notifications.remove(notification);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifikasi dihapus'),
        backgroundColor: AppColors.primaryOrange,
        action: SnackBarAction(
          label: 'Batal',
          onPressed: () {
            setState(() {
              _notifications.add(notification);
            });
          },
        ),
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text('Apakah Anda yakin ingin menghapus semua notifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi telah dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}