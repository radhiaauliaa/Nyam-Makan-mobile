// screens/owner/payment_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/restaurant_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/theme.dart';

class PaymentSettingsScreen extends StatefulWidget {
  final Restaurant restaurant;

  const PaymentSettingsScreen({super.key, required this.restaurant});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountHolderController;

  // State
  String? _qrisImageUrl;
  bool _isUploadingQRIS = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(
      text: widget.restaurant.bankName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.restaurant.accountNumber ?? '',
    );
    _accountHolderController = TextEditingController(
      text: widget.restaurant.accountName ?? '',
    );
    _qrisImageUrl = widget.restaurant.qrisImageUrl;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pengaturan Pembayaran'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildTransferSection(),
              const SizedBox(height: 20),
              _buildQRISSection(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Atur metode pembayaran yang akan digunakan customer untuk pembayaran DP reservasi',
              style: TextStyle(color: Colors.blue[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Transfer Bank',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bankNameController,
          decoration: InputDecoration(
            labelText: 'Nama Bank',
            hintText: 'Contoh: BCA, Mandiri, BNI',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Nomor Rekening',
            hintText: 'Masukkan nomor rekening',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accountHolderController,
          decoration: InputDecoration(
            labelText: 'Nama Pemilik Rekening',
            hintText: 'Sesuai dengan nama di rekening',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildQRISSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code, color: AppColors.primaryOrange),
            ),
            const SizedBox(width: 12),
            const Text(
              'QRIS / E-Wallet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_qrisImageUrl != null) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _qrisImageUrl!,
                height: 300,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploadingQRIS ? null : _uploadQRISImage,
                  icon: const Icon(Icons.edit),
                  label: const Text('Ganti QRIS'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _qrisImageUrl = null;
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          InkWell(
            onTap: _isUploadingQRIS ? null : _uploadQRISImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Center(
                child: _isUploadingQRIS
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Mengupload QRIS...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap untuk upload QRIS',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Format: JPG, PNG (Max 5MB)',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _savePaymentSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Simpan Pengaturan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _uploadQRISImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingQRIS = true;
      });

      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'qris',
      );

      if (uploadedUrl != null) {
        setState(() {
          _qrisImageUrl = uploadedUrl;
          _isUploadingQRIS = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QRIS berhasil diupload'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Upload gagal');
      }
    } catch (e) {
      setState(() {
        _isUploadingQRIS = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload QRIS: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePaymentSettings() async {
    // Validasi: minimal satu metode pembayaran harus diisi
    final bool hasTransfer =
        _bankNameController.text.isNotEmpty &&
        _accountNumberController.text.isNotEmpty &&
        _accountHolderController.text.isNotEmpty;
    final bool hasQRIS = _qrisImageUrl != null && _qrisImageUrl!.isNotEmpty;

    if (!hasTransfer && !hasQRIS) {
      _showErrorDialog(
        'Minimal isi salah satu metode pembayaran (Transfer Bank atau QRIS)',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final restaurantProvider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      // Update restaurant dengan info pembayaran baru
      final updatedRestaurant = widget.restaurant.copyWith(
        bankName: _bankNameController.text.isNotEmpty
            ? _bankNameController.text
            : null,
        accountNumber: _accountNumberController.text.isNotEmpty
            ? _accountNumberController.text
            : null,
        accountName: _accountHolderController.text.isNotEmpty
            ? _accountHolderController.text
            : null,
        qrisImageUrl: _qrisImageUrl,
      );

      await restaurantProvider.updateRestaurant(updatedRestaurant);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorDialog('Gagal menyimpan pengaturan: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            const Text('Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryOrange,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pengaturan pembayaran berhasil disimpan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
