// screens/user/reservation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/reservation_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/cloudinary_service.dart';
import 'payment_screen.dart';
import '../../utils/theme.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Reservasi'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildStatusHeader(),

            const SizedBox(height: 16),

            // Informasi Reservasi
            _buildReservationInfo(),

            const SizedBox(height: 24),

            // Menu Items
            if (widget.reservation.menuItems.isNotEmpty) _buildMenuItems(),

            const SizedBox(height: 24),

            // Payment Info
            _buildPaymentInfo(),

            const SizedBox(height: 20),

            // Action Buttons berdasarkan status
            if (widget.reservation.status == 'awaiting_payment' &&
                widget.reservation.paymentProofUrl == null)
              _buildPaymentButton(),

            if (widget.reservation.status == 'awaiting_payment' &&
                widget.reservation.paymentProofUrl != null)
              _buildPaymentProofStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (widget.reservation.status) {
      case 'pending_review':
        statusColor = AppColors.primaryOrange;
        statusIcon = Icons.access_time;
        statusText = 'Menunggu Review';
        statusDescription =
            'Restoran sedang mereview permintaan reservasi Anda';
        break;
      case 'awaiting_payment':
        statusColor = Colors.blue;
        statusIcon = Icons.payment;
        statusText = 'Menunggu Pembayaran';
        statusDescription = widget.reservation.alternativeTime != null
            ? 'Restoran menawarkan jam alternatif: ${widget.reservation.alternativeTime}. Silakan bayar DP 50% untuk konfirmasi.'
            : 'Silakan bayar DP 50% untuk mengkonfirmasi reservasi';
        break;
      case 'confirmed':
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Reservasi Terkonfirmasi';
        statusDescription =
            'Pembayaran diterima. Reservasi Anda telah dikonfirmasi!';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Reservasi Ditolak';
        statusDescription =
            widget.reservation.rejectionReason ??
            'Reservasi tidak dapat diproses';
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusIcon = Icons.done_all;
        statusText = 'Selesai';
        statusDescription = 'Reservasi telah selesai. Terima kasih!';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        statusText = 'Dibatalkan';
        statusDescription =
            widget.reservation.rejectionReason ?? 'Reservasi dibatalkan';
        break;
      default:
        statusColor = AppColors.primaryOrange;
        statusIcon = Icons.access_time;
        statusText = 'Menunggu Konfirmasi';
        statusDescription =
            'Reservasi Anda sedang menunggu konfirmasi restoran';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDescription,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (widget.reservation.status == 'accepted') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Meja: ${widget.reservation.tableGroup ?? '-'} - No. ${widget.reservation.tableNumber ?? '-'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Reservasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Restoran', widget.reservation.restaurantName),
            _buildInfoRow('Tanggal', widget.reservation.formattedDate),
            _buildInfoRow('Waktu', widget.reservation.formattedTime),
            _buildInfoRow(
              'Jumlah Orang',
              '${widget.reservation.guestCount} orang',
            ),
            _buildInfoRow('Area', widget.reservation.area),
            _buildInfoRow('Nama Pemesan', widget.reservation.customerName),
            _buildInfoRow('Telepon', widget.reservation.customerPhone),
            _buildInfoRow('ID Reservasi', widget.reservation.id),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
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

  Widget _buildMenuItems() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan Menu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.reservation.menuItems.map((menuItem) {
              final totalPrice =
                  (menuItem['price'] as num).toDouble() *
                  (menuItem['quantity'] as int);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuItem['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${menuItem['quantity']} x Rp ${(menuItem['price'] as num).toDouble().toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          if (menuItem['note'] != null &&
                              menuItem['note'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Catatan: ${menuItem['note']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      'Rp ${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow('Total Pesanan', widget.reservation.totalAmount),
            _buildPaymentRow('DP 50%', widget.reservation.dpAmount),
            const Divider(),
            _buildPaymentRow(
              'Sisa Pembayaran',
              widget.reservation.totalAmount - widget.reservation.dpAmount,
              isTotal: true,
            ),
            const SizedBox(height: 12),
            _buildPaymentMethod(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primaryOrange : Colors.black,
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primaryOrange : Colors.black,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Row(
      children: [
        const Icon(Icons.payment, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          'Metode: ${widget.reservation.paymentMethod.toUpperCase()}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // ========== NEW METHODS FOR PAYMENT FLOW ==========

  Widget _buildPaymentInstructions() {
    final restaurantProvider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );

    return FutureBuilder<Restaurant?>(
      future: restaurantProvider.getRestaurantById(
        widget.reservation.restaurantId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final restaurant = snapshot.data!;

        return Card(
          elevation: 2,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Instruksi Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Silakan transfer DP 50% ke rekening:'),
                const SizedBox(height: 8),
                if (restaurant.accountName != null) ...[
                  Text(
                    'Bank: ${restaurant.bankName ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'No. Rek: ${restaurant.accountNumber ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Atas Nama: ${restaurant.accountName ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ] else ...[
                  const Text(
                    'Informasi rekening belum tersedia. Hubungi restoran.',
                    style: TextStyle(color: AppColors.primaryOrange),
                  ),
                ],
                const SizedBox(height: 8),
                const Text('Jumlah DP: ', style: TextStyle(fontSize: 14)),
                Text(
                  'Rp ${widget.reservation.dpAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                  ),
                ),
                if (restaurant.qrisImageUrl != null) ...[
                  const SizedBox(height: 12),
                  const Text('Atau scan QRIS:'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      restaurant.qrisImageUrl!,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadPaymentButton() {
    if (widget.reservation.paymentProofUrl != null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Bukti Transfer Sudah Diupload',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.reservation.paymentProofUrl!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Menunggu verifikasi dari restoran...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _uploadPaymentProof,
        icon: _isUploading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload),
        label: Text(_isUploading ? 'Mengupload...' : 'Upload Bukti Transfer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Future<void> _uploadPaymentProof() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      // Upload to Cloudinary
      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'payment_proofs',
      );

      if (uploadedUrl != null && mounted) {
        // Update reservation with payment proof
        final reservationProvider = Provider.of<ReservationProvider>(
          context,
          listen: false,
        );

        final success = await reservationProvider.uploadPaymentProof(
          widget.reservation.id,
          uploadedUrl,
        );

        setState(() {
          _isUploading = false;
        });

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bukti transfer berhasil diupload!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh screen
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengupload bukti transfer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengupload gambar ke server'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Tombol pembayaran untuk navigate ke PaymentScreen
  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PaymentScreen(reservation: widget.reservation),
            ),
          );
        },
        icon: const Icon(Icons.payment),
        label: const Text('Bayar DP 50%'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Status bukti pembayaran yang sudah diupload
  Widget _buildPaymentProofStatus() {
    final isVerified = widget.reservation.paymentVerified == true;

    return Card(
      elevation: 2,
      color: isVerified ? Colors.green[50] : Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.access_time,
                  color: isVerified ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isVerified
                        ? 'Pembayaran Terverifikasi'
                        : 'Menunggu Verifikasi Pembayaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isVerified ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isVerified
                  ? 'Pembayaran Anda sudah diverifikasi oleh restoran. Reservasi Anda sudah dikonfirmasi.'
                  : 'Bukti pembayaran Anda sedang diverifikasi oleh restoran. Mohon tunggu konfirmasi.',
              style: const TextStyle(fontSize: 12),
            ),
            if (widget.reservation.paymentProofUrl != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Bukti Pembayaran:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.reservation.paymentProofUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
