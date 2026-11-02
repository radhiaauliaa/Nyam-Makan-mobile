
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mengambil konteks Firestore berdasarkan pertanyaan pengguna.
  Future<String> getDatabaseContext(String question) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('Pengguna harus login terlebih dahulu.');
      }

      final q = question.toLowerCase().trim();
      final contexts = <String>[];

      // 1. Menu dan restoran.
      if (_containsAny(q, [
        'menu',
        'makanan',
        'minuman',
        'harga',
        'restoran',
        'restaurant',
        'lokasi',
        'alamat',
        'ayam',
        'ramen',
        'matcha',
        'buka',
        'tutup',
        'jam operasional',
        'kategori',
        'tersedia',
        'favorit',
        'termurah',
        'termahal',
        'rekomendasi',
        'tempat makan',
      ])) {
        contexts.add(
          await _getMenuAndRestaurantContext(question),
        );
      }

      // 2. Promo.
      if (_containsAny(q, [
        'promo',
        'diskon',
        'discount',
        'potongan',
        'voucher',
        'penawaran',
      ])) {
        contexts.add(await _getPromoContext());
      }

      // 3. Ulasan dan rating.
      if (_containsAny(q, [
        'review',
        'ulasan',
        'rating',
        'penilaian',
        'komentar',
        'pendapat',
      ])) {
        contexts.add(
          await _getReviewContext(question),
        );
      }

      // 4. Reservasi milik pengguna.
      if (_containsAny(q, [
        'reservasi',
        'reservation',
        'pesanan',
        'booking',
        'meja',
        'pemesanan',
        'jadwal',
        'status reservasi',
        'reservasi saya',
        'riwayat reservasi',
      ])) {
        contexts.add(
          await _getReservationContext(user.uid),
        );
      }

      // 5. Notifikasi milik pengguna.
      if (_containsAny(q, [
        'notifikasi',
        'notification',
        'pemberitahuan',
        'pesan masuk',
      ])) {
        contexts.add(
          await _getNotificationContext(user.uid),
        );
      }

      // 6. Profil pengguna sendiri.
      if (_containsAny(q, [
        'profil',
        'akun saya',
        'username',
        'nama akun',
        'status akun',
        'jumlah ulasan saya',
        'jumlah favorit saya',
      ])) {
        contexts.add(
          await _getUserContext(user.uid),
        );
      }

      // 7. Pertanyaan umum.
      // Jika tidak ada kategori yang terdeteksi,
      // tampilkan data publik menu, restoran, dan promo.
      if (contexts.isEmpty) {
        contexts.add(
          await _getMenuAndRestaurantContext(question),
        );

        contexts.add(
          await _getPromoContext(),
        );
      }

      return contexts.join('\n\n');
    } catch (e) {
      throw Exception(
        'Gagal mengambil konteks Firestore: $e',
      );
    }
  }

  // =====================================================
  // MENU DAN RESTORAN
  // =====================================================

  Future<String> _getMenuAndRestaurantContext(
    String question,
  ) async {
    final menuSnapshot = await _firestore
        .collection('menus')
        .where('isAvailable', isEqualTo: true)
        .limit(100)
        .get();

    final restaurantSnapshot = await _firestore
        .collection('restaurants')
        .where('status', isEqualTo: 'verified')
        .limit(100)
        .get();

    // Menyimpan restoran berdasarkan document ID
    // dan field id jika tersedia.
    final Map<String, Map<String, dynamic>> restaurants = {};

    for (final doc in restaurantSnapshot.docs) {
      final data = doc.data();

      restaurants[doc.id] = data;

      final restaurantId = data['id']?.toString();

      if (restaurantId != null &&
          restaurantId.isNotEmpty) {
        restaurants[restaurantId] = data;
      }
    }

    final keywords = _extractKeywords(question);

    // Menghitung relevansi menu dengan pertanyaan.
    final scoredMenus = menuSnapshot.docs.map((doc) {
      final data = doc.data();

      final searchable = _buildText([
        data['name'],
        data['category'],
        data['description'],
        data['tags'],
      ]);

      return {
        ...data,
        'documentId': doc.id,
        '_score': _calculateScore(
          searchable,
          keywords,
        ),
      };
    }).where((menu) {
      return keywords.isEmpty ||
          (menu['_score'] as int) > 0;
    }).toList();

    scoredMenus.sort(
      (a, b) => (b['_score'] as int)
          .compareTo(a['_score'] as int),
    );

    final selectedMenus = scoredMenus.take(10).toList();

    // Menyusun informasi menu.
    final menuContext = selectedMenus.map((menu) {
      final restaurantId =
          menu['restaurantId']?.toString() ?? '';

      final restaurant = restaurants[restaurantId];

      return '''
Nama menu: ${menu['name'] ?? '-'}
Kategori: ${menu['category'] ?? '-'}
Deskripsi: ${menu['description'] ?? '-'}
Harga: Rp${menu['price'] ?? '-'}
Rating: ${menu['rating'] ?? 0}
Restoran: ${restaurant?['name'] ?? 'Tidak ditemukan'}
''';
    }).join('\n');

    // Menyusun informasi restoran.
    final restaurantContext = restaurants.values
        .toSet()
        .where((restaurant) {
          final restaurantId =
              restaurant['id']?.toString() ?? '';

          final name = _buildText([
            restaurant['name'],
            restaurant['categories'],
            restaurant['description'],
            restaurant['address'],
          ]);

          final relatedToMenu = selectedMenus.any(
            (menu) =>
                menu['restaurantId']?.toString() ==
                    restaurantId,
          );

          return relatedToMenu ||
              _calculateScore(name, keywords) > 0;
        })
        .take(10)
        .map((restaurant) {
          final hours = restaurant['openingHours'];
          final price = restaurant['priceRange'];

          return '''
Nama restoran: ${restaurant['name'] ?? '-'}
Deskripsi: ${restaurant['description'] ?? '-'}
Alamat: ${restaurant['address'] ?? '-'}
Kategori: ${_toText(restaurant['categories'])}
Jam buka: ${hours is Map ? hours['open'] ?? '-' : '-'}
Jam tutup: ${hours is Map ? hours['close'] ?? '-' : '-'}
Status buka: ${restaurant['isOpen'] ?? false}
Kisaran harga: ${_toText(price)}
Rating: ${restaurant['rating'] ?? 0}
''';
        })
        .join('\n');

    return '''
DATA MENU:
${menuContext.isEmpty ? 'Tidak ditemukan menu relevan.' : menuContext}

DATA RESTORAN:
${restaurantContext.isEmpty ? 'Tidak ditemukan restoran relevan.' : restaurantContext}
''';
  }

  // =====================================================
  // PROMO
  // =====================================================

  Future<String> _getPromoContext() async {
    final snapshot = await _firestore
        .collection('promo')
        .where('isActive', isEqualTo: true)
        .limit(50)
        .get();

    final now = DateTime.now();

    final activePromos = snapshot.docs.where((doc) {
      final data = doc.data();

      final start = DateTime.tryParse(
        data['startDate']?.toString() ?? '',
      );

      final end = DateTime.tryParse(
        data['endDate']?.toString() ?? '',
      );

      return start != null &&
          end != null &&
          !now.isBefore(start) &&
          !now.isAfter(end);
    }).toList();

    final result = activePromos.map((doc) {
      final data = doc.data();

      return '''
Nama promo: ${data['title'] ?? '-'}
Deskripsi: ${data['description'] ?? '-'}
Diskon: ${data['discount'] ?? 0}%
Mulai: ${data['startDate'] ?? '-'}
Berakhir: ${data['endDate'] ?? '-'}
Syarat: ${_toText(data['terms'])}
''';
    }).join('\n');

    return '''
DATA PROMO AKTIF:
${result.isEmpty ? 'Tidak ada promo aktif saat ini.' : result}
''';
  }

  // =====================================================
  // REVIEW
  // =====================================================

  Future<String> _getReviewContext(
    String question,
  ) async {
    final snapshot = await _firestore
        .collection('review')
        .limit(100)
        .get();

    final keywords = _extractKeywords(question);

    final reviews = snapshot.docs.where((doc) {
      final data = doc.data();

      final searchable = _buildText([
        data['restaurantName'],
        data['comment'],
        data['selectedMenus'],
      ]);

      return keywords.isEmpty ||
          _calculateScore(
            searchable,
            keywords,
          ) > 0;
    }).take(10).toList();

    final result = reviews.map((doc) {
      final data = doc.data();

      return '''
Restoran: ${data['restaurantName'] ?? '-'}
Rating: ${data['rating'] ?? 0}
Komentar: ${data['comment'] ?? '-'}
Pilihan menu: ${_toText(data['selectedMenus'])}
Pilihan makan: ${data['diningOption'] ?? '-'}
Balasan restoran: ${data['ownerReply'] ?? 'Belum ada balasan'}
''';
    }).join('\n');

    return '''
DATA ULASAN:
${result.isEmpty ? 'Tidak ditemukan ulasan relevan.' : result}
''';
  }

  // =====================================================
  // RESERVASI PENGGUNA
  // =====================================================

  Future<String> _getReservationContext(
    String uid,
  ) async {
    final snapshot = await _firestore
        .collection('reservasi')
        .where('userId', isEqualTo: uid)
        .limit(20)
        .get();

    final result = snapshot.docs.map((doc) {
      final data = doc.data();

      return '''
ID reservasi: ${data['id'] ?? doc.id}
Restoran: ${data['restaurantName'] ?? '-'}
Tanggal: ${_toText(data['date'])}
Waktu: ${data['time'] ?? '-'}
Jumlah tamu: ${data['guestCount'] ?? 0}
Area: ${data['area'] ?? '-'}
Nomor meja: ${data['tableNumber'] ?? '-'}
Total pembayaran: Rp${data['totalAmount'] ?? 0}
Status reservasi: ${data['status'] ?? '-'}
Menu pesanan: ${_toText(data['menuItems'])}
''';
    }).join('\n');

    return '''
DATA RESERVASI PENGGUNA:
${result.isEmpty ? 'Belum ditemukan reservasi milik pengguna.' : result}
''';
  }

  // =====================================================
  // NOTIFIKASI PENGGUNA
  // =====================================================

  Future<String> _getNotificationContext(
    String uid,
  ) async {
    final snapshot = await _firestore
        .collection('notification')
        .where('recipientId', isEqualTo: uid)
        .where('recipientType', isEqualTo: 'user')
        .limit(20)
        .get();

    final result = snapshot.docs.map((doc) {
      final data = doc.data();

      return '''
Judul: ${data['title'] ?? '-'}
Pesan: ${data['message'] ?? data['body'] ?? '-'}
Jenis: ${data['type'] ?? '-'}
Sudah dibaca: ${data['isRead'] ?? false}
Waktu: ${_toText(data['createdAt'])}
''';
    }).join('\n');

    return '''
DATA NOTIFIKASI PENGGUNA:
${result.isEmpty ? 'Tidak ditemukan notifikasi pengguna.' : result}
''';
  }

  // =====================================================
  // PROFIL PENGGUNA
  // =====================================================

  Future<String> _getUserContext(String uid) async {
    // Asumsi document ID pada collection user = UID.
    final doc = await _firestore
        .collection('user')
        .doc(uid)
        .get();

    if (!doc.exists) {
      return 'DATA PROFIL: Profil pengguna belum ditemukan.';
    }

    final data = doc.data()!;

    // Hanya mengambil informasi profil yang aman.
    return '''
DATA PROFIL PENGGUNA:
Username: ${data['username'] ?? '-'}
Role: ${data['role'] ?? '-'}
Status akun: ${data['status'] ?? '-'}
Jumlah ulasan: ${data['reviewCount'] ?? 0}
Jumlah favorit: ${data['favoriteCount'] ?? 0}
''';
  }

  // =====================================================
  // HELPER
  // =====================================================

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(
      (keyword) => text.contains(keyword),
    );
  }

  List<String> _extractKeywords(String question) {
    const stopWords = {
      'apa',
      'ada',
      'yang',
      'dan',
      'di',
      'ke',
      'dari',
      'untuk',
      'dengan',
      'ini',
      'itu',
      'saya',
      'aku',
      'mau',
      'ingin',
      'tolong',
      'carikan',
      'tampilkan',
      'berapa',
      'apakah',
      'dong',
      'nih',
      'ya',
      'bagaimana',
      'gimana',
      'dimana',
      'mana',
      'siapa',
      'kapan',
      'oleh',
      'pada',
      'atau',
      'bisa',
      'kah',
      'nya',
      'punya',
    };

    return question
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) =>
            word.length > 2 &&
            !stopWords.contains(word))
        .toSet()
        .toList();
  }

  int _calculateScore(
    String text,
    List<String> keywords,
  ) {
    int score = 0;

    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        score++;
      }
    }

    return score;
  }

  String _buildText(List<dynamic> values) {
    return values
        .map(_toText)
        .join(' ')
        .toLowerCase();
  }

  String _toText(dynamic value) {
    if (value == null) {
      return '-';
    }

    if (value is Timestamp) {
      return value.toDate().toString();
    }

    if (value is DateTime) {
      return value.toString();
    }

    if (value is List) {
      return value.map(_toText).join(', ');
    }

    if (value is Map) {
      return value.entries
          .map(
            (e) => '${e.key}: ${_toText(e.value)}',
          )
          .join(', ');
    }

    return value.toString();
  }
}
