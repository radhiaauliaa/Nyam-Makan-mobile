// screens/admin/problematic_accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/fcm_service.dart';
import '../../utils/theme.dart';

class ProblematicAccountsScreen extends StatefulWidget {
  const ProblematicAccountsScreen({super.key});

  @override
  State<ProblematicAccountsScreen> createState() =>
      _ProblematicAccountsScreenState();
}

class _ProblematicAccountsScreenState extends State<ProblematicAccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Akun Bermasalah'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFFFE4D6),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Direport Pemilik'),
            Tab(text: 'Review Buruk Berulang'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReportedUsersTab(), _buildBadReviewersTab()],
      ),
    );
  }

  // Tab 1: User yang direport oleh pemilik resto
  Widget _buildReportedUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('reportedEntityType', isEqualTo: 'user')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reports = snapshot.data?.docs ?? [];

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada user yang direport',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Group reports by user
        Map<String, List<QueryDocumentSnapshot>> reportsByUser = {};
        for (var report in reports) {
          final userId = report['reportedEntityId'] as String;
          reportsByUser.putIfAbsent(userId, () => []).add(report);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportsByUser.length,
          itemBuilder: (context, index) {
            final userId = reportsByUser.keys.elementAt(index);
            final userReports = reportsByUser[userId]!;
            return _buildReportedUserCard(userId, userReports);
          },
        );
      },
    );
  }

  Widget _buildReportedUserCard(
    String userId,
    List<QueryDocumentSnapshot> reports,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        final username = userData['username'] ?? 'Unknown User';
        final email = userData['email'] ?? '';
        final status = userData['status'] ?? 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'suspended'
                            ? Colors.red.withOpacity(0.1)
                            : AppColors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status == 'suspended' ? 'Ditangguhkan' : 'Aktif',
                        style: TextStyle(
                          color: status == 'suspended'
                              ? Colors.red
                              : AppColors.primaryOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Report Count
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Dilaporkan ${reports.length}x oleh pemilik resto',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Recent Reports
                const Text(
                  'Laporan Terbaru:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...reports.take(3).map((report) {
                  final data = report.data() as Map<String, dynamic>;
                  final reason = data['reason'] ?? 'Tidak ada alasan';
                  final reporterName = data['reporterName'] ?? 'Unknown';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            '$reason (oleh: $reporterName)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewReportDetails(userId, reports),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Lihat Detail'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (status != 'suspended')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _suspendUser(userId, username),
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text('Tangguhkan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _activateUser(userId, username),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Aktifkan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tab 2: User yang ngasih 10x review buruk berturut-turut di resto yang sama
  Widget _buildBadReviewersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reviews = snapshot.data?.docs ?? [];

        // Analisis review: cari user yang ngasih ≥10 review buruk (rating ≤2) berturut-turut di resto yang sama
        Map<String, Map<String, List<QueryDocumentSnapshot>>>
        userRestaurantReviews = {};

        for (var review in reviews) {
          final data = review.data() as Map<String, dynamic>;
          final userId = data['userId'] as String?;
          final restaurantId = data['restaurantId'] as String?;
          final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;

          if (userId != null && restaurantId != null && rating <= 2.0) {
            userRestaurantReviews
                .putIfAbsent(userId, () => {})
                .putIfAbsent(restaurantId, () => [])
                .add(review);
          }
        }

        // Filter: hanya user yang punya ≥10 review buruk di satu resto
        List<MapEntry<String, MapEntry<String, List<QueryDocumentSnapshot>>>>
        problematicUsers = [];

        userRestaurantReviews.forEach((userId, restaurants) {
          restaurants.forEach((restaurantId, reviewList) {
            if (reviewList.length >= 10) {
              problematicUsers.add(
                MapEntry(userId, MapEntry(restaurantId, reviewList)),
              );
            }
          });
        });

        if (problematicUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sentiment_satisfied,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada user dengan review buruk berulang',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: problematicUsers.length,
          itemBuilder: (context, index) {
            final entry = problematicUsers[index];
            final userId = entry.key;
            final restaurantId = entry.value.key;
            final badReviews = entry.value.value;
            return _buildBadReviewerCard(userId, restaurantId, badReviews);
          },
        );
      },
    );
  }

  Widget _buildBadReviewerCard(
    String userId,
    String restaurantId,
    List<QueryDocumentSnapshot> badReviews,
  ) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('users').doc(userId).get(),
        FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final userData = snapshot.data![0].data() as Map<String, dynamic>?;
        final restaurantData =
            snapshot.data![1].data() as Map<String, dynamic>?;

        if (userData == null || restaurantData == null) return const SizedBox();

        final username = userData['username'] ?? 'Unknown User';
        final email = userData['email'] ?? '';
        final status = userData['status'] ?? 'active';
        final restaurantName = restaurantData['name'] ?? 'Unknown Restaurant';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'suspended'
                            ? Colors.red.withOpacity(0.1)
                            : AppColors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status == 'suspended' ? 'Ditangguhkan' : 'Aktif',
                        style: TextStyle(
                          color: status == 'suspended'
                              ? Colors.red
                              : AppColors.primaryOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Warning Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${badReviews.length} review buruk berturut-turut',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'di resto: $restaurantName',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Recent Bad Reviews
                const Text(
                  'Review Buruk Terbaru:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...badReviews.take(3).map((review) {
                  final data = review.data() as Map<String, dynamic>;
                  final rating = (data['rating'] as num?)?.toDouble() ?? 0;
                  final comment = data['comment'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⭐ $rating - ',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Expanded(
                          child: Text(
                            comment.isNotEmpty ? comment : '(tanpa komentar)',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewUserReviews(userId, restaurantId),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Lihat Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (status != 'suspended')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _suspendUser(userId, username),
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text('Tangguhkan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _activateUser(userId, username),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Aktifkan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Actions
  void _viewReportDetails(String userId, List<QueryDocumentSnapshot> reports) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Laporan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: reports.map((report) {
              final data = report.data() as Map<String, dynamic>;
              final reason = data['reason'] ?? 'Tidak ada alasan';
              final reporterName = data['reporterName'] ?? 'Unknown';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dilaporkan oleh: $reporterName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alasan: $reason',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (createdAt != null)
                        Text(
                          'Tanggal: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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

  void _viewUserReviews(String userId, String restaurantId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserReviewsDetailScreen(userId: userId, restaurantId: restaurantId),
      ),
    );
  }

  void _suspendUser(String userId, String username) {
    showDialog(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();

        return AlertDialog(
          title: const Text('Tangguhkan Akun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Anda yakin ingin menangguhkan akun "$username"?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Alasan Penangguhan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap isi alasan penangguhan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final suspendedAt = DateTime.now();
                  final deletionDate = suspendedAt.add(const Duration(days: 7));

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                        'status': 'suspended',
                        'suspensionReason': reason,
                        'suspendedAt': Timestamp.now(),
                        'deletionDate': Timestamp.fromDate(deletionDate),
                        'updatedAt': Timestamp.now(),
                      });

                  // Send push notification
                  await FCMService.sendAccountSuspendedNotification(
                    userId: userId,
                    suspensionReason: reason,
                    deletionDate: DateFormat('dd/MM/yyyy').format(deletionDate),
                  );

                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Akun ditangguhkan dan notifikasi dikirim',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menangguhkan akun: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tangguhkan'),
            ),
          ],
        );
      },
    );
  }

  void _activateUser(String userId, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Akun'),
        content: Text(
          'Anda yakin ingin mengaktifkan kembali akun "$username"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                      'status': 'active',
                      'suspensionReason': FieldValue.delete(),
                      'suspendedAt': FieldValue.delete(),
                      'updatedAt': Timestamp.now(),
                    });

                Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Akun berhasil diaktifkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengaktifkan akun: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }
}

// Detail screen untuk melihat semua review user di resto tertentu
class UserReviewsDetailScreen extends StatelessWidget {
  final String userId;
  final String restaurantId;

  const UserReviewsDetailScreen({
    super.key,
    required this.userId,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Review User'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: userId)
            .where('restaurantId', isEqualTo: restaurantId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reviews = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              final rating = (data['rating'] as num?)?.toDouble() ?? 0;
              final comment = data['comment'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '⭐ $rating',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          const Spacer(),
                          if (createdAt != null)
                            Text(
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(comment),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
