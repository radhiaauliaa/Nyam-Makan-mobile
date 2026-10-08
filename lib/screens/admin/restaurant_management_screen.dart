// screens/admin/restaurant_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/restaurant_model.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'verification_screen.dart';
import 'user_management_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class RestaurantManagementScreen extends StatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  State<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState extends State<RestaurantManagementScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Pindahkan pemanggilan _loadRestaurants ke didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    // Jalankan secara berurutan agar status loading provider tetap konsisten
    await provider.loadPendingRestaurants();
    await provider.loadVerifiedRestaurants();
    await provider.loadRejectedRestaurants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Manajemen Restoran'),
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFFFE4D6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Belum Diproses'),
            Tab(text: 'Diterima'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 2),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Stats Overview
              Container(
                padding: const EdgeInsets.all(16),
                child: _buildStatsOverview(provider),
              ),

              // Tab Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRestaurantList(
                        provider.pendingRestaurants,
                        'pending',
                        provider,
                      ),
                      _buildRestaurantList(
                        provider.verifiedRestaurants,
                        'verified',
                        provider,
                      ),
                      _buildRestaurantList(
                        provider.rejectedRestaurants,
                        'rejected',
                        provider,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(RestaurantProvider provider) {
    final totalRestaurants =
        provider.pendingRestaurants.length +
        provider.verifiedRestaurants.length +
        provider.rejectedRestaurants.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verifikasi Resto Baru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatItem(
                  'Jumlah\nResto',
                  '$totalRestaurants',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Data\nMasuk',
                  '${provider.pendingRestaurants.length}',
                  AppColors.primaryOrange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Terverifikasi',
                  '${provider.verifiedRestaurants.length}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Ditolak',
                  '${provider.rejectedRestaurants.length}',
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantList(
    List<Restaurant> restaurants,
    String status,
    RestaurantProvider provider,
  ) {
    if (provider.isLoading && restaurants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getStatusIcon(status), size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(status),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRestaurants,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRestaurants,
      child: ListView.builder(
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          return _buildRestaurantCard(restaurants[index], status, provider);
        },
      ),
    );
  }

  Widget _buildRestaurantCard(
    Restaurant restaurant,
    String status,
    RestaurantProvider provider,
  ) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Restaurant Info
            Text(
              restaurant.categories.isNotEmpty
                  ? restaurant.categories.first
                  : 'Tidak ada kategori',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Details
            _buildOwnerRow(restaurant.ownerId),
            _buildDetailRow(
              'Telepon',
              restaurant.phone.isNotEmpty
                  ? restaurant.phone
                  : 'Tidak ada telepon',
            ),
            _buildDetailRow(
              'Alamat',
              restaurant.address.isNotEmpty
                  ? restaurant.address
                  : 'Tidak ada alamat',
            ),

            if (restaurant.rating > 0)
              _buildDetailRow(
                'Rating',
                '${restaurant.rating} (${restaurant.totalReviews} reviews)',
              ),

            if (restaurant.createdAt != null)
              _buildDetailRow('Diajukan', _formatDate(restaurant.createdAt!)),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(restaurant, status, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Tampilkan nama/username/email pemilik berdasarkan ownerId (bukan kode id)
  Widget _buildOwnerRow(String? ownerId) {
    if (ownerId == null || ownerId.isEmpty) {
      return _buildDetailRow('Pemilik', 'Tidak diketahui');
    }

    return FutureBuilder<UserModel?>(
      future: UserService().getUserById(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailRow('Pemilik', 'Memuat...');
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildDetailRow('Pemilik', 'Tidak diketahui');
        }
        final user = snapshot.data!;
        final display = user.username.isNotEmpty ? user.username : user.email;
        return _buildDetailRow('Pemilik', display);
      },
    );
  }

  Widget _buildActionButtons(
    Restaurant restaurant,
    String status,
    RestaurantProvider provider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;

        if (status == 'pending') {
          return isSmallScreen
              ? _buildPendingActionsVertical(restaurant, provider)
              : _buildPendingActionsHorizontal(restaurant, provider);
        } else if (status == 'verified') {
          return isSmallScreen
              ? _buildVerifiedActionsVertical(restaurant, provider)
              : _buildVerifiedActionsHorizontal(restaurant, provider);
        } else {
          return isSmallScreen
              ? _buildRejectedActionsVertical(restaurant, provider)
              : _buildRejectedActionsHorizontal(restaurant, provider);
        }
      },
    );
  }

  // Horizontal Layouts
  Widget _buildPendingActionsHorizontal(
    Restaurant restaurant,
    RestaurantProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _contactOwner(restaurant),
            child: const Text('Hubungi', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _viewRestaurantData(restaurant),
            child: const Text('Lihat Data', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _verifyRestaurant(restaurant, provider),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verifikasi', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _rejectRestaurant(restaurant, provider),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedActionsHorizontal(
    Restaurant restaurant,
    RestaurantProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _viewRestaurantData(restaurant),
            child: const Text('Lihat Data', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _contactOwner(restaurant),
            child: const Text('Hubungi', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _suspendRestaurant(restaurant, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tangguhkan', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedActionsHorizontal(
    Restaurant restaurant,
    RestaurantProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _viewRestaurantData(restaurant),
            child: const Text('Lihat Data', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _contactOwner(restaurant),
            child: const Text('Hubungi', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _reconsiderRestaurant(restaurant, provider),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Tinjau Ulang', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // Vertical Layouts
  Widget _buildPendingActionsVertical(
    Restaurant restaurant,
    RestaurantProvider provider,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _contactOwner(restaurant),
                child: const Text('Hubungi', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _viewRestaurantData(restaurant),
                child: const Text('Lihat Data', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _verifyRestaurant(restaurant, provider),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Verifikasi', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _rejectRestaurant(restaurant, provider),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Tolak', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifiedActionsVertical(
    Restaurant restaurant,
    RestaurantProvider provider,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _viewRestaurantData(restaurant),
                child: const Text('Lihat Data', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _contactOwner(restaurant),
                child: const Text('Hubungi', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _suspendRestaurant(restaurant, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tangguhkan', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedActionsVertical(
    Restaurant restaurant,
    RestaurantProvider provider,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _viewRestaurantData(restaurant),
                child: const Text('Lihat Data', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _contactOwner(restaurant),
                child: const Text('Hubungi', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _reconsiderRestaurant(restaurant, provider),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Tinjau Ulang', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  void _viewRestaurantData(Restaurant restaurant) async {
    // Ambil nama/username/email pemilik berdasarkan ownerId
    String ownerDisplay = 'Tidak diketahui';
    if (restaurant.ownerId != null && restaurant.ownerId!.isNotEmpty) {
      try {
        final user = await UserService().getUserById(restaurant.ownerId!);
        if (user != null) {
          ownerDisplay = user.username.isNotEmpty ? user.username : user.email;
        }
      } catch (_) {
        // Abaikan error, gunakan fallback default
      }
    }

    final data = _convertToMap(restaurant);
    data['owner'] = ownerDisplay; // ganti id dengan nama/email
    data['ownerId'] = restaurant.ownerId; // tetap kirim ownerId jika perlu

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationScreen(restaurant: data),
      ),
    );
  }

  Map<String, dynamic> _convertToMap(Restaurant restaurant) {
    return {
      'id': restaurant.id,
      'name': restaurant.name,
      'category': restaurant.categories.isNotEmpty
          ? restaurant.categories.first
          : '',
      'owner': restaurant.ownerId ?? 'Tidak diketahui',
      'phone': restaurant.phone,
      'address': restaurant.address,
      'openTime': restaurant.openTime,
      'closeTime': restaurant.closeTime,
      'description': restaurant.description,
      'images': restaurant.images,
      'licenseUrl': restaurant.license,
      'submissionDate': _formatDate(restaurant.createdAt ?? DateTime.now()),
      'status': restaurant.status,
    };
  }

  void _verifyRestaurant(Restaurant restaurant, RestaurantProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Restoran'),
        content: const Text(
          'Apakah Anda yakin ingin memverifikasi restoran ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await provider.updateRestaurantStatus(
                restaurant.id,
                'verified',
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restoran berhasil diverifikasi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal memverifikasi: ${provider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  void _rejectRestaurant(Restaurant restaurant, RestaurantProvider provider) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Restoran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alasan penolakan:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Data tidak valid, lokasi tidak sesuai',
                border: OutlineInputBorder(),
              ),
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
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                bool success = await provider.updateRestaurantStatus(
                  restaurant.id,
                  'rejected',
                  reason: reasonController.text,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restoran berhasil ditolak'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menolak: ${provider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _suspendRestaurant(Restaurant restaurant, RestaurantProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Tangguhkan Restoran'),
        content: const Text(
          'Apakah Anda yakin ingin menangguhkan restoran ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await provider.updateRestaurantStatus(
                restaurant.id,
                'suspended',
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restoran berhasil ditangguhkan'),
                    backgroundColor: AppColors.primaryOrange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tangguhkan'),
          ),
        ],
      ),
    );
  }

  void _reconsiderRestaurant(
    Restaurant restaurant,
    RestaurantProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tinjau Ulang Restoran'),
        content: const Text('Apakah Anda ingin meninjau ulang restoran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await provider.updateRestaurantStatus(
                restaurant.id,
                'pending',
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Restoran berhasil dikembalikan ke proses verifikasi',
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: const Text('Tinjau Ulang'),
          ),
        ],
      ),
    );
  }

  void _contactOwner(Restaurant restaurant) {
    if (restaurant.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon tidak tersedia'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hubungi Pemilik'),
        content: Text('Hubungi pemilik di ${restaurant.phone}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menghubungi ${restaurant.phone}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Hubungi'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Tidak ada restoran yang menunggu verifikasi';
      case 'verified':
        return 'Tidak ada restoran yang telah diverifikasi';
      case 'rejected':
        return 'Tidak ada restoran yang ditolak';
      default:
        return 'Tidak ada data';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.primaryOrange;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Belum Diproses';
      case 'verified':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; // Sudah di screen ini

        switch (index) {
          case 0: // Home
            Navigator.pop(context); // Kembali ke home
            break;
          case 1: // Users
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const UserManagementScreen(),
              ),
            );
            break;
          case 2: // Resto - tetap di screen ini
            break;
        }
      },
      items: [
        BottomNavItem(icon: Icons.home, label: 'Home'),
        BottomNavItem(icon: Icons.people, label: 'Users'),
        BottomNavItem(icon: Icons.restaurant, label: 'Resto'),
      ],
    );
  }
}
