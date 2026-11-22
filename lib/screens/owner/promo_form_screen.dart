// screens/owner/promo_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/promo_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_model.dart';
import '../../providers/promo_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/menu_service.dart';
import '../../widgets/discount_preset_selector.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';

class PromoFormScreen extends StatefulWidget {
  final Restaurant restaurant;
  final Promo? promoToEdit;

  const PromoFormScreen({
    super.key,
    required this.restaurant,
    this.promoToEdit,
  });

  @override
  State<PromoFormScreen> createState() => _PromoFormScreenState();
}

class _PromoFormScreenState extends State<PromoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _promoType; // 'menu' atau 'restaurant'
  late String _selectedPreset;
  late double _discountPercent;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _minimumOrderController;
  late TextEditingController _noteController;

  late DateTime _startDate;
  late DateTime _endDate;

  List<String> _selectedMenuIds = [];
  List<Menu> _restaurantMenus = [];
  Set<String> _conflictingMenuIds = {}; // Menu yang sudah ikut promo aktif lain
  bool _isLoadingMenus = true;
  bool _isSaving = false;

  bool get isEditing => widget.promoToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.promoToEdit;

    _promoType = p?.type ?? 'menu';
    _selectedPreset = p?.discountPreset ?? '10';
    _discountPercent = p?.discount ?? 10.0;

    _titleController = TextEditingController(text: p?.title ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _minimumOrderController = TextEditingController(
      text: p?.minimumOrder != null && p!.minimumOrder! > 0
          ? p.minimumOrder!.toInt().toString()
          : '',
    );
    _noteController = TextEditingController(text: p?.note ?? '');

    _startDate = p?.startDate ?? DateTime.now();
    _endDate = p?.endDate ?? DateTime.now().add(const Duration(days: 14));

    if (p != null) {
      _selectedMenuIds = List<String>.from(p.menuItems);
    }

    _loadMenusAndConflicts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _minimumOrderController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMenusAndConflicts() async {
    setState(() => _isLoadingMenus = true);
    try {
      final restaurantId = widget.restaurant.id ?? '';
      final menuService = MenuService();
      final promoProvider = Provider.of<PromoProvider>(context, listen: false);

      List<Menu> menus = [];
      try {
        menus = await menuService.getMenusByRestaurantId(restaurantId);
      } catch (e) {
        debugPrint('Error loading menus via MenuService: $e');
        final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
        menus = await restaurantProvider.getMenusByRestaurantId(restaurantId);
      }

      final allMenuIds = menus.map((m) => m.id).toList();
      Set<String> conflicts = {};
      try {
        final conflictList = await promoProvider.getMenuIdsAlreadyInActivePromo(
          restaurantId,
          allMenuIds,
          excludePromoId: widget.promoToEdit?.id,
        );
        conflicts = conflictList.toSet();
      } catch (e) {
        debugPrint('Error checking promo conflicts: $e');
      }

      setState(() {
        _restaurantMenus = menus;
        _conflictingMenuIds = conflicts;
        _isLoadingMenus = false;
      });
    } catch (e) {
      debugPrint('Error loading menus for promo form: $e');
      setState(() => _isLoadingMenus = false);
    }
  }

  void _onDiscountChanged(String preset, double percent) {
    setState(() {
      _selectedPreset = preset;
      _discountPercent = percent;
    });
  }

  String _generateDefaultTitle() {
    final pct = _discountPercent.toInt();
    if (_promoType == 'menu') {
      return 'Diskon $pct% Menu Pilihan';
    } else {
      return 'Diskon $pct% Total Reservasi';
    }
  }

  Future<void> _savePromo() async {
    if (_discountPercent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih atau masukkan persentase diskon yang valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_promoType == 'menu' && _selectedMenuIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 menu untuk promo menu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal berakhir harus setelah tanggal mulai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim().isEmpty
          ? _generateDefaultTitle()
          : _titleController.text.trim();

      final minOrder = _minimumOrderController.text.trim().isNotEmpty
          ? double.tryParse(_minimumOrderController.text.trim())
          : null;

      final promoProvider = Provider.of<PromoProvider>(context, listen: false);

      final promo = Promo(
        id: widget.promoToEdit?.id,
        restaurantId: widget.restaurant.id,
        type: _promoType,
        title: title,
        description: _descriptionController.text.trim(),
        discountPreset: _selectedPreset,
        menuItems: _promoType == 'menu' ? _selectedMenuIds : [],
        discount: _discountPercent,
        minimumOrder: _promoType == 'restaurant' ? minOrder : null,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        isActive: widget.promoToEdit?.isActive ?? true,
        createdAt: widget.promoToEdit?.createdAt ?? DateTime.now(),
        updatedAt: isEditing ? DateTime.now() : null,
      );

      if (isEditing) {
        await promoProvider.updatePromo(promo);
      } else {
        await promoProvider.addPromo(promo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Promo berhasil diperbarui' : 'Promo berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Promo' : 'Tambah Promo Baru',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingMenus
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPromoTypeSelector(),
                    const SizedBox(height: 20),
                    _buildDiscountCard(),
                    const SizedBox(height: 20),
                    if (_promoType == 'menu') ...[
                      _buildMenuSelectionCard(),
                      const SizedBox(height: 20),
                    ],
                    _buildDetailsCard(),
                    const SizedBox(height: 20),
                    _buildPeriodCard(),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── 1. Pilihan Jenis Promo ───────────────────────────────────────────────

  Widget _buildPromoTypeSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jenis Promo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih apakah diskon berlaku langsung pada menu atau pada total reservasi',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    title: 'Promo Menu',
                    subtitle: 'Harga coret per item menu',
                    icon: Icons.restaurant_menu,
                    isSelected: _promoType == 'menu',
                    onTap: () => setState(() => _promoType = 'menu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    title: 'Promo Restoran',
                    subtitle: 'Diskon total order saat reservasi',
                    icon: Icons.confirmation_number_outlined,
                    isSelected: _promoType == 'restaurant',
                    onTap: () => setState(() => _promoType = 'restaurant'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightOrange.withValues(alpha: 0.4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryOrange : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? AppColors.primaryOrange : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. Besaran Diskon & Preset ──────────────────────────────────────────

  Widget _buildDiscountCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DiscountPresetSelector(
          selectedPreset: _selectedPreset,
          discountPercent: _discountPercent,
          onChanged: _onDiscountChanged,
        ),
      ),
    );
  }

  // ─── 3. Pilihan Menu & Live Preview Coretan ──────────────────────────────

  Widget _buildMenuSelectionCard() {
    final availableForPromo = _restaurantMenus.where((m) => !_conflictingMenuIds.contains(m.id)).toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Menu yang Didiskon',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (availableForPromo.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMenuIds.length == availableForPromo.length) {
                          _selectedMenuIds.clear();
                        } else {
                          _selectedMenuIds = availableForPromo.map((m) => m.id).toList();
                        }
                      });
                    },
                    child: Text(
                      _selectedMenuIds.length == availableForPromo.length
                          ? 'Batal Semua'
                          : 'Pilih Semua',
                      style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedMenuIds.length} menu terpilih. 1 menu hanya boleh masuk 1 promo aktif.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (_restaurantMenus.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Belum ada menu di restoran ini', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _restaurantMenus.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final menu = _restaurantMenus[index];
                  final isConflict = _conflictingMenuIds.contains(menu.id);
                  final isSelected = _selectedMenuIds.contains(menu.id);

                  // Base price (jika menu sedang promo saat ini, gunakan originalPrice)
                  final basePrice = menu.originalPrice ?? menu.price;
                  final discountedPrice = basePrice * (1 - _discountPercent / 100);

                  return CheckboxListTile(
                    value: isSelected,
                    enabled: !isConflict,
                    activeColor: AppColors.primaryOrange,
                    contentPadding: EdgeInsets.zero,
                    onChanged: isConflict
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedMenuIds.add(menu.id);
                              } else {
                                _selectedMenuIds.remove(menu.id);
                              }
                            });
                          },
                    title: Text(
                      menu.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isConflict ? Colors.grey : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isConflict)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Sudah terdaftar di promo aktif lain',
                              style: TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                Helpers.formatCurrency(basePrice),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  decoration: isSelected && _discountPercent > 0
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (isSelected && _discountPercent > 0) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 12, color: AppColors.primaryOrange),
                                const SizedBox(width: 4),
                                Text(
                                  Helpers.formatCurrency(discountedPrice),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-${_discountPercent.toInt()}%',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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

  // ─── 4. Detail Info (Judul, Deskripsi, Min Order, Note) ───────────────────

  Widget _buildDetailsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Promo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Judul Promo
            const Text(
              'Judul Promo',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _generateDefaultTitle(),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Deskripsi Promo
            const Text(
              'Deskripsi Singkat',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tuliskan keterangan promo yang menarik bagi pelanggan',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Minimum Order (Hanya untuk Promo Restoran)
            if (_promoType == 'restaurant') ...[
              const Text(
                'Minimum Pembelian (Opsional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _minimumOrderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: 'Contoh: 50000 (kosongkan jika tidak ada)',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Catatan Tambahan (Pengganti S&K)
            const Text(
              'Catatan Tambahan (Opsional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Contoh: Berlaku untuk makan di tempat, tidak berlaku akhir pekan',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5. Periode Berlaku ──────────────────────────────────────────────────

  Widget _buildPeriodCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Periode Berlaku',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Promo akan otomatis aktif dan berakhir sesuai tanggal yang ditentukan',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Mulai',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _pickDate(isStart: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryOrange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(_startDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Berakhir',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _pickDate(isStart: false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_busy, size: 16, color: AppColors.primaryOrange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(_endDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart ? DateTime.now().subtract(const Duration(days: 365)) : _startDate;
    final last = DateTime.now().add(const Duration(days: 365 * 3));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // ─── 6. Tombol Simpan ────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _savePromo,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                isEditing ? 'Simpan Perubahan' : 'Terbitkan Promo',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
