// screens/user/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/restaurant_card.dart';
import 'favorite_screen.dart';
import 'list_screen.dart';
import 'home_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _locationInitialized = false;

  double _budgetValue = 0;
  String _selectedCategory = '';
  SearchMode _searchMode = SearchMode.initial;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Makanan cepat saji',
      'icon': Icons.fastfood,
      'value': 'Fast Food',
    },
    {'name': 'Pizza dan Pasta', 'icon': Icons.local_pizza, 'value': 'Pizza'},
    {'name': 'Ayam dan Bebek', 'icon': Icons.set_meal, 'value': 'Chicken'},
    {'name': 'Kue dan Roti', 'icon': Icons.cake, 'value': 'Bakery'},
    {'name': 'Makan siang', 'icon': Icons.lunch_dining, 'value': 'Lunch'},
    {
      'name': 'Minuman dan Ice Cream',
      'icon': Icons.icecream,
      'value': 'Drinks',
    },
    {'name': 'Ramen dan Bakmi', 'icon': Icons.ramen_dining, 'value': 'Ramen'},
    {'name': 'Seafood', 'icon': Icons.set_meal, 'value': 'Seafood'},
    {'name': 'Nasi Padang', 'icon': Icons.rice_bowl, 'value': 'Padang'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().loadRestaurants();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locationInitialized) {
      _locationInitialized = true;
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      locationProvider.initializeLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final provider = context.read<RestaurantProvider>();
    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      setState(() {
        _searchMode = SearchMode.manual;
      });
      provider.searchRestaurants(query);
    }
  }

  void _applyBudgetFilter() {
    setState(() {
      _searchMode = SearchMode.budget;
    });
    _applyCurrentFilters();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _searchMode = SearchMode.category;
    });
    _applyCurrentFilters();
  }

  void _applyCurrentFilters() {
    final provider = context.read<RestaurantProvider>();
    provider.applyCombinedFilters(
      searchQuery: _searchController.text.trim(),
      category: _selectedCategory,
      maxPrice: _budgetValue > 0 ? _budgetValue : 200000,
    );
  }

  void _clearFilters() {
    final provider = context.read<RestaurantProvider>();
    setState(() {
      _searchController.clear();
      _budgetValue = 0;
      _selectedCategory = '';
      _searchMode = SearchMode.initial;
    });
    provider.clearFilters();
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/nyam_makaan.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cari Restoran',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Nyam! Makaan',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Tombol kembali
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _handleBackButton,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar dalam header
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari restoran atau makanan...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: AppColors.primaryOrange),
                suffixIcon: _searchMode != SearchMode.initial
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearFilters,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onSubmitted: (value) => _performSearch(),
            ),
          ),
        ],
      ),
    );
  }

  String _getBudgetTitle() {
    if (_budgetValue == 0) return 'Semua harga';
    if (_budgetValue <= 10000) return 'Yang harga-nya 10.000 nih!';
    if (_budgetValue <= 20000) return 'Yang harga-nya 20.000 nih!';
    if (_budgetValue <= 30000) return 'Yang harga-nya 30.000 nih!';
    if (_budgetValue <= 40000) return 'Yang harga-nya 40.000 nih!';
    if (_budgetValue <= 50000) return 'Yang harga-nya 50.000 nih!';
    if (_budgetValue <= 60000) return 'Yang harga-nya 60.000 nih!';
    if (_budgetValue <= 70000) return 'Yang harga-nya 70.000 nih!';
    if (_budgetValue <= 80000) return 'Yang harga-nya 80.000 nih!';
    if (_budgetValue <= 90000) return 'Yang harga-nya 90.000 nih!';
    if (_budgetValue <= 100000) return 'Yang harga-nya 100.000 nih!';
    if (_budgetValue <= 125000) return 'Yang harga-nya 125.000 nih!';
    if (_budgetValue <= 150000) return 'Yang harga-nya 150.000 nih!';
    if (_budgetValue <= 175000) return 'Yang harga-nya 175.000 nih!';
    return 'Yang harga-nya 200.000 nih!';
  }

  void _handleBackButton() {
    if (_searchMode != SearchMode.initial) {
      // Jika sedang di hasil pencarian, kembali ke tampilan awal
      _clearFilters();
    } else {
      // Jika sudah di tampilan awal, kembali ke home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            // Konten utama berdasarkan mode pencarian
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  Widget _buildContent() {
    switch (_searchMode) {
      case SearchMode.initial:
        return _buildInitialView();
      case SearchMode.manual:
        return _buildManualSearchResults();
      case SearchMode.budget:
        return _buildBudgetSearchView();
      case SearchMode.category:
        return _buildCategorySearchView();
    }
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Section - SIMPLE seperti awal
          _buildBudgetSection(),
          const SizedBox(height: 32),
          // Categories Section
          _buildCategoriesSection(),
        ],
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mau makan sesuai budget?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Slider(
                value: _budgetValue,
                min: 0,
                max: 200000,
                divisions: 20, // 200.000 / 10.000 = 20 divisions
                label: _budgetValue == 0
                    ? 'Semua harga'
                    : 'Rp ${(_budgetValue / 1000).toStringAsFixed(0)}rb',
                onChanged: (value) {
                  setState(() {
                    _budgetValue = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rp 0',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Rp 200rb',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyBudgetFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('OKE'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];

            return GestureDetector(
              onTap: () => _onCategorySelected(category['value'] as String),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 28,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category['name'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildManualSearchResults() {
    return Consumer2<RestaurantProvider, LocationProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final restaurants = locationProvider.updateRestaurantsDistanceAndTime(
          provider.filteredRestaurants,
        );

        return Column(
          children: [
            // Header untuk search manual
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kamu nyari ini ya?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (restaurants.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${restaurants.length} hasil ditemukan',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: restaurants.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = restaurants[index];
                        return RestaurantCard(restaurant: restaurant);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetSearchView() {
    return Consumer2<RestaurantProvider, LocationProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final restaurants = locationProvider.updateRestaurantsDistanceAndTime(
          provider.filteredRestaurants,
        );

        return Column(
          children: [
            // Header untuk budget search
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.lightOrange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getBudgetTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (restaurants.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${restaurants.length} restoran sesuai budget Anda',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: restaurants.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = restaurants[index];
                        return RestaurantCard(restaurant: restaurant);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySearchView() {
    return Consumer2<RestaurantProvider, LocationProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final restaurants = locationProvider.updateRestaurantsDistanceAndTime(
          provider.filteredRestaurants,
        );
        final categoryName = _categories.firstWhere(
          (cat) => cat['value'] == _selectedCategory,
          orElse: () => {'name': _selectedCategory},
        )['name'];

        return Column(
          children: [
            // Header untuk category search
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$categoryName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (restaurants.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${restaurants.length} restoran dalam kategori $categoryName',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: restaurants.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = restaurants[index];
                        return RestaurantCard(restaurant: restaurant);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada restoran yang ditemukan',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci atau filter pencarian',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FavoriteScreen()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ListScreen()),
            );
            break;
        }
      },
      items: [
        BottomNavItem(icon: Icons.home, label: 'Home'),
        BottomNavItem(icon: Icons.favorite, label: 'Favorite'),
        BottomNavItem(icon: Icons.list, label: 'Reservasi'),
      ],
    );
  }
}

enum SearchMode {
  initial, // Tampilan awal dengan budget slider dan kategori
  manual, // Hasil pencarian manual (ketik)
  budget, // Hasil pencarian budget
  category, // Hasil pencarian kategori
}
