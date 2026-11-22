// models/promo_model.dart
class Promo {
  String? id;
  String restaurantId;

  /// 'menu'       → diskon harga coretan per item menu
  /// 'restaurant' → diskon dari total order saat reservasi
  String type;

  String title;
  String description;

  /// Nilai preset yang dipilih owner: '5','10','15','20','25','30','50','custom'
  String discountPreset;

  List<String> menuItems; // kosong = berlaku semua menu
  double discount; // persentase, misal 10.0 = 10%
  double? minimumOrder; // opsional, hanya relevan untuk type 'restaurant'
  String? note; // catatan tambahan opsional, menggantikan terms
  DateTime startDate;
  DateTime endDate;
  bool isActive;
  DateTime createdAt;
  DateTime? updatedAt;

  Promo({
    this.id,
    required this.restaurantId,
    required this.type,
    required this.title,
    required this.description,
    required this.discountPreset,
    required this.menuItems,
    required this.discount,
    this.minimumOrder,
    this.note,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Promo.fromMap(Map<String, dynamic> map) {
    // Kompatibilitas dengan data dummy lama yang memakai terms
    String? note = map['note'];
    if (note == null && map['terms'] != null && map['terms'] is List) {
      final termsList = List<String>.from(map['terms']);
      if (termsList.isNotEmpty) {
        note = termsList.join(', ');
      }
    }

    double? minOrder = map['minimumOrder'] != null
        ? (map['minimumOrder'] as num).toDouble()
        : null;

    // Jika minimumOrder belum diset tapi ada di terms (misal "minimal 50k")
    if (minOrder == null && map['terms'] != null && map['terms'] is List) {
      for (final t in List<String>.from(map['terms'])) {
        final lower = t.toLowerCase();
        if (lower.contains('50k') || lower.contains('50.000') || lower.contains('50000')) {
          minOrder = 50000;
          break;
        } else if (lower.contains('100k') || lower.contains('100.000') || lower.contains('100000')) {
          minOrder = 100000;
          break;
        }
      }
    }

    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? fallback;
    }

    return Promo(
      id: map['id'],
      restaurantId: map['restaurantId'] ?? '',
      type: map['type'] ?? 'restaurant',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discountPreset: map['discountPreset'] ?? 'custom',
      menuItems: map['menuItems'] != null
          ? List<String>.from(map['menuItems'])
          : [],
      discount: (map['discount'] ?? 0).toDouble(),
      minimumOrder: minOrder,
      note: note,
      startDate: parseDate(map['startDate'], DateTime.now()),
      endDate: parseDate(map['endDate'], DateTime.now().add(const Duration(days: 30))),
      isActive: map['isActive'] ?? true,
      createdAt: parseDate(map['createdAt'], DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'type': type,
      'title': title,
      'description': description,
      'discountPreset': discountPreset,
      'menuItems': menuItems,
      'discount': discount,
      'minimumOrder': minimumOrder,
      'note': note,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// True jika promo sedang dalam periode aktif
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// True jika promo belum mulai
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  /// True jika promo sudah berakhir
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Label status untuk UI owner
  String get statusLabel {
    if (!isActive) return 'Nonaktif';
    if (isUpcoming) return 'Akan Datang';
    if (isExpired) return 'Berakhir';
    return 'Aktif';
  }
}
