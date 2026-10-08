// screens/owner/restaurant_register_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/restaurant_model.dart';
import '../../services/restaurant_service.dart';
import '../../services/cloudinary_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import 'free_map_picker.dart';
import '../../utils/theme.dart';
import '../../widgets/PhoneNumberInput.dart';

class RestaurantRegisterScreen extends StatefulWidget {
  const RestaurantRegisterScreen({super.key});

  @override
  State<RestaurantRegisterScreen> createState() =>
      _RestaurantRegisterScreenState();
}

class _RestaurantRegisterScreenState extends State<RestaurantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _openTimeController = TextEditingController();
  final TextEditingController _closeTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _imageLinksController = TextEditingController();
  final TextEditingController _licenseLinkController = TextEditingController();

  // Payment info controllers
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  List<String> _selectedImageLinks = [];
  String? _licenseImageLink;
  String? _qrisImageUrl;
  bool _isSubmitting = false;
  bool _isUploadingImages = false;
  bool _isUploadingLicense = false;
  bool _isUploadingQRIS = false;
  GeoPoint? _location;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Set default values
    _openTimeController.text = '08:00';
    _closeTimeController.text = '22:00';
    _minPriceController.text = '15000';
    _maxPriceController.text = '50000';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header oren melengkung
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Daftarkan Resto',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daftar sebagai Merchant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lengkapi data restoran Anda untuk bergabung dengan Nyam! Makaan',
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 24),

                    // Restaurant Info Section
                    _buildSectionHeader('Informasi Restoran'),
                    _buildTextField(
                      _nameController,
                      'Nama Resto',
                      'Isikan nama',
                      Icons.restaurant,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama resto harus diisi';
                        }
                        return null;
                      },
                    ),
                    PhoneNumberInput(
                      onChanged: (value) {
                        _phoneController.text = value;
                      },
                      initialPhoneNumber: _phoneController.text,
                    ),

                    // Operating Hours
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _openTimeController,
                            'Jam Buka',
                            '08:00',
                            Icons.access_time,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Jam buka harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            _closeTimeController,
                            'Jam Tutup',
                            '22:00',
                            Icons.access_time,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Jam tutup harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    _buildTextField(
                      _descriptionController,
                      'Deskripsi Singkat',
                      'Isikan deskripsi resto',
                      Icons.description,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi harus diisi';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      _categoryController,
                      'Kategori',
                      'Contoh: Ayam, Ramen, Cafe',
                      Icons.category,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kategori harus diisi';
                        }
                        return null;
                      },
                    ),

                    // Price Range
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _minPriceController,
                            'Harga Minimum (Rp)',
                            '15000',
                            Icons.money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Harga minimum harus diisi';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Harga harus berupa angka';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            _maxPriceController,
                            'Harga Maksimum (Rp)',
                            '50000',
                            Icons.money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Harga maksimum harus diisi';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Harga harus berupa angka';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Location Section
                    _buildLocationSection(),

                    const SizedBox(height: 24),

                    // Restaurant Photos
                    _buildImageLinkSection(),

                    const SizedBox(height: 24),

                    // License Upload
                    _buildLicenseLinkSection(),

                    const SizedBox(height: 24),

                    // Payment Info Section
                    _buildPaymentInfoSection(),

                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryOrange,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryOrange,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryOrange,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi & Alamat Restoran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Alamat dari peta
        if (_addressController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryOrange, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alamat:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _addressController.text,
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (_location != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${_location!.latitude.toStringAsFixed(6)}, Lng: ${_location!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pilih lokasi pada peta untuk mengisi alamat otomatis',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Tombol-tombol lokasi dalam column (VERTIKAL)
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Dapatkan Lokasi Saat Ini'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectLocationFromMap,
                icon: const Icon(Icons.map),
                label: const Text('Pilih Lokasi dari Peta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Note: Untuk demo, menggunakan lokasi default Jakarta',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildImageLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Restoran (minimal 1-3 gambar)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Upload Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUploadingImages ? null : _uploadRestaurantImages,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF873300),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: _isUploadingImages
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mengupload...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Upload Gambar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 8),

        // Selected Images Grid
        if (_selectedImageLinks.isNotEmpty) ...[
          const Text(
            'Gambar yang akan diupload:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImageLinks.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: Image.network(
                      _selectedImageLinks[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                'Error',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageLinks.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildLicenseLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Surat Izin Usaha',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Upload License Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUploadingLicense ? null : _uploadLicenseImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF873300),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: _isUploadingLicense
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mengupload...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Upload Gambar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 8),

        // Preview License Image
        if (_licenseImageLink != null) ...[
          const Text(
            'Preview Surat Izin:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: Image.network(
              _licenseImageLink!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      Text('Gambar tidak dapat dimuat'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Informasi Pembayaran'),

        const Text(
          'Transfer Bank',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _bankNameController,
          'Nama Bank',
          'Contoh: BCA, BNI, Mandiri',
          Icons.account_balance,
        ),

        _buildTextField(
          _accountNumberController,
          'Nomor Rekening',
          'Contoh: 1234567890',
          Icons.credit_card,
          keyboardType: TextInputType.number,
        ),

        _buildTextField(
          _accountHolderController,
          'Atas Nama',
          'Nama pemilik rekening',
          Icons.person,
        ),

        const SizedBox(height: 16),

        const Text(
          'QRIS (Opsional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Upload QRIS Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUploadingQRIS ? null : _uploadQRISImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF873300),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: _isUploadingQRIS
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mengupload...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Upload QRIS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 8),

        // Preview QRIS Image
        if (_qrisImageUrl != null) ...[
          const Text(
            'Preview QRIS:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: Image.network(
              _qrisImageUrl!,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      Text('Gambar tidak dapat dimuat'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Daftar', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _uploadRestaurantImages() async {
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
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImages = true;
      });

      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'restaurants',
      );

      if (uploadedUrl != null) {
        setState(() {
          _selectedImageLinks.add(uploadedUrl);
          if (_selectedImageLinks.length > 3) {
            _selectedImageLinks = _selectedImageLinks.sublist(0, 3);
          }
          _isUploadingImages = false;
        });

        _showSuccess('Gambar berhasil diupload');
      } else {
        setState(() {
          _isUploadingImages = false;
        });
        _showError('Gagal upload gambar');
      }
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      _showError('Error: $e');
    }
  }

  Future<void> _uploadLicenseImage() async {
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
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingLicense = true;
      });

      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'licenses',
      );

      if (uploadedUrl != null) {
        setState(() {
          _licenseImageLink = uploadedUrl;
          _isUploadingLicense = false;
        });

        _showSuccess('Surat izin berhasil diupload');
      } else {
        setState(() {
          _isUploadingLicense = false;
        });
        _showError('Gagal upload surat izin');
      }
    } catch (e) {
      setState(() {
        _isUploadingLicense = false;
      });
      _showError('Error: $e');
    }
  }

  Future<void> _uploadQRISImage() async {
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
                  'Pilih Sumber Foto QRIS',
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
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
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

        _showSuccess('QRIS berhasil diupload');
      } else {
        setState(() {
          _isUploadingQRIS = false;
        });
        _showError('Gagal upload QRIS');
      }
    } catch (e) {
      setState(() {
        _isUploadingQRIS = false;
      });
      _showError('Error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Buka FreeMapPicker untuk pilih lokasi dengan GPS
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FreeMapPicker(initialLocation: _location),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _location = result['location'] as GeoPoint;
          _addressController.text = result['address'] as String;
        });

        _showSuccess('Lokasi dan alamat berhasil dipilih');
      }
    } catch (e) {
      _showError('Gagal mendapatkan lokasi: $e');

      // Fallback ke default location
      setState(() {
        _location = const GeoPoint(-6.2088, 106.8456);
        _addressController.text = 'Jakarta, Indonesia (default)';
      });
    }
  }

  Future<void> _selectLocationFromMap() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FreeMapPicker(initialLocation: _location),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _location = result['location'] as GeoPoint;
          _addressController.text = result['address'] as String;
        });

        _showSuccess('Lokasi dan alamat berhasil dipilih dari peta');
      }
    } catch (e) {
      _showError('Gagal memilih lokasi dari peta: $e');
    }
  }

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageLinks.isEmpty) {
      _showError('Harap tambahkan minimal 1 link foto restoran');
      return;
    }

    if (_licenseImageLink == null) {
      _showError('Harap tambahkan link surat izin usaha');
      return;
    }

    if (_addressController.text.isEmpty) {
      _showError('Harap pilih lokasi pada peta untuk mengisi alamat');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );

    if (authProvider.user == null) {
      _showError('User tidak ditemukan');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Parse categories dari text input
      List<String> categories = _categoryController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Gunakan lokasi default jika belum dipilih
      final location = _location ?? const GeoPoint(-6.2088, 106.8456);

      // Create restaurant object menggunakan constructor yang ada
      final restaurant = Restaurant(
        id: '', // ID akan digenerate oleh service
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        description: _descriptionController.text,
        images: _selectedImageLinks,
        openingHours: {
          'open': _openTimeController.text,
          'close': _closeTimeController.text,
        },
        categories: categories,
        priceRange: {
          'min': double.parse(_minPriceController.text),
          'max': double.parse(_maxPriceController.text),
        },
        license: _licenseImageLink!,
        ownerId: authProvider.user!.id,
        ownerEmail: authProvider.user!.email, // Email pemilik untuk notifikasi
        owner: authProvider.user!.username, // Nama pemilik
        location: location,
        status: 'pending', // Status awal pending
        rating: 0,
        totalReviews: 0,
        // Payment info
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore menggunakan provider
      bool success = await restaurantProvider.createRestaurant(restaurant);

      if (success) {
        // Show success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RegistrationSuccessScreen(),
          ),
        );
      } else {
        _showError(restaurantProvider.error ?? 'Gagal mendaftarkan resto');
      }
    } catch (e) {
      _showError('Gagal mendaftar: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Registrasi Gagal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: AppColors.primaryOrange),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Berhasil!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _imageLinksController.dispose();
    _licenseLinkController.dispose();
    super.dispose();
  }
}

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
              const SizedBox(height: 24),
              const Text(
                'Terima Kasih sudah mendaftar!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tim Nyam! Makaan akan segera konfirmasi dan tinjau lokasi. Harap Tunggu, Ya!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Kembali ke splash screen untuk reload flow
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Kembali ke Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
