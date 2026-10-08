// screens/owner/select_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/menu_item_card.dart';
import '../../utils/theme.dart';

class SelectMenuScreen extends StatefulWidget {
  final List<String>? initiallySelectedMenuIds;
  final Function(List<String> selectedMenuIds)? onMenuSelected;

  const SelectMenuScreen({
    super.key,
    this.initiallySelectedMenuIds,
    this.onMenuSelected,
  });

  @override
  State<SelectMenuScreen> createState() => _SelectMenuScreenState();
}

class _SelectMenuScreenState extends State<SelectMenuScreen> {
  final List<String> _selectedMenuIds = [];
  List<Menu> _allMenus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
    // Initialize with previously selected menus
    if (widget.initiallySelectedMenuIds != null) {
      _selectedMenuIds.addAll(widget.initiallySelectedMenuIds!);
    }
  }

  Future<void> _loadMenus() async {
    try {
      final restaurantProvider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );
      final restaurant = restaurantProvider.currentRestaurant;

      if (restaurant != null) {
        // Load menus for current restaurant
        // You might need to implement this method in your RestaurantProvider
        final menus = await restaurantProvider.getMenusByRestaurantId(
          restaurant.id!,
        );
        setState(() {
          _allMenus = menus;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading menus: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleMenuSelection(String menuId) {
    setState(() {
      if (_selectedMenuIds.contains(menuId)) {
        _selectedMenuIds.remove(menuId);
      } else {
        _selectedMenuIds.add(menuId);
      }
    });
  }

  void _clearAllSelection() {
    setState(() {
      _selectedMenuIds.clear();
    });
  }

  void _finishSelection() {
    widget.onMenuSelected?.call(_selectedMenuIds);
    Navigator.pop(context, _selectedMenuIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pilihan Menu'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_selectedMenuIds.isNotEmpty)
            TextButton(
              onPressed: _clearAllSelection,
              child: const Text(
                'Hapus Semua',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Section
                _buildHeaderSection(),

                // Menu List
                Expanded(child: _buildMenuList()),

                // Bottom Action Bar
                if (_selectedMenuIds.isNotEmpty) _buildActionBar(),
              ],
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pilih Menu Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedMenuIds.isEmpty
                      ? 'Semua Menu'
                      : '${_selectedMenuIds.length} Menu Terpilih',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Pilih Menu yang Kamu Coba',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    if (_allMenus.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada menu tersedia',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allMenus.length,
      itemBuilder: (context, index) {
        final menu = _allMenus[index];
        final isSelected = _selectedMenuIds.contains(menu.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppColors.primaryOrange, width: 2)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: MenuItemCard(
            name: menu.name,
            description: menu.description,
            price: menu.price,
            originalPrice: menu.originalPrice,
            rating: menu.rating,
            reviewCount: menu.reviewCount.toString(),
            images: menu.images,
            imageUrl: menu.imageUrl,
            category: menu.category,
            isPopular: menu.isPopular,
            showQuantity: false, // Tidak perlu quantity selector di sini
            initialQuantity: 0,
            onTap: () => _toggleMenuSelection(menu.id),
          ),
        );
      },
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAllSelection,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hapus Semua',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _finishSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );
  }
}
