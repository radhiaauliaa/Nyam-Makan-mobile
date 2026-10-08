// screens/user/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/reservation_model.dart';
import '../../models/promo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/promo_provider.dart';
import '../../services/menu_service.dart';
// import '../../widgets/menu_item_card.dart';
import '../../utils/theme.dart';
// import '../../widgets/custom_textfield.dart';
import '../../widgets/PhoneNumberInput.dart';

class ReservationScreen extends StatefulWidget {
  final Restaurant restaurant;
  final Promo? selectedPromo;

  const ReservationScreen({
    super.key,
    required this.restaurant,
    this.selectedPromo,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _guestController = TextEditingController(
    text: '2',
  );
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Form values
  String _selectedArea = 'Indoor';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  // Menu selections
  final List<Map<String, dynamic>> _selectedMenus = [];
  final MenuService _menuService = MenuService();

  // Promo
  Promo? _selectedPromo;

  @override
  void initState() {
    super.initState();
    _selectedPromo = widget.selectedPromo;
  }

  double get _subtotal {
    double total = 0;
    for (var menu in _selectedMenus) {
      total += (menu['price'] as double) * (menu['quantity'] as int);
    }
    return total;
  }

  double get _discount {
    if (_selectedPromo == null) return 0;

    // Check if promo is valid for selected menus
    final menuIds = _selectedMenus.map((m) => m['id'] as String).toList();
    final promoProvider = Provider.of<PromoProvider>(context, listen: false);

    if (!promoProvider.isPromoValidForMenus(_selectedPromo!, menuIds)) {
      return 0;
    }

    return promoProvider.calculateDiscount(_selectedPromo!, _subtotal);
  }

  double get _totalAmount {
    return _subtotal - _discount;
  }

  double get _dpAmount => _totalAmount * 0.5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
    // Set text controllers hanya jika tanggal dan waktu sudah dipilih
    if (_selectedDate != null) {
      _dateController.text = _formatDate(_selectedDate!);
    }
    if (_selectedTime != null) {
      _timeController.text = _selectedTime!.format(context);
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _nameController.text = user.username ?? '';
      _phoneController.text = user.phone ?? '';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reservasi Tempat'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Info
                    _buildRestaurantInfo(),

                    const SizedBox(height: 24),

                    // Reservation Form
                    _buildReservationForm(),

                    const SizedBox(height: 24),

                    // Menu Selection
                    _buildMenuSelection(),

                    const SizedBox(height: 24),

                    // Selected Menus Summary
                    if (_selectedMenus.isNotEmpty) _buildSelectedMenus(),

                    const SizedBox(height: 24),

                    // Info: Pembayaran setelah approved
                    if (_selectedMenus.isNotEmpty) _buildPaymentInfoNote(),

                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
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
                    const SizedBox(width: 4),
                    Text('${widget.restaurant.rating}'),
                    Text(
                      ' (${widget.restaurant.totalReviews} reviews)',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  Widget _buildReservationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Reservasi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Name Field
        _buildTextField(
          controller: _nameController,
          label: 'Nama',
          hint: 'Isikan nama',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama harus diisi';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Phone Field
        const SizedBox(height: 8), // Tambahkan ini sebelum PhoneNumberInput
        const Text(
          'Nomor Telepon',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        PhoneNumberInput(
          onChanged: (value) {
            _phoneController.text = value;
          },
          initialPhoneNumber: _phoneController.text,
        ),

        const SizedBox(height: 16),

        // Guest Count
        _buildTextField(
          controller: _guestController,
          label: 'Jumlah Orang',
          hint: 'Isikan jumlah orang',
          icon: Icons.people,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Jumlah orang harus diisi';
            }
            if (int.tryParse(value) == null) {
              return 'Jumlah harus angka';
            }
            final count = int.parse(value);
            if (count < 1 || count > 20) {
              return 'Jumlah orang harus 1-20';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Date and Time
        Row(
          children: [
            Expanded(child: _buildDateField()),
            const SizedBox(width: 16),
            Expanded(child: _buildTimeField()),
          ],
        ),

        const SizedBox(height: 16),

        // Area Selection
        _buildAreaSelection(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryOrange, width: 2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(icon, color: AppColors.primaryOrange),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryOrange, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  hintText: 'Pilih tanggal',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryOrange,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal harus dipilih';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jam',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryOrange, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  hintText: 'Pilih jam',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(
                    Icons.access_time,
                    color: AppColors.primaryOrange,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jam harus dipilih';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilihan Area',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildAreaOption('Indoor', Icons.home)),
            const SizedBox(width: 12),
            Expanded(child: _buildAreaOption('Outdoor', Icons.nature)),
          ],
        ),
      ],
    );
  }

  Widget _buildAreaOption(String area, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedArea = area;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedArea == area
              ? AppColors.lightOrange
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedArea == area
                ? AppColors.primaryOrange
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: _selectedArea == area
                  ? AppColors.primaryOrange
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              area,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _selectedArea == area
                    ? AppColors.primaryOrange
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilihan Menu (opsional)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Tombol untuk membuka bottom sheet pilih menu
        ElevatedButton(
          onPressed: _showMenuSelectionSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.add), SizedBox(width: 8), Text('Pilih Menu')],
          ),
        ),
      ],
    );
  }

  void _showMenuSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        // Beri height maksimal 80% dari screen height
        height: MediaQuery.of(context).size.height * 0.8,
        child: _buildMenuSelectionContent(),
      ),
    );
  }

  Widget _buildMenuSelectionContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),

          // List menu - pakai Expanded biar scrollable
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadMenus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada menu untuk restoran ini'),
                  );
                }

                final menus = snapshot.data!;
                return ListView.builder(
                  itemCount: menus.length,
                  itemBuilder: (context, index) {
                    final menu = menus[index];
                    final currentQuantity = _getCurrentQuantity(menu['id']);

                    return _buildMenuCard(menu, currentQuantity);
                  },
                );
              },
            ),
          ),

          // Tombol selesai - tidak pakai SizedBox height besar
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Selesai'),
            ),
          ),
          const SizedBox(height: 8), // Sedikit spacing di bawah
        ],
      ),
    );
  }

  // Helper function untuk get current quantity
  int _getCurrentQuantity(String menuId) {
    final existingSelection = _selectedMenus.firstWhere(
      (m) => m['id'] == menuId,
      orElse: () => {},
    );
    return existingSelection['quantity'] ?? 0;
  }

  Widget _buildMenuCard(Map<String, dynamic> menu, int currentQuantity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Info menu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menu['description'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${menu['price'].toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Tombol +/- dengan StatefulBuilder agar langsung update
            StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol minus
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: currentQuantity > 0
                            ? () {
                                _decreaseMenuQuantity(menu);
                                // Update state lokal
                                setState(() {
                                  currentQuantity = _getCurrentQuantity(
                                    menu['id'],
                                  );
                                });
                              }
                            : null,
                        color: currentQuantity > 0
                            ? AppColors.primaryOrange
                            : Colors.grey,
                        padding: const EdgeInsets.all(4),
                      ),

                      // Quantity
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$currentQuantity',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: currentQuantity > 0
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),

                      // Tombol plus
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () {
                          _increaseMenuQuantity(menu);
                          // Update state lokal
                          setState(() {
                            currentQuantity = _getCurrentQuantity(menu['id']);
                          });
                        },
                        color: AppColors.primaryOrange,
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _increaseMenuQuantity(Map<String, dynamic> menu) {
    final existingIndex = _selectedMenus.indexWhere(
      (m) => m['id'] == menu['id'],
    );

    if (existingIndex >= 0) {
      _selectedMenus[existingIndex]['quantity']++;
    } else {
      _selectedMenus.add({...menu, 'quantity': 1});
    }
    // Pastikan setState dipanggil untuk update UI
    if (mounted) setState(() {});
  }

  void _decreaseMenuQuantity(Map<String, dynamic> menu) {
    final existingIndex = _selectedMenus.indexWhere(
      (m) => m['id'] == menu['id'],
    );

    if (existingIndex >= 0) {
      if (_selectedMenus[existingIndex]['quantity'] > 1) {
        _selectedMenus[existingIndex]['quantity']--;
      } else {
        _selectedMenus.removeAt(existingIndex);
      }
    }
    // Pastikan setState dipanggil untuk update UI
    if (mounted) setState(() {});
  }
  // ========== END PERBAIKAN ==========

  Widget _buildSelectedMenus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu yang Dipilih',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._selectedMenus.map((menu) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.lightOrange,
              child: Text(
                '${menu['quantity']}',
                style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(menu['name']),
            subtitle: Text('Rp ${menu['price']} x ${menu['quantity']}'),
            trailing: Text(
              'Rp ${((menu['price'] as double) * (menu['quantity'] as int)).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        const Divider(),

        // Promo Section
        if (_selectedPromo != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.discount,
                    color: AppColors.primaryOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(_selectedPromo!.title),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPromo = null;
                  });
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text('Rp ${_subtotal.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Diskon (${_selectedPromo!.discount.toInt()}%):'),
              Text(
                '- Rp ${_discount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Pesanan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Rp ${_totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Payment section dihapus - user pilih metode setelah reservasi disetujui

  Widget _buildPaymentInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Pembayaran',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'DP 50% sebesar ${_formatCurrency(_dpAmount)} akan dibayarkan setelah reservasi disetujui oleh restoran.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitReservation,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Buat Reservasi', style: TextStyle(fontSize: 16)),
    );
  }

  // Date Picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  // Time Picker
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  // Load menus from Firestore
  Future<List<Map<String, dynamic>>> _loadMenus() async {
    try {
      final menus = await _menuService.getMenusByRestaurantId(
        widget.restaurant.id,
      );
      return menus.map((menu) {
        return {
          'id': menu.id,
          'name': menu.name,
          'description': menu.description,
          'price': menu.price,
          'category': menu.category,
          'imageUrl': menu.imageUrl,
        };
      }).toList();
    } catch (e) {
      throw Exception('Gagal memuat menu: $e');
    }
  }

  // Submit Reservation
  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi nama dan nomor telepon')),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih tanggal dan waktu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reservationProvider = Provider.of<ReservationProvider>(
        context,
        listen: false,
      );
      final user = authProvider.user;

      // Status awal = pending_review (menunggu review dari resto)
      final reservation = Reservation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user?.id ?? 'guest',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        restaurantImageUrl: widget.restaurant.imageUrl,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        guestCount: int.parse(_guestController.text),
        date: _selectedDate!,
        time:
            '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        area: _selectedArea,
        menuItems: _selectedMenus,
        totalAmount: _totalAmount,
        dpAmount: _dpAmount, // DP 50% dihitung otomatis
        paymentMethod: 'pending', // Metode pembayaran dipilih setelah approved
        promoId: _selectedPromo?.id,
        promoTitle: _selectedPromo?.title,
        discount: _discount > 0 ? _discount : null,
        status: 'pending_review', // Status awal: menunggu review resto
        createdAt: DateTime.now(),
      );

      final success = await reservationProvider.createReservation(reservation);

      if (success && mounted) {
        // Tampilkan dialog sukses dengan informasi proses
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reservasi Berhasil Diajukan',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permintaan reservasi Anda telah dikirim ke restoran.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Proses Reservasi:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildProcessStep(
                        Icons.pending_actions,
                        'Ajukan reservasi',
                        'Status: Pending Approval',
                        true,
                      ),
                      const SizedBox(height: 8),
                      _buildProcessStep(
                        Icons.thumb_up,
                        'Pemilik restoran mereview',
                        'Menyetujui/menolak/menawarkan waktu alternatif',
                        false,
                      ),
                      const SizedBox(height: 8),
                      _buildProcessStep(
                        Icons.payment,
                        'Pembayaran DP 50%',
                        'Instruksi pembayaran akan muncul setelah disetujui',
                        false,
                      ),
                      const SizedBox(height: 8),
                      _buildProcessStep(
                        Icons.verified,
                        'Konfirmasi akhir',
                        'Upload bukti pembayaran untuk konfirmasi',
                        false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.darkOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pembayaran DP 50% dilakukan setelah reservasi disetujui oleh restoran.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to previous screen
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('OK, Mengerti'),
              ),
            ],
          ),
        );
      } else {
        throw Exception(reservationProvider.error ?? 'Gagal membuat reservasi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat reservasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper widget untuk process step di dialog
  Widget _buildProcessStep(
    IconData icon,
    String title,
    String description,
    bool isActive,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isActive ? Colors.blue : Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.blue : Colors.grey[700],
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
