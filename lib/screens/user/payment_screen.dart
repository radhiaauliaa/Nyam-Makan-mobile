// screens/user/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/reservation_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/theme.dart';

class PaymentScreen extends StatefulWidget {
  final Reservation reservation;

  const PaymentScreen({super.key, required this.reservation});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isUploading = false;
  Restaurant? _restaurant;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final restaurantProvider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );
    final restaurant = await restaurantProvider.getRestaurantById(
      widget.reservation.restaurantId,
    );
    setState(() {
      _restaurant = restaurant;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pembayaran DP 50%'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _restaurant == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReservationInfo(),
                  const SizedBox(height: 24),
                  _buildPaymentAmount(),
                  const SizedBox(height: 24),
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),
                  _buildPaymentInstructions(),
                  const SizedBox(height: 24),
                  _buildUploadSection(),
                ],
              ),
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
            Row(
              children: [
                const Icon(Icons.restaurant, color: AppColors.primaryOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.reservation.restaurantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Tanggal', widget.reservation.formattedDate),
            _buildInfoRow('Waktu', widget.reservation.formattedTime),
            _buildInfoRow(
              'Jumlah Orang',
              '${widget.reservation.guestCount} orang',
            ),
            _buildInfoRow('Area', widget.reservation.area),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPaymentAmount() {
    return Card(
      elevation: 2,
      color: AppColors.lightOrange,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildAmountRow(
              'Total Pesanan',
              widget.reservation.totalAmount,
              isSubtotal: true,
            ),
            _buildAmountRow(
              'DP 50%',
              widget.reservation.dpAmount,
              isSubtotal: true,
            ),
            const Divider(height: 24),
            _buildAmountRow(
              'Yang harus dibayar',
              widget.reservation.dpAmount,
              isTotal: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sisa ${_formatCurrency(widget.reservation.totalAmount - widget.reservation.dpAmount)} dibayar saat di restoran',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isSubtotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isSubtotal ? Colors.grey[700] : Colors.black,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppColors.primaryOrange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    if (_restaurant == null) return const SizedBox();

    // Check jika tidak ada metode pembayaran yang tersedia
    final bool hasTransfer =
        _restaurant!.accountNumber != null &&
        _restaurant!.accountNumber!.isNotEmpty;
    final bool hasQRIS =
        _restaurant!.qrisImageUrl != null &&
        _restaurant!.qrisImageUrl!.isNotEmpty;

    if (!hasTransfer && !hasQRIS) {
      return Card(
        elevation: 2,
        color: Colors.orange[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.orange[700]),
              const SizedBox(height: 12),
              Text(
                'Metode Pembayaran Belum Tersedia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Restoran belum mengatur informasi pembayaran. Silakan hubungi restoran untuk informasi lebih lanjut.',
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        // Transfer Manual
        if (hasTransfer) _buildTransferMethod(),

        if (hasTransfer && hasQRIS) const SizedBox(height: 12),

        // QRIS
        if (hasQRIS) _buildQRISMethod(),
      ],
    );
  }

  Widget _buildTransferMethod() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Transfer Manual',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildTransferDetail(
              'Bank',
              _restaurant!.bankName ?? 'BCA Bank Central Asia',
              Icons.account_balance,
            ),
            _buildTransferDetail(
              'No. Rekening',
              _restaurant!.accountNumber ?? '',
              Icons.credit_card,
              canCopy: true,
            ),
            _buildTransferDetail(
              'Atas Nama',
              _restaurant!.accountName ?? '',
              Icons.person,
            ),
            _buildTransferDetail(
              'Jumlah Transfer',
              _formatCurrency(widget.reservation.dpAmount),
              Icons.payments,
              isAmount: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Catatan Penting:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildNote('Pastikan jumlah pembayaran sesuai dengan DP 50%'),
                  _buildNote('Batas waktu pembayaran 24 jam'),
                  _buildNote('Pastikan jumlah transfer tepat'),
                  _buildNote(
                    'Reservasi otomatis dibatalkan jika tidak ada pembayaran',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferDetail(
    String label,
    String value,
    IconData icon, {
    bool canCopy = false,
    bool isAmount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
                    fontSize: isAmount ? 16 : 14,
                    color: isAmount ? AppColors.primaryOrange : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nomor rekening berhasil disalin'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Salin',
            ),
        ],
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildQRISMethod() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Scan QRIS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Image.network(
                      _restaurant!.qrisImageUrl!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.error, color: Colors.red),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatCurrency(widget.reservation.dpAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const Text(
                      'Scan untuk bayar via QRIS',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Informasi Penting',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '1',
            'Pastikan jumlah pembayaran sesuai dengan DP 50%',
          ),
          _buildInstructionStep(
            '2',
            'Upload bukti pembayaran yang jelas dan terbaca',
          ),
          _buildInstructionStep(
            '3',
            'Reservasi akan dikonfirmasi setelah pembayaran diverifikasi oleh admin',
          ),
          _buildInstructionStep(
            '4',
            'Untuk pertanyaan, hubungi restoran langsung',
          ),
          _buildInstructionStep(
            '5',
            'Sisa pembayaran dapat dilakukan di restoran',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    if (widget.reservation.paymentProofUrl != null) {
      return _buildExistingProof();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Bukti Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.upload_file, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Klik untuk upload atau drag & drop',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'JPG, PNG, atau PDF (Max 5MB)',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadPaymentProof,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _isUploading ? 'Mengupload...' : 'Pilih Bukti Pembayaran',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingProof() {
    return Card(
      elevation: 2,
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bukti Pembayaran Berhasil Diupload',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.reservation.paymentProofUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.reservation.paymentVerified == true
                          ? 'Pembayaran sudah diverifikasi'
                          : 'Menunggu verifikasi dari restoran',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPaymentProof() async {
    // Show dialog untuk pilih sumber gambar
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryOrange,
                  ),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryOrange,
                  ),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      // Upload to Cloudinary
      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'payment_proofs/${widget.reservation.id}',
      );

      if (uploadedUrl != null && mounted) {
        // Update reservation with payment proof
        final reservationProvider = Provider.of<ReservationProvider>(
          context,
          listen: false,
        );

        await reservationProvider.uploadPaymentProof(
          widget.reservation.id,
          uploadedUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bukti pembayaran berhasil diupload'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Kembali ke detail reservasi
        }
      } else {
        throw Exception('Gagal mengupload gambar');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload bukti: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
