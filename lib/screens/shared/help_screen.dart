// screens/shared/help_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bantuan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lightOrange!, AppColors.darkOrange!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Bantuan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kami siap membantu Anda',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content berdasarkan role
            if (user?.role == 'Pengguna') _buildUserHelp(context),
            if (user?.role == 'Pemilik Resto') _buildOwnerHelp(context),
            if (user?.role == 'Admin') _buildAdminHelp(context),

            const SizedBox(height: 24),

            // Contact Support
            _buildContactSupport(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHelp(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Panduan Pengguna',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _HelpCard(
          icon: Icons.restaurant_menu,
          title: 'Cara Melakukan Reservasi',
          items: const [
            '1. Pilih restoran yang diinginkan',
            '2. Pilih menu yang ingin dipesan',
            '3. Pilih tanggal dan waktu reservasi',
            '4. Isi data diri dan jumlah tamu',
            '5. Lakukan pembayaran DP 50%',
            '6. Upload bukti pembayaran',
            '7. Tunggu konfirmasi dari restoran',
          ],
        ),

        _HelpCard(
          icon: Icons.payment,
          title: 'Cara Pembayaran',
          items: const [
            '• Pembayaran DP 50% dilakukan saat reservasi',
            '• Transfer ke rekening yang tertera',
            '• Upload bukti transfer dengan jelas',
            '• Pembayaran sisanya di restoran',
            '• Pembayaran akan diverifikasi dalam 24 jam',
          ],
        ),

        _HelpCard(
          icon: Icons.local_offer,
          title: 'Cara Menggunakan Promo',
          items: const [
            '1. Lihat promo yang tersedia di menu Promo',
            '2. Pilih promo yang diinginkan',
            '3. Klik "Gunakan Promo"',
            '4. Pilih menu sesuai ketentuan promo',
            '5. Diskon akan otomatis terpotong',
            '6. Lakukan reservasi seperti biasa',
          ],
        ),

        _HelpCard(
          icon: Icons.favorite,
          title: 'Cara Menambah Favorit',
          items: const [
            '• Klik icon love pada restoran',
            '• Restoran akan masuk ke daftar favorit',
            '• Akses favorit dari menu Favorite',
            '• Klik lagi untuk menghapus favorit',
          ],
        ),

        _HelpCard(
          icon: Icons.cancel,
          title: 'Cara Membatalkan Reservasi',
          items: const [
            '• Buka halaman Reservasi',
            '• Pilih reservasi yang ingin dibatalkan',
            '• Klik tombol "Batalkan Reservasi"',
            '• Konfirmasi pembatalan',
            '• Pengembalian DP sesuai kebijakan',
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerHelp(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Panduan Pemilik Restoran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _HelpCard(
          icon: Icons.approval,
          title: 'Cara Mengelola Reservasi',
          items: const [
            '1. Lihat daftar reservasi masuk',
            '2. Periksa detail reservasi pelanggan',
            '3. Konfirmasi atau tolak reservasi',
            '4. Jika ditolak, berikan alasan & waktu alternatif',
            '5. Verifikasi pembayaran DP',
            '6. Update status reservasi',
          ],
        ),

        _HelpCard(
          icon: Icons.restaurant,
          title: 'Cara Mengelola Menu',
          items: const [
            '• Tambah menu baru melalui dashboard',
            '• Upload foto menu yang menarik',
            '• Atur harga dan kategori menu',
            '• Update ketersediaan menu',
            '• Hapus menu yang tidak tersedia',
          ],
        ),

        _HelpCard(
          icon: Icons.local_offer,
          title: 'Cara Membuat Promo',
          items: const [
            '1. Buat promo dari menu Promo',
            '2. Tentukan jenis promo (%, fixed)',
            '3. Pilih menu yang berlaku promo',
            '4. Atur periode promo',
            '5. Tentukan minimal pembelian',
            '6. Aktifkan promo',
          ],
        ),

        _HelpCard(
          icon: Icons.table_restaurant,
          title: 'Cara Mengatur Meja',
          items: const [
            '• Set kapasitas meja per area',
            '• Atur nomor meja tersedia',
            '• Update status meja (tersedia/terisi)',
            '• Assign meja saat konfirmasi reservasi',
          ],
        ),

        _HelpCard(
          icon: Icons.bar_chart,
          title: 'Cara Melihat Laporan',
          items: const [
            '• Akses menu Laporan di dashboard',
            '• Lihat statistik reservasi harian',
            '• Monitor pendapatan dan pembayaran',
            '• Analisis rating dan review',
            '• Export laporan bulanan',
          ],
        ),
      ],
    );
  }

  Widget _buildAdminHelp(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Panduan Administrator',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _HelpCard(
          icon: Icons.verified,
          title: 'Cara Verifikasi Restoran',
          items: const [
            '1. Lihat daftar restoran pending',
            '2. Periksa dokumen dan informasi',
            '3. Verifikasi data kesesuaian',
            '4. Approve atau reject pendaftaran',
            '5. Berikan catatan jika ditolak',
            '6. Restoran akan notifikasi hasil',
          ],
        ),

        _HelpCard(
          icon: Icons.people,
          title: 'Cara Mengelola User',
          items: const [
            '• Lihat daftar semua user',
            '• Filter by role (Pengguna/Owner)',
            '• Edit informasi user',
            '• Suspend user bermasalah',
            '• Aktifkan kembali user',
            '• Hapus akun permanen',
          ],
        ),

        _HelpCard(
          icon: Icons.restaurant,
          title: 'Cara Mengelola Restoran',
          items: const [
            '• Monitor semua restoran terdaftar',
            '• Edit informasi restoran',
            '• Set status verifikasi',
            '• Suspend restoran melanggar',
            '• Hapus restoran jika perlu',
          ],
        ),

        _HelpCard(
          icon: Icons.report,
          title: 'Cara Handle Laporan',
          items: const [
            '1. Terima laporan dari user',
            '2. Investigasi kasus',
            '3. Periksa bukti dan data',
            '4. Ambil tindakan sesuai',
            '5. Berikan solusi ke pelapor',
            '6. Dokumentasi hasil penanganan',
          ],
        ),

        _HelpCard(
          icon: Icons.settings,
          title: 'Cara Mengelola Sistem',
          items: const [
            '• Monitor performa aplikasi',
            '• Update konfigurasi sistem',
            '• Backup data berkala',
            '• Manage notifikasi sistem',
            '• Set parameter aplikasi',
          ],
        ),
      ],
    );
  }

  Widget _buildContactSupport(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Butuh Bantuan Lebih Lanjut?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _ContactItem(
            icon: Icons.email,
            title: 'Email',
            value: 'support@nyammakaan.com',
            onTap: () {
              // TODO: Open email app
            },
          ),

          _ContactItem(
            icon: Icons.phone,
            title: 'Telepon',
            value: '+62 812-3456-7890',
            onTap: () {
              // TODO: Open phone dialer
            },
          ),

          _ContactItem(
            icon: Icons.chat,
            title: 'WhatsApp',
            value: '+62 812-3456-7890',
            onTap: () {
              // TODO: Open WhatsApp
            },
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _HelpCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryOrange),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
