// widgets/reservation_card.dart
import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onTap;
  final bool showRestaurantInfo;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
    this.showRestaurantInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.restaurantName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${reservation.id.substring(0, 8)}...', // Potong ID biar tidak terlalu panjang
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),

              const SizedBox(height: 12),

              // Informasi reservasi
              _buildReservationDetails(),

              const SizedBox(height: 12),

              // Menu yang dipesan (jika ada)
              if (reservation.menuItems.isNotEmpty) _buildMenuPreview(),

              const SizedBox(height: 8),

              // Total harga
              _buildTotalPrice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;

    switch (reservation.status) {
      case 'pending_review':
      case 'pending':
        statusColor = AppColors.primaryOrange;
        statusText = 'Menunggu Review';
        break;
      case 'awaiting_payment':
        statusColor = Colors.blue;
        statusText = 'Bayar DP';
        break;
      case 'confirmed':
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Terkonfirmasi';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusText = 'Selesai';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusText = 'Dibatalkan';
        break;
      default:
        statusColor = Colors.grey;
        statusText = reservation.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReservationDetails() {
    return Column(
      children: [
        Row(
          children: [
            _buildDetailItem(Icons.calendar_today, reservation.formattedDate),
            const SizedBox(width: 16),
            _buildDetailItem(Icons.access_time, reservation.formattedTime),
            const SizedBox(width: 16),
            _buildDetailItem(Icons.people, '${reservation.guestCount} orang'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDetailItem(Icons.location_on, reservation.area),
            if (reservation.tableNumber != null) ...[
              const SizedBox(width: 16),
              _buildDetailItem(
                Icons.table_restaurant,
                'Meja ${reservation.tableNumber}',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPreview() {
    final displayedMenus = reservation.menuItems.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Column(
          children: displayedMenus.map((menu) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Text(
                    '• ${menu['name']}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${menu['quantity']}x)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (reservation.menuItems.length > 2)
          Text(
            '+${reservation.menuItems.length - 2} menu lainnya',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildTotalPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          Helpers.formatCurrency(reservation.totalAmount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryOrange,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
