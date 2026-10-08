import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/menu_item_card.dart';
import '../../services/notification_service.dart';
import '../../services/report_service.dart';
import '../../utils/theme.dart';

class ReviewScreen extends StatefulWidget {
  final Restaurant restaurant;
  final Review? existingReview;

  const ReviewScreen({
    super.key,
    required this.restaurant,
    this.existingReview,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 5.0;
  String _diningOption = 'Dine In';
  List<String> _selectedMenus = []; // Changed to List<String>
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _reviewController.text = widget.existingReview!.comment;
      _rating = widget.existingReview!.rating.toDouble();
      _diningOption = widget.existingReview!.diningOption;
      // Convert existing selectedMenus to List<String>
      _selectedMenus = widget.existingReview!.selectedMenus
          .map((menu) => menu['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.existingReview != null ? 'Edit Ulasan' : 'Tambahkan Ulasan',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (widget.existingReview != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteReview,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRestaurantInfo(),
            const SizedBox(height: 24),
            _buildUserInfo(currentUser?.username ?? 'Pengguna'),
            const SizedBox(height: 24),
            _buildReviewTextField(),
            const SizedBox(height: 24),
            _buildMenuSelection(),
            const SizedBox(height: 24),
            _buildDiningOption(),
            const SizedBox(height: 24),
            _buildRatingSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String userName) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.lightOrange,
          child: const Icon(Icons.person, color: AppColors.primaryOrange),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Local Guide • 181 Ulasan',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRestaurantInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
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
              image: widget.restaurant.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.restaurant.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.restaurant.imageUrl == null
                ? const Icon(Icons.restaurant, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.restaurant.address,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.primaryOrange,
                      size: 16,
                    ),
                    Text('${widget.restaurant.rating}'),
                    Text(
                      ' (${widget.restaurant.totalReviews} ratings)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tuliskan pengalaman anda',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
              hintText: 'Bagikan pengalaman makan Anda di restoran ini...',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilihan Menu (opsional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Tampilkan menu yang sudah dipilih
        if (_selectedMenus.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedMenus.map((menu) {
              return Chip(
                label: Text(menu),
                backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
                onDeleted: () {
                  setState(() {
                    _selectedMenus.remove(menu);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        ElevatedButton(
          onPressed: _showMenuSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            side: BorderSide(color: Colors.grey[300]!),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_selectedMenus.isEmpty ? Icons.add : Icons.edit, size: 20),
              const SizedBox(width: 8),
              Text(_selectedMenus.isEmpty ? 'Pilih Menu' : 'Edit Menu Dipilih'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiningOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilihan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDiningOptionButton('Dine In', Icons.restaurant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDiningOptionButton(
                'Take Away',
                Icons.takeout_dining,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiningOptionButton(String option, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => _diningOption = option),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _diningOption == option
              ? AppColors.lightOrange
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _diningOption == option
                ? AppColors.primaryOrange
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: _diningOption == option
                  ? AppColors.primaryOrange
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              option,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _diningOption == option
                    ? AppColors.primaryOrange
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Center(
          child: RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 40,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: AppColors.primaryOrange),
            onRatingUpdate: (rating) => setState(() => _rating = rating),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${_rating.toInt()} / 5',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(currentUser) {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : () => _submitReview(currentUser),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          : Text(
              widget.existingReview != null ? 'Update Ulasan' : 'Submit Ulasan',
            ),
    );
  }

  Future<void> _submitReview(currentUser) async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tulis ulasan terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Convert List<String> to List<Map<String, dynamic>> for the model
      final selectedMenusForModel = _selectedMenus.map((menuName) {
        return {'name': menuName};
      }).toList();

      final review = Review(
        id:
            widget.existingReview?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser?.id ?? 'guest',
        userName: currentUser?.username ?? 'Pengguna',
        userBadge: 'Local Guide',
        userReviewCount: 1,
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        rating: _rating.toDouble(), // Convert to double for Firebase
        comment: _reviewController.text.trim(),
        diningOption: _diningOption,
        selectedMenus: selectedMenusForModel,
        createdAt: DateTime.now(),
      );

      // Debug print
      print('Data yang akan disimpan: ${review.toMap()}');

      // ✅ Simpan ke Firestore
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(review.id)
          .set(review.toMap());

      // SEND NOTIFICATION to restaurant owner - Get ownerId from restaurant doc
      final notificationService = NotificationService();
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurant.id)
          .get();
      final restaurantData = restaurantDoc.data();
      final ownerId = restaurantData?['ownerId'] ?? '';

      if (ownerId.isNotEmpty) {
        await notificationService.notifyNewReview(
          ownerId,
          review.userName,
          widget.restaurant.id,
          review.rating,
        );
        print('✅ Notification sent to owner: $ownerId for new review');
      } else {
        print('⚠️ OwnerId not found for restaurant: ${widget.restaurant.id}');
      }

      // CHECK for spam rating (10x rating <2 to same restaurant)
      if (review.rating < 2.0) {
        final reportService = ReportService();
        await reportService.checkUserSpamRating(
          review.userId,
          widget.restaurant.id,
        );
      }

      // CHECK restaurant poor rating
      final reportService = ReportService();
      await reportService.checkRestaurantPoorRating(widget.restaurant.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ulasan berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, review);
    } catch (e) {
      print('Error saat menyimpan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan ulasan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showMenuSelection() async {
    // Filter menu berdasarkan restaurantId
    final menuSnapshot = await FirebaseFirestore.instance
        .collection('menus')
        .where('restaurantId', isEqualTo: widget.restaurant.id)
        .get();

    final menus = menuSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'price': (data['price'] ?? 0).toDouble(),
        'description': data['description'] ?? '',
        'category': data['category'] ?? '',
        'image': data['image'] ?? '',
      };
    }).toList();

    // List sementara untuk menu yang dipilih
    List<String> selected = List.from(_selectedMenus);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Menu yang Kamu Coba",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Tampilkan menu yang sudah dipilih
                  if (selected.isNotEmpty) ...[
                    const Text(
                      "Menu yang dipilih:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selected.map((menuName) {
                        return Chip(
                          label: Text(menuName),
                          backgroundColor: AppColors.primaryOrange.withOpacity(
                            0.1,
                          ),
                          onDeleted: () {
                            setModalState(() {
                              selected.remove(menuName);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Daftar semua menu
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: menus.length,
                      itemBuilder: (context, index) {
                        final menu = menus[index];
                        final isSelected = selected.contains(menu['name']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image:
                                    menu['image'] != null &&
                                        menu['image'].toString().isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          menu['image'].toString(),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child:
                                  menu['image'] == null ||
                                      menu['image'].toString().isEmpty
                                  ? const Icon(
                                      Icons.fastfood,
                                      color: Colors.grey,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            title: Text(
                              menu['name'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              menu['description']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : Colors.grey,
                            ),
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selected.remove(menu['name']);
                                } else {
                                  selected.add(menu['name']);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              selected.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                          ),
                          child: const Text("Hapus Semua"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedMenus = selected;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Selesai"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteReview() {
    // Implement delete functionality here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ulasan'),
        content: const Text('Apakah Anda yakin ingin menghapus ulasan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('reviews')
                    .doc(widget.existingReview!.id)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ulasan berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close review screen
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus ulasan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
