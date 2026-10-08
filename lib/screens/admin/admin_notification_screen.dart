// screens/admin/admin_notification_screen.dart
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'restaurant',
      'title': 'Restoran Baru Mendaftar!',
      'message': 'Ayam Gepuk Pak Gembus mendaftar sebagai merchant baru',
      'time': '5 menit yang lalu',
      'isRead': false,
      'restaurantId': 'RES001',
      'priority': 'high',
    },
    {
      'id': '2',
      'type': 'user_report',
      'title': 'Laporan Pengguna',
      'message':
          'User BingBung dilaporkan oleh Setya Ramen karena rating buruk berulang',
      'time': '1 jam yang lalu',
      'isRead': false,
      'userId': 'USER002',
      'priority': 'medium',
    },
    {
      'id': '3',
      'type': 'restaurant_warning',
      'title': 'Peringatan Rating Resto',
      'message': 'Setya Ramen memiliki rating dibawah 2. Perlu peninjauan',
      'time': '2 jam yang lalu',
      'isRead': true,
      'restaurantId': 'RES002',
      'priority': 'high',
    },
    {
      'id': '4',
      'type': 'system',
      'title': 'Update Sistem',
      'message': 'Backup database berhasil dilakukan',
      'time': '1 hari yang lalu',
      'isRead': true,
      'priority': 'low',
    },
    {
      'id': '5',
      'type': 'user_suspension',
      'title': 'User Ditangguhkan',
      'message': 'User DePani berhasil ditangguhkan karena pelanggaran',
      'time': '2 hari yang lalu',
      'isRead': true,
      'userId': 'USER003',
      'priority': 'medium',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Notifikasi Admin'),
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            Badge(
              label: Text(unreadCount.toString()),
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterOptions,
              ),
            ),
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
                // Quick Actions
                _buildQuickActions(),

                // Notifications List
                Expanded(child: _buildNotificationsList()),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 80, color: Colors.grey[300]),
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
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final pendingRestaurants = _notifications
        .where((n) => n['type'] == 'restaurant' && !n['isRead'])
        .length;
    final userReports = _notifications
        .where((n) => n['type'] == 'user_report' && !n['isRead'])
        .length;
    final warnings = _notifications
        .where((n) => n['type'] == 'restaurant_warning' && !n['isRead'])
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tindakan Cepat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (pendingRestaurants > 0)
                Expanded(
                  child: _buildQuickActionItem(
                    '$pendingRestaurants Resto Baru',
                    Icons.restaurant,
                    Colors.blue,
                    () {
                      _navigateToPendingRestaurants();
                    },
                  ),
                ),
              if (userReports > 0)
                Expanded(
                  child: _buildQuickActionItem(
                    '$userReports Laporan',
                    Icons.flag,
                    AppColors.primaryOrange,
                    () {
                      _navigateToUserReports();
                    },
                  ),
                ),
              if (warnings > 0)
                Expanded(
                  child: _buildQuickActionItem(
                    '$warnings Peringatan',
                    Icons.warning,
                    Colors.red,
                    () {
                      _navigateToWarnings();
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: _buildNotificationIcon(notification),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['isRead']
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14,
                        color: _getPriorityColor(notification['priority']),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    notification['time'],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Spacer(),
                  _buildPriorityBadge(notification['priority']),
                ],
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
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
          onTap: () {
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(Map<String, dynamic> notification) {
    IconData icon;
    Color color;

    switch (notification['type']) {
      case 'restaurant':
        icon = Icons.restaurant;
        color = Colors.blue;
        break;
      case 'user_report':
        icon = Icons.flag;
        color = AppColors.primaryOrange;
        break;
      case 'restaurant_warning':
        icon = Icons.warning;
        color = Colors.red;
        break;
      case 'user_suspension':
        icon = Icons.person_off;
        color = Colors.purple;
        break;
      case 'system':
        icon = Icons.settings;
        color = Colors.green;
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

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String text;

    switch (priority) {
      case 'high':
        color = Colors.red;
        text = 'Tinggi';
        break;
      case 'medium':
        color = AppColors.primaryOrange;
        text = 'Sedang';
        break;
      case 'low':
        color = Colors.green;
        text = 'Rendah';
        break;
      default:
        color = Colors.grey;
        text = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read when tapped
    if (!notification['isRead']) {
      _markAsRead(notification);
    }

    // Navigate based on notification type
    switch (notification['type']) {
      case 'restaurant':
        _showRestaurantVerification(notification);
        break;
      case 'user_report':
        _showUserReport(notification);
        break;
      case 'restaurant_warning':
        _showRestaurantWarning(notification);
        break;
      case 'user_suspension':
        _showUserSuspension(notification);
        break;
      case 'system':
        _showSystemNotification(notification);
        break;
    }
  }

  void _showRestaurantVerification(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Restoran Baru'),
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
                      // Navigate to restaurant verification
                    },
                    child: const Text('Lihat Detail Resto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Quick verify
                    },
                    child: const Text('Verifikasi Cepat'),
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

  void _showUserReport(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporan Pengguna'),
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
                      // Navigate to user management
                    },
                    child: const Text('Lihat User'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _suspendUserFromNotification(notification);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                    ),
                    child: const Text('Tangguhkan'),
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

  void _showRestaurantWarning(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Peringatan Rating Restoran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message']),
            const SizedBox(height: 16),
            const Text(
              'Rating dibawah 2 dapat menyebabkan penangguhan.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
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
                      // Navigate to restaurant management
                    },
                    child: const Text('Lihat Resto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _contactRestaurantOwner(notification);
                    },
                    child: const Text('Hubungi Owner'),
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

  void _showUserSuspension(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Ditangguhkan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message']),
            const SizedBox(height: 16),
            const Text(
              'User telah berhasil ditangguhkan karena pelanggaran.',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to user management
            },
            child: const Text('Lihat User'),
          ),
        ],
      ),
    );
  }

  void _showSystemNotification(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifikasi Sistem'),
        content: Text(notification['message']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _suspendUserFromNotification(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tangguhkan User'),
        content: const Text('Apakah Anda yakin ingin menangguhkan user ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Suspend user logic
              Navigator.pop(context);
              Navigator.pop(context); // Close notification dialog too

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User berhasil ditangguhkan'),
                  backgroundColor: AppColors.primaryOrange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Tangguhkan'),
          ),
        ],
      ),
    );
  }

  void _contactRestaurantOwner(Map<String, dynamic> notification) {
    // Implement contact logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka kontak owner restoran...'),
        backgroundColor: Colors.blue,
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
      const SnackBar(
        content: Text('Notifikasi dihapus'),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua notifikasi?',
        ),
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

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Semua Notifikasi', Icons.all_inclusive),
            _buildFilterOption('Belum Dibaca', Icons.mark_email_unread),
            _buildFilterOption('Restoran', Icons.restaurant),
            _buildFilterOption('Laporan User', Icons.flag),
            _buildFilterOption('Peringatan', Icons.warning),
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

  Widget _buildFilterOption(String text, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        // Implement filter logic
      },
    );
  }

  void _navigateToPendingRestaurants() {
    // Navigate to pending restaurants
  }

  void _navigateToUserReports() {
    // Navigate to user reports
  }

  void _navigateToWarnings() {
    // Navigate to warnings
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return AppColors.primaryOrange;
      case 'low':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
