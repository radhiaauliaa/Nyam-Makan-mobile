// screens/owner/manage_reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/restaurant_model.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import 'owner_home_screen.dart';
import 'manage_menu_screen.dart';
import '../../services/fcm_service.dart';
import 'package:intl/intl.dart';

class ManageReservationScreen extends StatefulWidget {
  const ManageReservationScreen({super.key});

  @override
  State<ManageReservationScreen> createState() =>
      _ManageReservationScreenState();
}

class _ManageReservationScreenState extends State<ManageReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load reservations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservations();
    });
  }

  void _loadReservations() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      // Load restaurant data first
      restaurantProvider.loadCurrentRestaurant(authProvider.user!.id).then((_) {
        // Then load reservations using restaurant ID
        if (restaurantProvider.currentRestaurant != null) {
          reservationProvider.loadRestaurantReservations(
            restaurantProvider.currentRestaurant!.id,
          );
        }
      });
    }
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

    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, _) {
        final restaurant = restaurantProvider.currentRestaurant;

        return Scaffold(
          backgroundColor: const Color(0xFFEEEEEE),
          body: Column(
            children: [
              // Header dengan background orange curved
              _buildHeader(context, restaurant),

              // Tabs
              Container(
                color: AppColors.primaryOrange,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFFFFE4D6),
                  indicatorColor: Colors.white,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Belum Diproses'),
                    Tab(text: 'Diterima'),
                    Tab(text: 'Ditolak'),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Overview
                      _buildStatsOverview(reservationProvider, authProvider),

                      const SizedBox(height: 12),

                      // Loading indicator
                      if (reservationProvider.isLoading)
                        const LinearProgressIndicator(),

                      if (reservationProvider.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Error: ${reservationProvider.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Belum Diproses (pending_review only)
                            _buildReservationList(
                              reservationProvider.pendingReviewReservations,
                              'pending',
                            ),
                            // Tab 2: Diterima (awaiting_payment + confirmed)
                            _buildReservationList([
                              ...reservationProvider
                                  .awaitingPaymentReservations,
                              ...reservationProvider.confirmedReservations,
                            ], 'accepted'),
                            // Tab 3: Ditolak (rejected)
                            _buildReservationList(
                              reservationProvider.rejectedReservations,
                              'rejected',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: OwnerBottomNavBar(
            currentIndex: 2,
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerHomeScreen(),
                  ),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageMenuScreen(),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsOverview(
    ReservationProvider reservationProvider,
    AuthProvider authProvider,
  ) {
    // Hitung stats dengan status baru
    final pendingCount = reservationProvider.pendingReviewReservations.length;
    final acceptedCount =
        reservationProvider.awaitingPaymentReservations.length +
        reservationProvider.confirmedReservations.length;
    final rejectedCount = reservationProvider.rejectedReservations.length;
    final totalCount = reservationProvider.reservations.length;

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
                'Detail Reservasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // // Restaurant name from restaurant provider
          // Consumer<RestaurantProvider>(
          //   builder: (context, restaurantProvider, _) {
          //     if (restaurantProvider.currentRestaurant != null) {
          //       return Text(
          //         restaurantProvider.currentRestaurant!.name,
          //         style: const TextStyle(fontSize: 12, color: Colors.grey),
          //       );
          //     }
          //     return const SizedBox.shrink();
          //   },
          // ),
          // const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Jumlah Reservasi',
                totalCount.toString(),
                Colors.blue,
              ),
              _buildStatItem(
                'Reservasi Masuk',
                pendingCount.toString(),
                AppColors.primaryOrange,
              ),
              _buildStatItem(
                'Diterima',
                acceptedCount.toString(),
                Colors.green,
              ),
              _buildStatItem('Ditolak', rejectedCount.toString(), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReservationList(List<Reservation> reservations, String status) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getStatusIcon(status), size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(status),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        return _buildReservationCard(reservations[index], status);
      },
    );
  }

  Widget _buildReservationCard(Reservation reservation, String status) {
    // Tentukan warna dan text berdasarkan status aktual reservasi
    Color statusColor;
    String statusText;

    switch (reservation.status) {
      case 'pending_review':
        statusColor = AppColors.primaryOrange;
        statusText = 'Menunggu Review';
        break;
      case 'awaiting_payment':
        // Jika sudah upload bukti, tampilkan "Menunggu Konfirmasi" dengan warna biru
        if (reservation.paymentProofUrl != null &&
            reservation.paymentProofUrl!.isNotEmpty) {
          statusColor = Colors.blue;
          statusText = 'Menunggu Konfirmasi';
        } else {
          statusColor = AppColors.primaryOrange;
          statusText = 'Menunggu Pembayaran';
        }
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'Telah Diterima';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusText = 'Selesai';
        break;
      default:
        statusColor = _getStatusColor(status);
        statusText = _getStatusText(status);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _showReservationDetailDialog(reservation);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer Info
            _buildInfoRow('Jumlah Orang', '${reservation.guestCount} orang'),
            _buildInfoRow('Nomor Telepon', reservation.customerPhone),
            _buildInfoRow('Area', reservation.area),
            _buildInfoRow(
              'Waktu',
              '${reservation.formattedDate} ${reservation.formattedTime}',
            ),

            // Menu items (tampilkan 2 pertama)
            if (reservation.menuItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Menu:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              ...reservation.menuItems.take(2).map((menu) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${menu['name']} (${menu['quantity']}x)',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }),
              if (reservation.menuItems.length > 2)
                Text(
                  '+${reservation.menuItems.length - 2} menu lainnya',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],

            // Payment info
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp ${reservation.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),

            // Alternative time if offered
            if (reservation.alternativeTime != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jam alternatif: ${reservation.alternativeTime}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (reservation.tableNumber != null)
              _buildInfoRow(
                'Meja',
                '${reservation.tableGroup} - No. ${reservation.tableNumber}',
              ),

            if (reservation.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alasan: ${reservation.rejectionReason}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            if (status == 'pending' || status == 'pending_review')
              _buildPendingActions(reservation),
            if (status == 'awaiting_payment')
              _buildAwaitingPaymentActions(reservation),
            if (status == 'confirmed') _buildConfirmedActions(reservation),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions(Reservation reservation) {
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _approveReservation(reservation, reservationProvider);
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Setujui'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _offerAlternativeTime(reservation, reservationProvider);
                },
                icon: const Icon(Icons.schedule, size: 16),
                label: const Text('Jam Lain'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _rejectReservation(reservation, reservationProvider);
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Tolak Reservasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // New action buttons for awaiting_payment status
  Widget _buildAwaitingPaymentActions(Reservation reservation) {
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );

    return Column(
      children: [
        if (reservation.paymentProofUrl != null) ...[
          OutlinedButton.icon(
            onPressed: () {
              _showPaymentProof(reservation);
            },
            icon: const Icon(Icons.receipt, size: 16),
            label: const Text('Lihat Bukti Transfer'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _verifyPayment(reservation, reservationProvider, true);
                  },
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Konfirmasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _verifyPayment(reservation, reservationProvider, false);
                  },
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Tolak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const Text(
            'Menunggu customer upload bukti transfer',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmedActions(Reservation reservation) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showReservationDetails(reservation);
        },
        icon: const Icon(Icons.visibility, size: 16),
        label: const Text('Lihat Detail'),
      ),
    );
  }

  void _showPaymentProof(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bukti Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (reservation.paymentProofUrl != null)
                Image.network(
                  reservation.paymentProofUrl!,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text('Gambar tidak dapat dimuat'),
                      ),
                    );
                  },
                )
              else
                Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('Tidak ada bukti pembayaran'),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'DP 50%: Rp ${reservation.dpAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTableAssignment(Reservation reservation) {
    String? selectedTable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Penempatan Meja',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih nomor meja untuk reservasi ini'),
                  const SizedBox(height: 16),

                  // Table Selection
                  DropdownButtonFormField<String>(
                    initialValue: selectedTable,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Meja',
                      border: OutlineInputBorder(),
                    ),
                    items: ['17', '18', '19', '20', '21'].map((table) {
                      return DropdownMenuItem(
                        value: table,
                        child: Text('Meja $table - ${reservation.area}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTable = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // No Table Available Option
                  Row(
                    children: [
                      Checkbox(
                        value: selectedTable == 'none',
                        onChanged: (value) {
                          setState(() {
                            selectedTable = value! ? 'none' : null;
                          });
                        },
                      ),
                      const Text('Tidak ada meja yang tersedia'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedTable != null
                              ? () {
                                  Navigator.pop(context);
                                  if (selectedTable != 'none') {
                                    _assignTable(reservation, selectedTable!);
                                  }
                                }
                              : null,
                          child: const Text('Oke'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _assignTable(Reservation reservation, String tableNumber) async {
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );

    final success = await reservationProvider.assignTable(
      reservation.id,
      'Lt.1 (${reservation.area})',
      tableNumber,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meja berhasil ditetapkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menetapkan meja: ${reservationProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _acceptReservation(
    Reservation reservation,
    ReservationProvider reservationProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Reservasi'),
        content: const Text('Apakah Anda yakin ingin menerima reservasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await reservationProvider.updateReservationStatus(
                reservation.id,
                'accepted',
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reservasi berhasil diterima'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal menerima reservasi: ${reservationProvider.error}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Terima'),
          ),
        ],
      ),
    );
  }

  // ========== NEW METHODS FOR UPDATED FLOW ==========

  void _approveReservation(
    Reservation reservation,
    ReservationProvider reservationProvider,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui Reservasi'),
        content: const Text(
          'Customer akan diminta untuk membayar DP 50% setelah disetujui. Setelah customer upload bukti transfer, Anda perlu memverifikasinya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Memproses...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              final success = await reservationProvider.approveReservation(
                reservation.id,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Reservasi disetujui! Customer akan diminta bayar DP.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                // Reload reservations
                _loadReservations();
                setState(() {}); // Force refresh UI
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal menyetujui: ${reservationProvider.error ?? "Unknown error"}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _rejectReservation(
    Reservation reservation,
    ReservationProvider reservationProvider,
  ) async {
    String? selectedReason;
    final List<String> rejectionReasons = [
      'Tempat penuh',
      'Waktu tidak tersedia',
      'Permintaan menu tidak tersedia',
      'Restoran tutup pada tanggal tersebut',
      'Lainnya',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tolak Reservasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih alasan penolakan:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Pilih alasan'),
                items: rejectionReasons.map((reason) {
                  return DropdownMenuItem(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
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
                if (selectedReason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap pilih alasan penolakan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Show loading
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Memproses...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }

                final success = await reservationProvider.rejectReservation(
                  reservation.id,
                  selectedReason!,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reservasi ditolak'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  // Reload reservations
                  _loadReservations();
                  setState(() {}); // Force refresh UI
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menolak: ${reservationProvider.error ?? "Unknown error"}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tolak'),
            ),
          ],
        ),
      ),
    );
  }

  void _offerAlternativeTime(
    Reservation reservation,
    ReservationProvider reservationProvider,
  ) async {
    TimeOfDay? selectedTime = TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tawarkan Jam Alternatif'),
          content: Text('Tawarkan jam $formattedTime kepada customer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final success = await reservationProvider.offerAlternativeTime(
                  reservation.id,
                  formattedTime,
                );

                if (success) {
                  // Reload reservations
                  _loadReservations();
                  setState(() {}); // Force refresh UI

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jam alternatif berhasil ditawarkan'),
                        backgroundColor: AppColors.primaryOrange,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal: ${reservationProvider.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text('Kirim'),
            ),
          ],
        ),
      );
    }
  }

  void _verifyPayment(
    Reservation reservation,
    ReservationProvider reservationProvider,
    bool isValid,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isValid ? 'Terima Pembayaran' : 'Tolak Pembayaran'),
        content: Text(
          isValid
              ? 'Bukti transfer valid? Reservasi akan dikonfirmasi.'
              : 'Bukti transfer tidak valid? Customer harus upload ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await reservationProvider.verifyPaymentProof(
                reservation.id,
                isValid,
              );

              if (success) {
                // Reload reservations
                _loadReservations();
                setState(() {}); // Force refresh UI

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isValid
                            ? 'Pembayaran diterima. Reservasi terkonfirmasi!'
                            : 'Pembayaran ditolak. Customer diminta upload ulang.',
                      ),
                      backgroundColor: isValid
                          ? Colors.green
                          : AppColors.primaryOrange,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: ${reservationProvider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? Colors.green : Colors.red,
            ),
            child: Text(isValid ? 'Terima' : 'Tolak'),
          ),
        ],
      ),
    );
  }

  // Method yang dipanggil dari icon titik 3
  void _showReservationDetailDialog(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ReservationDetailScreen(reservation: reservation),
      ),
    );
  }

  void _showReservationDetails(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ReservationDetailScreen(reservation: reservation),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Restaurant? restaurant) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
      ),
      decoration: const BoxDecoration(color: AppColors.primaryOrange),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kelola Reservasi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (restaurant != null)
            Text(
              restaurant.name,
              style: const TextStyle(fontSize: 16, color: Color(0xFFFFE4D6)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  void _contactCustomer(Reservation reservation) {
    // Implement phone call functionality
    // You can use url_launcher package to make phone calls
  }

  Widget _buildBottomNavBar(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, currentIndex),
              _buildNavItem(Icons.restaurant_menu, 'Menu', 1, currentIndex),
              _buildNavItem(Icons.event_seat, 'Reservasi', 2, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
    final isSelected = index == currentIndex;
    return InkWell(
      onTap: () {
        if (index != currentIndex) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OwnerHomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ManageMenuScreen()),
            );
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
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
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Tidak ada reservasi yang menunggu konfirmasi';
      case 'accepted':
        return 'Tidak ada reservasi yang diterima';
      case 'rejected':
        return 'Tidak ada reservasi yang ditolak';
      default:
        return 'Tidak ada data';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.primaryOrange;
      case 'accepted':
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
      case 'accepted':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}

// Detail screen widget (full screen like user side)
class _ReservationDetailScreen extends StatelessWidget {
  final Reservation reservation;

  const _ReservationDetailScreen({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Reservasi'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner if awaiting payment
            if (reservation.status == 'awaiting_payment' &&
                (reservation.paymentProofUrl == null ||
                    reservation.paymentProofUrl!.isEmpty))
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menunggu Pembayaran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            'Customer belum upload bukti pembayaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Informasi Reservasi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Reservasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Nama Pemesan', reservation.customerName),
                  _buildDetailRow('Nomor Telepon', reservation.customerPhone),
                  _buildDetailRow('Tanggal', reservation.formattedDate),
                  _buildDetailRow('Waktu', reservation.formattedTime),
                  _buildDetailRow(
                    'Jumlah Orang',
                    '${reservation.guestCount} orang',
                  ),
                  _buildDetailRow('Area', reservation.area),
                  if (reservation.tableGroup != null)
                    _buildDetailRow('Grup Meja', reservation.tableGroup!),
                  if (reservation.tableNumber != null)
                    _buildDetailRow('Nomor Meja', reservation.tableNumber!),
                  _buildDetailRow('ID Reservasi', reservation.id),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pesanan Menu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pesanan Menu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...reservation.menuItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item['name']}')),
                          Text(
                            'Rp ${item['price'].toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informasi Pembayaran
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pesanan'),
                      Text(
                        'Rp ${reservation.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('DP 50%'),
                      Text(
                        'Rp ${reservation.dpAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sisa Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      Text(
                        'Rp ${(reservation.totalAmount - reservation.dpAmount).toStringAsFixed(0)}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
