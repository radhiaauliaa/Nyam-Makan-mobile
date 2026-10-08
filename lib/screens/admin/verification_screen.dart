// screens/admin/verification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/user_service.dart';
import '../../services/email_service.dart';
import '../../models/user_model.dart';
import '../../models/restaurant_model.dart';
import '../../utils/theme.dart';

class VerificationScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const VerificationScreen({super.key, required this.restaurant});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isVerifying = false;
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Debug: Print restaurant data saat screen dibuka
    print('========== RESTAURANT DATA DEBUG ==========');
    print('Restaurant ID: ${widget.restaurant['id']}');
    print('Restaurant Name: ${widget.restaurant['name']}');
    print('Owner ID: ${widget.restaurant['ownerId']}');
    print('Owner Email: ${widget.restaurant['ownerEmail']}');
    print('Owner Name: ${widget.restaurant['owner']}');
    print('All Keys: ${widget.restaurant.keys.toList()}');
    print('============================================');
  }

  // Method untuk fix semua resto yang ownerEmail-nya null
  Future<void> _fixAllRestaurantsOwnerData() async {
    try {
      print('Starting to fix all restaurants owner data...');

      final userService = UserService();
      final firestore = FirebaseFirestore.instance;

      // Get all restaurants directly from Firestore
      final snapshot = await firestore.collection('restaurants').get();

      int fixedCount = 0;
      int errorCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final restaurantId = doc.id;
        final restaurantName = data['name'] ?? 'Unknown';
        final ownerEmail = data['ownerEmail'];
        final ownerId = data['ownerId'];

        // Skip jika ownerEmail sudah ada
        if (ownerEmail != null && ownerEmail.toString().isNotEmpty) {
          print('$restaurantName - sudah ada ownerEmail');
          continue;
        }

        // Skip jika ownerId kosong
        if (ownerId == null || ownerId.toString().isEmpty) {
          print('$restaurantName - ownerId kosong, skip');
          errorCount++;
          continue;
        }

        try {
          // Fetch owner data
          final owner = await userService.getUserById(ownerId.toString());

          if (owner != null) {
            // Update restaurant dengan owner data via Firestore
            await firestore.collection('restaurants').doc(restaurantId).update({
              'ownerEmail': owner.email,
              'owner': owner.username,
            });

            print('Fixed: $restaurantName - added ${owner.email}');
            fixedCount++;
          } else {
            print('$restaurantName - owner not found');
            errorCount++;
          }
        } catch (e) {
          print('Error fixing $restaurantName: $e');
          errorCount++;
        }
      }

      print('Done! Fixed: $fixedCount, Errors: $errorCount');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil fix $fixedCount resto, $errorCount error'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in _fixAllRestaurantsOwnerData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper method to convert Restaurant model to Map
  Map<String, dynamic> _convertRestaurantToMap(Restaurant restaurant) {
    return {
      'id': restaurant.id,
      'name': restaurant.name,
      'category': restaurant.categories.isNotEmpty
          ? restaurant.categories.first
          : '',
      'ownerId': restaurant.ownerId,
      'ownerEmail': restaurant.ownerEmail,
      'owner': restaurant.owner ?? restaurant.ownerId ?? 'Tidak diketahui',
      'phone': restaurant.phone,
      'address': restaurant.address,
      'openTime': restaurant.openTime,
      'closeTime': restaurant.closeTime,
      'description': restaurant.description,
      'images': restaurant.images,
      'licenseUrl': restaurant.license,
      'submissionDate': _formatDate(restaurant.createdAt ?? DateTime.now()),
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Refresh data method for pull-to-refresh
  Future<void> _refreshData() async {
    try {
      print('Refreshing verification data...');
      final provider = Provider.of<RestaurantProvider>(context, listen: false);

      // Reload pending restaurants
      await provider.loadPendingRestaurants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil diperbarui'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }

      print('Verification data refreshed successfully');
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return ScaffoldMessenger(
    key: _scaffoldKey, // TAMBAHKAN INI
    child: Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Verifikasi Resto Baru'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.build),
            tooltip: 'Fix Owner Data',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Fix Owner Data'),
                  content: const Text(
                    'Update semua resto yang ownerEmail-nya null dengan data dari users collection?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ya, Fix'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _fixAllRestaurantsOwnerData();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.phone), onPressed: _contactOwner),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRestaurantHeader(),
              const SizedBox(height: 24),
              _buildVerificationChecklist(),
              const SizedBox(height: 24),
              _buildRestaurantDetails(),
              const SizedBox(height: 24),
              _buildDocumentsSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
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
              image:
                  widget.restaurant['images'] != null &&
                      widget.restaurant['images'].isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.restaurant['images'][0]),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child:
                widget.restaurant['images'] == null ||
                    widget.restaurant['images'].isEmpty
                ? const Icon(Icons.restaurant, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurant['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.restaurant['category'],
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                _buildOwnerSubmittedText(),
                Text(
                  'Tanggal: ${widget.restaurant['submissionDate']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checklist Verifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          _buildChecklistItem('Data restoran lengkap dan valid', true),
          _buildChecklistItem('Surat izin usaha valid', true),
          _buildChecklistItem('Foto restoran memadai (min. 3)', true),
          _buildChecklistItem('Lokasi dapat diverifikasi', false),
          _buildChecklistItem('Nomor telepon aktif', true),
          _buildChecklistItem('Kategori usaha sesuai', true),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.error,
            color: isVerified ? Colors.green : AppColors.primaryOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isVerified ? Colors.green : AppColors.primaryOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Restoran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDetailItem('Nama Restoran', widget.restaurant['name']),
        _buildDetailItem('Kategori', widget.restaurant['category']),
        _buildOwnerDetailItem(),
        _buildDetailItem('Telepon', widget.restaurant['phone']),
        _buildDetailItem('Alamat', widget.restaurant['address']),
        _buildDetailItem(
          'Jam Operasional',
          '${widget.restaurant['openTime']} - ${widget.restaurant['closeTime']}',
        ),
        _buildDetailItem('Deskripsi', widget.restaurant['description']),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  bool _looksLikeId(String value) {
    // Heuristic: Firestore UID: length > 20, no '@'
    return value.length > 20 && !value.contains('@') && !value.contains(' ');
  }

  Widget _buildOwnerSubmittedText() {
    final ownerId = widget.restaurant['ownerId'];
    final rawOwner = widget.restaurant['owner']?.toString() ?? '';
    // Jika sudah berupa nama/email, tampilkan langsung
    if (ownerId == null && rawOwner.isNotEmpty && !_looksLikeId(rawOwner)) {
      return Text(
        'Diajukan oleh: $rawOwner',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
    final idToFetch = ownerId ?? rawOwner;
    return FutureBuilder<UserModel?>(
      future: UserService().getUserById(idToFetch),
      builder: (context, snapshot) {
        String display;
        if (snapshot.connectionState == ConnectionState.waiting) {
          display = 'Memuat...';
        } else if (snapshot.hasError || snapshot.data == null) {
          display = 'Tidak diketahui';
        } else {
          final user = snapshot.data!;
          display = user.username.isNotEmpty ? user.username : user.email;
        }
        return Text(
          'Diajukan oleh: $display',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildOwnerDetailItem() {
    final ownerId = widget.restaurant['ownerId'];
    final rawOwner = widget.restaurant['owner']?.toString() ?? '';
    if (ownerId == null && rawOwner.isNotEmpty && !_looksLikeId(rawOwner)) {
      return _buildDetailItem('Pemilik', rawOwner);
    }
    final idToFetch = ownerId ?? rawOwner;
    return FutureBuilder<UserModel?>(
      future: UserService().getUserById(idToFetch),
      builder: (context, snapshot) {
        String display;
        if (snapshot.connectionState == ConnectionState.waiting) {
          display = 'Memuat...';
        } else if (snapshot.hasError || snapshot.data == null) {
          display = 'Tidak diketahui';
        } else {
          final user = snapshot.data!;
          display = user.username.isNotEmpty ? user.username : user.email;
        }
        return _buildDetailItem('Pemilik', display);
      },
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dokumen & Foto',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Business License
        _buildDocumentItem(
          'Surat Izin Usaha',
          widget.restaurant['licenseUrl'],
          Icons.description,
        ),

        const SizedBox(height: 16),

        // Restaurant Photos
        _buildPhotosSection(),
      ],
    );
  }

  Widget _buildDocumentItem(String title, String? url, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: url != null ? () => _viewDocument(url, title) : null,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(icon, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    url != null ? 'Lihat $title' : '$title tidak tersedia',
                    style: TextStyle(
                      color: url != null ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
                if (url != null)
                  const Icon(Icons.visibility, color: Colors.blue),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    final images = widget.restaurant['images'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Restoran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          const Text(
            'Tidak ada foto yang diupload',
            style: TextStyle(color: Colors.grey),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _viewImage(images[index]),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(images[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isVerifying ? null : _rejectRestaurant,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _verifyRestaurant,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Verifikasi'),
          ),
        ),
      ],
    );
  }

  void _viewDocument(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Image.network(url),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _viewImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Image.network(url),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contactOwner() {
    // Implement phone call to owner
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menghubungi ${widget.restaurant['owner']}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _verifyRestaurant() async {
  if (_isVerifying) return; // Prevent double tap
  
  setState(() => _isVerifying = true);
  
  final provider = Provider.of<RestaurantProvider>(context, listen: false);
  final String id = widget.restaurant['id']?.toString() ?? '';

  try {
    final success = await provider.updateRestaurantStatus(id, 'verified');
    
    if (!mounted) return;

    if (success) {
      final ownerId = widget.restaurant['ownerId']?.toString() ?? '';
      final restaurantName = widget.restaurant['name']?.toString() ?? '';

      print('Restaurant approved');

      if (ownerId.isNotEmpty) {
        try {
          final userService = UserService();
          final ownerData = await userService.getUserById(ownerId);

          if (ownerData != null) {
            final ownerEmail = ownerData.email;
            final ownerName = ownerData.username;
            final ownerPhone = ownerData.phone ?? '';

            print('Sending email...');
            await EmailService.sendRestaurantApprovedEmail(
              ownerEmail: ownerEmail,
              ownerName: ownerName,
              restaurantName: restaurantName,
            );

            // Stop loading
            if (mounted) {
              setState(() => _isVerifying = false);
            }

            // Show WhatsApp dialog ONLY if mounted
            if (ownerPhone.isNotEmpty && mounted) {
              print('Showing WhatsApp dialog for: $ownerPhone');
              
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => WillPopScope(
                  onWillPop: () async => false,
                  child: _buildWhatsAppDialog(
                    context: dialogContext,
                    phone: ownerPhone,
                    ownerName: ownerName,
                    restaurantName: restaurantName,
                    isApproved: true,
                  ),
                ),
              );
              
              print('WhatsApp dialog closed');
            }
          }
        } catch (e) {
          print('Error: $e');
          if (mounted) setState(() => _isVerifying = false);
        }
      } else {
        if (mounted) setState(() => _isVerifying = false);
      }

      // Navigate SETELAH dialog
      if (!mounted) return;
      
      await provider.loadPendingRestaurants();
      
      if (!mounted) return;

      if (provider.pendingRestaurants.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              restaurant: _convertRestaurantToMap(
                provider.pendingRestaurants.first,
              ),
            ),
          ),
        );
      } else {
        _scaffoldKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Semua restoran telah diverifikasi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        setState(() => _isVerifying = false);
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Gagal: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print('Error: $e');
    if (mounted) {
      setState(() => _isVerifying = false);
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// REPLACE method _rejectRestaurant dengan ini:

void _rejectRestaurant() {
  TextEditingController reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tolak Restoran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Alasan penolakan:'),
          const SizedBox(height: 8),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Jelaskan alasan penolakan...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => _handleRejection(reasonController.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Tolak'),
        ),
      ],
    ),
  );
}

void _handleRejection(String reason) async {
  if (reason.isEmpty) {
    _scaffoldKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Harap isi alasan penolakan'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  Navigator.pop(context); // Close dialog
  
  if (_isVerifying) return; // Prevent double tap

  setState(() => _isVerifying = true);

  final provider = Provider.of<RestaurantProvider>(context, listen: false);
  final String id = widget.restaurant['id']?.toString() ?? '';

  try {
    final success = await provider.updateRestaurantStatus(
      id,
      'rejected',
      reason: reason,
    );

    if (!mounted) return;

    if (success) {
      final ownerId = widget.restaurant['ownerId']?.toString() ?? '';
      final restaurantName = widget.restaurant['name']?.toString() ?? '';

      print('Restaurant rejected');

      if (ownerId.isNotEmpty) {
        try {
          final userService = UserService();
          final ownerData = await userService.getUserById(ownerId);

          if (ownerData != null) {
            final ownerEmail = ownerData.email;
            final ownerName = ownerData.username;
            final ownerPhone = ownerData.phone ?? '';

            print('Suspending account...');
            await _suspendOwnerAccount(ownerId);

            print('Sending email...');
            await EmailService.sendRestaurantRejectedEmail(
              ownerEmail: ownerEmail,
              ownerName: ownerName,
              restaurantName: restaurantName,
              rejectionReason: reason,
            );

            // Stop loading
            if (mounted) {
              setState(() => _isVerifying = false);
            }

            // Show WhatsApp dialog ONLY if mounted
            if (ownerPhone.isNotEmpty && mounted) {
              print('Showing WhatsApp dialog for: $ownerPhone');
              
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => WillPopScope(
                  onWillPop: () async => false,
                  child: _buildWhatsAppDialog(
                    context: dialogContext,
                    phone: ownerPhone,
                    ownerName: ownerName,
                    restaurantName: restaurantName,
                    isApproved: false,
                    rejectionReason: reason,
                  ),
                ),
              );
              
              print('WhatsApp dialog closed');
            }
          }
        } catch (e) {
          print('Error: $e');
          if (mounted) setState(() => _isVerifying = false);
        }
      } else {
        if (mounted) setState(() => _isVerifying = false);
      }

      // Navigate SETELAH dialog
      if (!mounted) return;
      
      await provider.loadPendingRestaurants();
      
      if (!mounted) return;

      if (provider.pendingRestaurants.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              restaurant: _convertRestaurantToMap(
                provider.pendingRestaurants.first,
              ),
            ),
          ),
        );
      } else {
        _scaffoldKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Semua restoran telah diproses'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, false);
      }
    } else {
      if (mounted) {
        setState(() => _isVerifying = false);
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Gagal: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print('Error: $e');
    if (mounted) {
      setState(() => _isVerifying = false);
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// TAMBAHKAN method baru untuk build WhatsApp dialog:

Widget _buildWhatsAppDialog({
  required BuildContext context,
  required String phone,
  required String ownerName,
  required String restaurantName,
  required bool isApproved,
  String? rejectionReason,
}) {
  final adminEmail = 'admin@nyammakan.com';

  String message;
  if (isApproved) {
    message = '''Selamat! Restoran Disetujui

Halo $ownerName,

Kabar baik! Restoran "$restaurantName" telah disetujui dan sekarang AKTIF di aplikasi Nyam! Makaan.

Status: AKTIF
Restoran Anda sudah dapat menerima reservasi!

Informasi Login:
- Email: Gunakan email yang Anda daftarkan
- Role: Pemilik Resto

Langkah Selanjutnya:
1. Login ke aplikasi Nyam! Makaan
2. Lengkapi menu restoran Anda
3. Kelola reservasi yang masuk

Selamat bergabung dengan Nyam! Makaan!

Kontak: $adminEmail''';
  } else {
    message = '''Pemberitahuan: Restoran Ditolak

Halo $ownerName,

Pengajuan restoran "$restaurantName" tidak dapat disetujui.

Status: DITOLAK

Alasan:
$rejectionReason

Yang bisa dilakukan:
- Perbaiki data sesuai alasan
- Pastikan dokumen lengkap
- Daftar kembali setelah perbaikan

Kontak: $adminEmail''';
  }

  String waNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (!waNumber.startsWith('+')) {
    if (waNumber.startsWith('0')) {
      waNumber = '+62${waNumber.substring(1)}';
    } else if (waNumber.startsWith('8')) {
      waNumber = '+62$waNumber';
    } else {
      waNumber = '+$waNumber';
    }
  }

  final encodedMessage = Uri.encodeComponent(message);
  final waUrl = 'https://wa.me/$waNumber?text=$encodedMessage';

  return AlertDialog(
    title: Row(
      children: [
        Icon(Icons.message, color: Colors.green[700], size: 28),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Kirim Notifikasi WhatsApp', style: TextStyle(fontSize: 18)),
        ),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kirim notifikasi ${isApproved ? "persetujuan" : "penolakan"} ke:'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ownerName)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(phone)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Klik tombol untuk membuka WhatsApp',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Lewati'),
      ),
      ElevatedButton.icon(
        onPressed: () async {
          try {
            final uri = Uri.parse(waUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
              _scaffoldKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text('Tidak bisa membuka WhatsApp'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            Navigator.pop(context);
            print('Error: $e');
          }
        },
        icon: const Icon(Icons.send),
        label: const Text('Kirim WhatsApp'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    ],
  );
}


  Future<void> _sendWhatsAppNotification({
    required String phone,
    required String ownerName,
    required String restaurantName,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    final adminEmail = 'admin@nyammakan.com';

    String message;
    if (isApproved) {
      message =
          '''Selamat! Restoran Disetujui
      
      Halo $ownerName,
      
      Kabar baik! Restoran "$restaurantName" telah disetujui dan sekarang AKTIF di aplikasi Nyam! Makaan.
      
      Status: AKTIF
      Restoran Anda sudah dapat menerima reservasi dari pelanggan!

      Informasi Login:
      - Email: Gunakan email yang Anda daftarkan
      - Role: Pemilik Resto

      Langkah Selanjutnya:
      1. Login ke aplikasi Nyam! Makaan
      2. Lengkapi menu restoran Anda
      3. Atur ketersediaan meja dan area
      4. Buat promo menarik untuk pelanggan
      5. Kelola reservasi yang masuk
      6. Berikan pelayanan terbaik!

      Selamat bergabung dengan Nyam! Makaan!

      Jika ada pertanyaan, hubungi kami di: $adminEmail

      ---
      Email ini dikirim otomatis oleh sistem Nyam! Makaan.
      Kontak Admin: $adminEmail''';
    } else {
      message =
          '''Pemberitahuan: Restoran Ditolak
      
      Halo $ownerName,

      Kami informasikan bahwa pengajuan restoran "$restaurantName" tidak dapat disetujui saat ini.

      Status: DITOLAK

      Alasan Penolakan:
      $rejectionReason

      Apa yang bisa dilakukan?
      - Perbaiki data sesuai alasan penolakan
      - Pastikan semua dokumen lengkap dan valid
      - Daftar kembali setelah perbaikan

      Butuh Bantuan?
      Jika Anda memiliki pertanyaan atau membutuhkan klarifikasi, silakan hubungi kami di: $adminEmail

      Terima kasih atas pengertiannya.

      ---
      Tim Nyam! Makaan
      Email ini dikirim otomatis oleh sistem.
      Kontak Admin: $adminEmail''';
    }

    // Format nomor telepon
    String waNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // Pastikan nomor diawali dengan '+'
    if (!waNumber.startsWith('+')) {
      // Jika tidak ada kode negara, tambahkan +62 (Indonesia)
      if (waNumber.startsWith('0')) {
        waNumber = '+62${waNumber.substring(1)}';
      } else if (waNumber.startsWith('8')) {
        waNumber = '+62$waNumber';
      } else {
        waNumber = '+$waNumber';
      }
    }

    // Encode message untuk URL
    final encodedMessage = Uri.encodeComponent(message);
    final waUrl = 'https://wa.me/$waNumber?text=$encodedMessage';

    if (!mounted) return;

    // Tampilkan dialog dengan tombol kirim WhatsApp
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.message, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Kirim Notifikasi WhatsApp',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kirim notifikasi ${isApproved ? "persetujuan" : "penolakan"} ke:',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ownerName)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(phone)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Klik tombol di bawah untuk membuka WhatsApp dan mengirim pesan notifikasi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lewati'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final uri = Uri.parse(waUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Membuka WhatsApp...'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  throw Exception('Could not launch WhatsApp');
                }
              } catch (e) {
                print('Error launching WhatsApp: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal membuka WhatsApp: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Kirim WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // TAMBAHKAN method untuk suspend owner account

  Future<void> _suspendOwnerAccount(String ownerId) async {
    try {
      print('Suspending owner account: $ownerId');

      await FirebaseFirestore.instance.collection('users').doc(ownerId).update({
        'status': 'suspended',
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendReason': 'Restoran ditolak - akun dinonaktifkan',
      });

      print('Owner account suspended successfully');
    } catch (e) {
      print('Error suspending owner account: $e');
    }
  }
}
