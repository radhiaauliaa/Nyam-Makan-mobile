// screens/owner/edit_restaurant_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/theme.dart';
import '../../models/restaurant_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import 'add_promo_screen.dart';

class EditRestaurantScreen extends StatefulWidget {
  const EditRestaurantScreen({super.key});

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _openTimeController = TextEditingController();
  final TextEditingController _closeTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late Restaurant _restaurant;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isUploadingMenuImage = false;
  List<String> _newImages = []; // Images restoran yang baru diupload
  List<String> _menuImages = []; // Images menu yang baru diupload

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );

    try {
      // Load restaurant data based on logged-in user
      await restaurantProvider.loadCurrentRestaurant(auth.user!.id);

      if (restaurantProvider.currentRestaurant != null) {
        _restaurant = restaurantProvider.currentRestaurant!;

        // Set controller values from actual data
        _phoneController.text = _restaurant.phone;
        _openTimeController.text = _restaurant.openTime;
        _closeTimeController.text = _restaurant.closeTime;
        _descriptionController.text = _restaurant.description;

        // Initialize newImages with existing images
        _newImages = List.from(_restaurant.images);
      }
    } catch (e) {
      print('Error loading restaurant data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: Column(
        children: [
          // Header dengan background orange curved
          _buildHeader(context),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Info Header - USING ACTUAL DATA
                  _buildRestaurantHeader(),

                  const SizedBox(height: 24),

                  // Edit Form
                  _buildEditForm(),

                  const SizedBox(height: 32),

                  // Update Button
                  _buildUpdateButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profil Resto',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Perbarui informasi restoran',
                  style: TextStyle(fontSize: 16, color: Color(0xFFFFE4D6)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: _saveChanges,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: _restaurant.images.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_restaurant.images.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _restaurant.images.isEmpty
                ? const Icon(Icons.restaurant, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _restaurant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _restaurant.categories.isNotEmpty
                      ? _restaurant.categories.join(' • ')
                      : 'Tidak ada kategori',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${_restaurant.rating}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_restaurant.totalReviews} ulasan)',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(_restaurant.status),
                  style: TextStyle(
                    color: _getStatusColor(_restaurant.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_phoneController, 'Nomor Telepon', Icons.phone),
        _buildOperatingHours(),
        _buildTextField(
          _descriptionController,
          'Deskripsi Singkat',
          Icons.description,
          maxLines: 3,
        ),
        _buildPromoSection(),
        _buildImageUploadSection(), // Foto Restoran
        const SizedBox(height: 16),
        // _buildMenuImageUploadSection(), // Foto Menu
      ],
    );
  }

  Widget _buildPromoSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Promo Resto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primaryOrange),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddPromoScreen(restaurant: _restaurant),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Placeholder for existing promos - you can fetch from Firestore later
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Tambah promo dengan menekan tombol +',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
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
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHours() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jam Buka dan Tutup',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _openTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Buka',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _closeTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Tutup',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Restoran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Current Images
        if (_newImages.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _newImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(_newImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _newImages.removeAt(index);
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

        // Add More Images Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUploadingImage ? null : _addMoreImages,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF873300),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: _isUploadingImage
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
      ],
    );
  }

  // Widget _buildMenuImageUploadSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Foto Menu',
  //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  //       ),
  //       const SizedBox(height: 8),

  //       // Current Menu Images
  //       if (_menuImages.isNotEmpty) ...[
  //         GridView.builder(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //             crossAxisCount: 3,
  //             crossAxisSpacing: 8,
  //             mainAxisSpacing: 8,
  //           ),
  //           itemCount: _menuImages.length,
  //           itemBuilder: (context, index) {
  //             return Stack(
  //               children: [
  //                 Container(
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(8),
  //                     image: DecorationImage(
  //                       image: NetworkImage(_menuImages[index]),
  //                       fit: BoxFit.cover,
  //                     ),
  //                   ),
  //                 ),
  //                 Positioned(
  //                   top: 4,
  //                   right: 4,
  //                   child: GestureDetector(
  //                     onTap: () {
  //                       setState(() {
  //                         _menuImages.removeAt(index);
  //                       });
  //                     },
  //                     child: Container(
  //                       padding: const EdgeInsets.all(4),
  //                       decoration: const BoxDecoration(
  //                         color: Colors.red,
  //                         shape: BoxShape.circle,
  //                       ),
  //                       child: const Icon(
  //                         Icons.close,
  //                         size: 12,
  //                         color: Colors.white,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //         const SizedBox(height: 8),
  //       ],

  //       // Add Menu Images Button
  //       Container(
  //         height: 80,
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.grey, style: BorderStyle.solid),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: InkWell(
  //           onTap: _isUploadingMenuImage ? null : _addMenuImage,
  //           child: _isUploadingMenuImage
  //               ? const Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     CircularProgressIndicator(),
  //                     SizedBox(height: 4),
  //                     Text(
  //                       'Mengupload...',
  //                       style: TextStyle(color: Colors.grey),
  //                     ),
  //                   ],
  //                 )
  //               : const Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Icon(Icons.add_photo_alternate, color: Colors.grey),
  //                     SizedBox(height: 4),
  //                     Text(
  //                       'Tambah Foto Menu',
  //                       style: TextStyle(color: Colors.grey),
  //                     ),
  //                   ],
  //                 ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Update Profil', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _addMoreImages() async {
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
      // Pick image from selected source
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress untuk hemat bandwidth
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload to Cloudinary
      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'restaurants/${_restaurant.id}',
      );

      if (uploadedUrl != null) {
        setState(() {
          _newImages.add(uploadedUrl);
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar berhasil diupload ke Cloudinary'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal upload gambar ke Cloudinary'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addMenuImage() async {
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
      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingMenuImage = true;
      });

      // Upload to Cloudinary in menu folder
      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'restaurants/${_restaurant.id}/menu',
      );

      if (uploadedUrl != null) {
        setState(() {
          _menuImages.add(uploadedUrl);
          _isUploadingMenuImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto menu berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isUploadingMenuImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal upload foto menu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingMenuImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      final restaurantProvider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      // Build updated Restaurant instance (Restaurant is immutable)
      final updatedRestaurant = Restaurant(
        id: _restaurant.id,
        name: _restaurant.name,
        address: _restaurant.address,
        category: _restaurant.category,
        rating: _restaurant.rating,
        totalReviews: _restaurant.totalReviews,
        distance: _restaurant.distance,
        estimatedTime: _restaurant.estimatedTime,
        discount: _restaurant.discount,
        imageUrl: _restaurant.imageUrl,
        phone: _phoneController.text,
        openTime: _openTimeController.text,
        closeTime: _closeTimeController.text,
        description: _descriptionController.text,
        status: _restaurant.status,
        images: _newImages, // Use updated images
        ownerId: _restaurant.ownerId,
        categories: _restaurant.categories,
        priceRange: _restaurant.priceRange,
        openingHours: _restaurant.openingHours,
        location: _restaurant.location,
        license: _restaurant.license,
        createdAt: _restaurant.createdAt,
        updatedAt: DateTime.now(),
      );

      // Call provider to update the restaurant
      await restaurantProvider.updateRestaurant(updatedRestaurant);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil restoran berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return AppColors.primaryOrange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}
