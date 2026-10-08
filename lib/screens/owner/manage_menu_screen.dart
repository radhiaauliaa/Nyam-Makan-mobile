// screens/owner/manage_menu_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/theme.dart';
import '../../models/menu_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import '../../models/restaurant_model.dart';
import 'owner_home_screen.dart';
import 'manage_reservation_screen.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  @override
  void initState() {
    super.initState();

    // Load menu data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenuData();
    });
  }

  void _loadMenuData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    if (authProvider.user != null) {
      // Load restaurant data first
      restaurantProvider.loadCurrentRestaurant(authProvider.user!.id).then((_) {
        // Then load menu using restaurant ID
        if (restaurantProvider.currentRestaurant != null) {
          menuProvider.loadRestaurantMenu(
            restaurantProvider.currentRestaurant!.id,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);

    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, _) {
        final restaurant = restaurantProvider.currentRestaurant;

        return Scaffold(
          backgroundColor: const Color(0xFFEEEEEE),
          body: Column(
            children: [
              // Header dengan background orange curved
              _buildHeader(context, restaurant),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Info
                      _buildRestaurantInfo(authProvider),

                      const SizedBox(height: 16),

                      // Menu Stats
                      _buildMenuStats(menuProvider),

                      const SizedBox(height: 12),

                      // Loading and Error States
                      if (menuProvider.isLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (menuProvider.error != null)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Gagal memuat menu',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadMenuData,
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        // Menu List
                        Expanded(child: _buildMenuList(menuProvider)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showAddMenuDialog();
            },
            backgroundColor: AppColors.primaryOrange,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          bottomNavigationBar: OwnerBottomNavBar(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerHomeScreen(),
                  ),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageReservationScreen(),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildRestaurantInfo(AuthProvider authProvider) {
    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, _) {
        final restaurant = restaurantProvider.currentRestaurant;
        final restaurantName = restaurant?.name ?? 'Nama Restoran';
        final restaurantAddress = restaurant?.address ?? 'Alamat restoran';
        final restaurantCategory = restaurant?.categories.isNotEmpty == true
            ? restaurant!.categories.join(', ')
            : 'Kategori restoran';
        final restaurantRating = restaurant?.rating.toString() ?? '4.9';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: restaurant?.images.isNotEmpty == true
                      ? DecorationImage(
                          image: NetworkImage(restaurant!.images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: restaurant?.images.isEmpty != false
                    ? const Icon(Icons.restaurant, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurantAddress,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$restaurantCategory • $restaurantRating ⭐',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuStats(MenuProvider menuProvider) {
    final totalMenu = menuProvider.menuItems.length;
    final categories = menuProvider.menuItems
        .map((menu) => menu.category)
        .toSet();
    final promoCount = menuProvider.menuItems
        .where((menu) => menu.hasDiscount)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Jumlah Menu',
            totalMenu.toString(),
            Icons.restaurant_menu,
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            'Kategori',
            categories.length.toString(),
            Icons.category,
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            'Promo Aktif',
            promoCount.toString(),
            Icons.local_offer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryOrange),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuList(MenuProvider menuProvider) {
    if (menuProvider.menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Belum ada menu',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan menu pertama Anda',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: menuProvider.menuItems.length,
      itemBuilder: (context, index) {
        final menuItem = menuProvider.menuItems[index];
        return _buildMenuItemCard(menuItem);
      },
    );
  }

  Widget _buildMenuItemCard(Menu menuItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                image: menuItem.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(menuItem.images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: menuItem.images.isEmpty
                  ? const Icon(Icons.fastfood, color: Colors.grey, size: 40)
                  : null,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    menuItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.primaryOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${menuItem.rating.toStringAsFixed(1)} (${menuItem.reviewCount} ratings)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Row(
                    children: [
                      if (menuItem.hasDiscount) ...[
                        Text(
                          'Rp ${menuItem.originalPrice!.toInt()}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Rp ${menuItem.price.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                          fontSize: 16,
                        ),
                      ),
                      if (menuItem.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Promo',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Menu Button
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditMenuDialog(menuItem);
                } else if (value == 'delete') {
                  _showDeleteDialog(menuItem);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenuDialog() {
    final restaurantProvider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );

    if (restaurantProvider.currentRestaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data restoran belum dimuat')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddEditMenuDialog(
        onSave: (newItem) {
          final menuProvider = Provider.of<MenuProvider>(
            context,
            listen: false,
          );
          menuProvider.createMenuItem(newItem);
        },
        restaurantId: restaurantProvider.currentRestaurant!.id,
      ),
    );
  }

  void _showEditMenuDialog(Menu menuItem) {
    showDialog(
      context: context,
      builder: (context) => AddEditMenuDialog(
        menuItem: menuItem,
        onSave: (updatedItem) {
          final menuProvider = Provider.of<MenuProvider>(
            context,
            listen: false,
          );
          menuProvider.updateMenuItem(updatedItem);
        },
        restaurantId: menuItem.restaurantId,
      ),
    );
  }

  // Di manage_menu_screen.dart, method _showDeleteDialog:

  void _showDeleteDialog(Menu menuItem) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );

    final restaurantId = restaurantProvider.currentRestaurant?.id ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Apakah Anda yakin ingin menghapus "${menuItem.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Tutup dialog konfirmasi
              Navigator.pop(context);

              // Tampilkan loading sederhana (snackbar)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                      const SizedBox(width: 12),
                      const Text('Menghapus menu...'),
                    ],
                  ),
                  backgroundColor: AppColors.primaryOrange,
                  duration: const Duration(seconds: 5), // Max 5 detik
                ),
              );

              try {
                // Hapus menu
                final success = await menuProvider.deleteMenuItem(
                  menuItem.id,
                  restaurantId,
                );

                // Hapus snackbar loading
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Menu berhasil dihapus'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ ${menuProvider.error}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
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
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kelola Menu',
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
}

class AddEditMenuDialog extends StatefulWidget {
  final Menu? menuItem;
  final Function(Menu) onSave;
  final String restaurantId;

  const AddEditMenuDialog({
    super.key,
    this.menuItem,
    required this.onSave,
    required this.restaurantId,
  });

  @override
  State<AddEditMenuDialog> createState() => _AddEditMenuDialogState();
}

class _AddEditMenuDialogState extends State<AddEditMenuDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController =
      TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _hasPromo = false;
  List<String> _uploadedImages = []; // URL gambar dari Cloudinary
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.menuItem != null) {
      _nameController.text = widget.menuItem!.name;
      _descriptionController.text = widget.menuItem!.description;
      _priceController.text = widget.menuItem!.price.toInt().toString();
      _originalPriceController.text =
          widget.menuItem!.originalPrice?.toInt().toString() ?? '';
      _categoryController.text = widget.menuItem!.category;
      _hasPromo = widget.menuItem!.hasDiscount;
      _uploadedImages = widget.menuItem!.images; // Load existing image
    }
  }

  Future<void> _pickAndUploadImage() async {
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
      setState(() {
        _isUploading = true;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'menus',
      );

      if (uploadedUrl != null) {
        setState(() {
          _uploadedImages.add(uploadedUrl);
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar berhasil diupload'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal upload gambar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.menuItem != null ? 'Edit Menu' : 'Tambah Menu Baru',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Nama Menu', 'Isikan nama'),
              _buildTextField(
                _descriptionController,
                'Deskripsi Singkat',
                'Isikan deskripsi resto',
              ),
              _buildTextField(
                _priceController,
                'Harga Menu',
                'Isikan harga menu',
                TextInputType.number,
              ),
              _buildTextField(
                _categoryController,
                'Kategori',
                'Contoh: Ramen, Minuman',
              ),

              // Promo Toggle
              Row(
                children: [
                  Checkbox(
                    value: _hasPromo,
                    onChanged: (value) {
                      setState(() {
                        _hasPromo = value!;
                      });
                    },
                  ),
                  const Text('Ada Promo'),
                ],
              ),

              if (_hasPromo)
                _buildTextField(
                  _originalPriceController,
                  'Harga Asli',
                  'Isikan harga sebelum promo',
                  TextInputType.number,
                ),

              const SizedBox(height: 16),

              // Foto Menu
              const Text('Foto Menu', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              if (_uploadedImages.isNotEmpty) ...[
                // Grid untuk multiple images
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _uploadedImages.length,
                  itemBuilder: (context, index) {
                    return _buildImagePreview(index);
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (_isUploading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                const Text('Mengupload gambar...', textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _pickAndUploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF873300),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Upload Gambar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              if (_uploadedImages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '✅ ${_uploadedImages.length} gambar terupload',
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _uploadedImages.clear();
                        });
                      },
                      child: const Text(
                        'Hapus Semua',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
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
                      onPressed: _saveMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Simpan'),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, [
    TextInputType? keyboardType,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
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

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _uploadedImages[index],
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
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _uploadedImages.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }


  // Di method _saveMenu di AddEditMenuDialog:

  void _saveMenu() {
    // Validasi input
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama menu harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_priceController.text.isEmpty ||
        double.tryParse(_priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga menu harus diisi dengan angka'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_uploadedImages.isEmpty) { // PERUBAHAN: validasi images
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon upload minimal 1 gambar menu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Create menu object
    final menuItem = Menu(
      id: widget.menuItem?.id ?? '', // Empty for new items
      restaurantId: widget.restaurantId,
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      originalPrice: _hasPromo && _originalPriceController.text.isNotEmpty
          ? (double.tryParse(_originalPriceController.text) ?? 0.0)
          : null,
      category: _categoryController.text,
      images: _uploadedImages,
      isPopular: widget.menuItem?.isPopular ?? false,
      rating: widget.menuItem?.rating ?? 0.0,
      reviewCount: widget.menuItem?.reviewCount ?? 0,
      isAvailable: widget.menuItem?.isAvailable ?? true,
      tags: widget.menuItem?.tags,
      createdAt: widget.menuItem?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save menu
    Future.delayed(Duration.zero, () async {
      try {
        final menuProvider = Provider.of<MenuProvider>(context, listen: false);

        bool success;
        if (widget.menuItem != null) {
          success = await menuProvider.updateMenuItem(menuItem);
        } else {
          success = await menuProvider.createMenuItem(menuItem);
        }

        if (mounted) {
          Navigator.pop(context); // Close loading

          if (success) {
            // Call onSave callback
            widget.onSave(menuItem);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.menuItem != null
                      ? 'Menu berhasil diperbarui'
                      : 'Menu berhasil ditambahkan',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Close dialog
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${menuProvider.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }
}
