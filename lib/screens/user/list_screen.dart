// screens/user/list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reservation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import 'reservation_detail_screen.dart';
import 'favorite_screen.dart';
import 'home_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final currentUser = authProvider.user;
    final currentUserId = currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, currentUser?.username ?? 'Guest'),

            // Tab Bar
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: currentUserId == null
                  ? _buildNotLoggedInState()
                  : _buildReservationContent(
                      currentUserId,
                      reservationProvider,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 2),
    );
  }

  Widget _buildHeader(BuildContext context, String username) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.primaryOrange),
      child: Row(
        children: [
          // Logo
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset('assets/nyam_makaan.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reservasi Saya',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Hi! $username',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.list_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primaryOrange,
        tabs: const [
          Tab(text: 'Diproses'),
          Tab(text: 'Diterima'),
          Tab(text: 'Ditolak'),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Silakan login untuk melihat reservasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationContent(String userId, ReservationProvider provider) {
    // Use StreamBuilder for real-time updates
    return StreamBuilder<List<Reservation>>(
      stream: provider.getUserReservationsStream(userId),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle error state
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        // Handle data state
        if (snapshot.hasData) {
          final reservations = snapshot.data!;
          provider.updateReservations(reservations); // Update provider state

          final pending = reservations.where((r) => r.isPending).toList();
          final accepted = reservations.where((r) => r.isAccepted).toList();
          final rejected = reservations.where((r) => r.isRejected).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReservationList(
                pending,
                AppColors.primaryOrange,
                'diproses',
              ),
              _buildReservationList(accepted, Colors.green, 'diterima'),
              _buildReservationList(rejected, Colors.red, 'ditolak'),
            ],
          );
        }

        // Default empty state
        return _buildEmptyState('reservasi');
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat reservasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(
    List<Reservation> reservations,
    Color statusColor,
    String statusText,
  ) {
    if (reservations.isEmpty) {
      return _buildEmptyState(statusText);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return _buildReservationCard(reservation, statusColor);
      },
    );
  }

  Widget _buildReservationCard(Reservation reservation, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ReservationDetailScreen(reservation: reservation),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Restaurant Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image: reservation.restaurantImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(reservation.restaurantImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: reservation.restaurantImageUrl == null
                    ? const Icon(Icons.restaurant, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),

              // Reservation Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.restaurantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.formattedDate} • ${reservation.formattedTime}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.guestCount} orang • ${reservation.area}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(reservation.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Rp ${reservation.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'DIPROSES';
      case 'accepted':
        return 'DITERIMA';
      case 'rejected':
        return 'DITOLAK';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildEmptyState(String status) {
    IconData icon;
    String message;

    switch (status) {
      case 'diproses':
        icon = Icons.access_time;
        message = 'Tidak ada reservasi yang sedang diproses';
        break;
      case 'diterima':
        icon = Icons.check_circle;
        message = 'Tidak ada reservasi yang diterima';
        break;
      case 'ditolak':
        icon = Icons.cancel;
        message = 'Tidak ada reservasi yang ditolak';
        break;
      default:
        icon = Icons.list;
        message = 'Tidak ada reservasi';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Semua reservasi Anda akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FavoriteScreen()),
            );
            break;
          case 2:
            // Already on list
            break;
        }
      },
      items: [
        BottomNavItem(icon: Icons.home, label: 'Home'),
        BottomNavItem(icon: Icons.favorite, label: 'Favorite'),
        BottomNavItem(icon: Icons.list, label: 'Reservasi'),
      ],
    );
  }
}
