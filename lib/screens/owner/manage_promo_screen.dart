// screens/owner/manage_promo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/promo_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/promo_provider.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import 'promo_form_screen.dart';

class ManagePromoScreen extends StatefulWidget {
  final Restaurant restaurant;

  const ManagePromoScreen({super.key, required this.restaurant});

  @override
  State<ManagePromoScreen> createState() => _ManagePromoScreenState();
}

class _ManagePromoScreenState extends State<ManagePromoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPromos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPromos() async {
    final promoProvider = Provider.of<PromoProvider>(context, listen: false);
    await promoProvider.loadPromosByRestaurant(widget.restaurant.id);
  }

  void _navigateToForm([Promo? promoToEdit]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PromoFormScreen(
          restaurant: widget.restaurant,
          promoToEdit: promoToEdit,
        ),
      ),
    );
    if (result == true) {
      _loadPromos();
    }
  }

  Future<void> _confirmDeactivate(Promo promo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nonaktifkan Promo?'),
        content: Text(
          promo.type == 'menu'
              ? 'Promo "${promo.title}" akan dinonaktifkan dan harga menu yang didiskon akan kembali normal.'
              : 'Promo "${promo.title}" tidak akan bisa digunakan lagi oleh pelanggan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final promoProvider = Provider.of<PromoProvider>(context, listen: false);
        await promoProvider.deactivatePromo(promo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promo berhasil dinonaktifkan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menonaktifkan promo: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Kelola Promo Resto',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryOrange,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Akan Datang'),
            Tab(text: 'Berakhir'),
          ],
        ),
      ),
      body: Consumer<PromoProvider>(
        builder: (context, promoProvider, child) {
          if (promoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (promoProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${promoProvider.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadPromos, child: const Text('Coba Lagi')),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPromoList(promoProvider.activeOwnerPromos, 'Belum ada promo aktif'),
              _buildPromoList(promoProvider.upcomingOwnerPromos, 'Belum ada promo yang akan datang'),
              _buildPromoList(promoProvider.expiredOwnerPromos, 'Belum ada riwayat promo berakhir'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Promo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPromoList(List<Promo> promos, String emptyMessage) {
    if (promos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPromos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan tombol + di bawah untuk membuat promo baru',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPromos,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          final promo = promos[index];
          return _buildPromoCard(promo);
        },
      ),
    );
  }

  Widget _buildPromoCard(Promo promo) {
    final isMenuPromo = promo.type == 'menu';
    final isCurrentlyActive = promo.isCurrentlyActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Type badge & Status chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMenuPromo ? Colors.blue.shade50 : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isMenuPromo ? Icons.restaurant_menu : Icons.confirmation_number_outlined,
                            size: 14,
                            color: isMenuPromo ? Colors.blue.shade700 : Colors.purple.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMenuPromo ? 'Promo Menu' : 'Promo Restoran',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isMenuPromo ? Colors.blue.shade700 : Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${promo.discount.toInt()}% OFF',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(promo),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    promo.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(promo),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              promo.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            if (promo.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                promo.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Meta Info: Scope & Dates
            if (isMenuPromo)
              Row(
                children: [
                  const Icon(Icons.fastfood_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${promo.menuItems.length} menu didiskon',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              )
            else if (promo.minimumOrder != null && promo.minimumOrder! > 0)
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Min. pemesanan: ${Helpers.formatCurrency(promo.minimumOrder!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),

            if (promo.note != null && promo.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: ${promo.note}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.date_range, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('dd MMM yyyy').format(promo.startDate)} - ${DateFormat('dd MMM yyyy').format(promo.endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCurrentlyActive || promo.isUpcoming) ...[
                  OutlinedButton.icon(
                    onPressed: () => _navigateToForm(promo),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryOrange,
                      side: const BorderSide(color: AppColors.primaryOrange),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _confirmDeactivate(promo),
                    icon: const Icon(Icons.power_settings_new, size: 14),
                    label: const Text('Nonaktifkan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => _navigateToForm(promo),
                    icon: const Icon(Icons.replay, size: 14),
                    label: const Text('Gunakan Ulang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBgColor(Promo promo) {
    if (!promo.isActive) return Colors.grey.shade200;
    if (promo.isUpcoming) return Colors.blue.shade50;
    if (promo.isExpired) return Colors.orange.shade50;
    return Colors.green.shade50;
  }

  Color _getStatusTextColor(Promo promo) {
    if (!promo.isActive) return Colors.grey.shade700;
    if (promo.isUpcoming) return Colors.blue.shade700;
    if (promo.isExpired) return Colors.orange.shade800;
    return Colors.green.shade700;
  }
}
