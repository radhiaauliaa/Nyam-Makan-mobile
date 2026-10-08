// screens/shared/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Common settings
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  String _language = 'Indonesia';

  // User specific
  bool _showOnlineStatus = true;
  bool _shareLocation = false;

  // Owner specific
  String _defaultOpenTime = '08:00';
  String _defaultCloseTime = '22:00';
  bool _autoAcceptReservations = false;

  // Admin specific
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  int _backupFrequency = 7; // days

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pengaturan'),
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
                      Icons.settings,
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
                          'Pengaturan Aplikasi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sesuaikan preferensi Anda',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Common Settings
            _buildCommonSettings(),

            const SizedBox(height: 16),

            // Role-specific settings
            if (user?.role == 'Pengguna') _buildUserSettings(),
            if (user?.role == 'Pemilik Resto') _buildOwnerSettings(),
            if (user?.role == 'Admin') _buildAdminSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Umum',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _SettingCard(
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.notifications,
                title: 'Notifikasi',
                subtitle: 'Aktifkan semua notifikasi',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),

              if (_notificationsEnabled) ...[
                const Divider(height: 1),
                _SwitchTile(
                  icon: Icons.email,
                  title: 'Notifikasi Email',
                  subtitle: 'Terima notifikasi via email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                ),

                const Divider(height: 1),
                _SwitchTile(
                  icon: Icons.notifications_active,
                  title: 'Push Notifications',
                  subtitle: 'Notifikasi langsung ke perangkat',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                ),
              ],

              const Divider(height: 1),
              _SelectTile(
                icon: Icons.language,
                title: 'Bahasa',
                subtitle: _language,
                onTap: () {
                  _showLanguageDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privasi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _SettingCard(
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.visibility,
                title: 'Status Online',
                subtitle: 'Tampilkan status online Anda',
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() {
                    _showOnlineStatus = value;
                  });
                },
              ),

              const Divider(height: 1),
              _SwitchTile(
                icon: Icons.location_on,
                title: 'Bagikan Lokasi',
                subtitle: 'Izinkan akses lokasi untuk rekomendasi',
                value: _shareLocation,
                onChanged: (value) {
                  setState(() {
                    _shareLocation = value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Data & Penyimpanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _SettingCard(
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.history,
                title: 'Hapus Cache',
                subtitle: 'Bersihkan data temporary',
                onTap: () {
                  _showClearCacheDialog();
                },
              ),

              const Divider(height: 1),
              _ActionTile(
                icon: Icons.download,
                title: 'Download Data Saya',
                subtitle: 'Unduh semua data pribadi',
                onTap: () {
                  _showDownloadDataDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengaturan Restoran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _SettingCard(
          child: Column(
            children: [
              _SelectTile(
                icon: Icons.access_time,
                title: 'Jam Buka Default',
                subtitle: _defaultOpenTime,
                onTap: () {
                  _showTimePickerDialog(true);
                },
              ),

              const Divider(height: 1),
              _SelectTile(
                icon: Icons.access_time_filled,
                title: 'Jam Tutup Default',
                subtitle: _defaultCloseTime,
                onTap: () {
                  _showTimePickerDialog(false);
                },
              ),

              const Divider(height: 1),
              _SwitchTile(
                icon: Icons.auto_awesome,
                title: 'Auto Accept Reservasi',
                subtitle: 'Terima reservasi otomatis',
                value: _autoAcceptReservations,
                onChanged: (value) {
                  setState(() {
                    _autoAcceptReservations = value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _SettingCard(
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.account_balance,
                title: 'Rekening Bank',
                subtitle: 'Kelola rekening pembayaran',
                onTap: () {
                  // TODO: Navigate to bank account settings
                },
              ),

              const Divider(height: 1),
              _ActionTile(
                icon: Icons.receipt_long,
                title: 'Riwayat Transaksi',
                subtitle: 'Lihat semua transaksi',
                onTap: () {
                  // TODO: Navigate to transaction history
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sistem',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _SettingCard(
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.construction,
                title: 'Mode Maintenance',
                subtitle: 'Nonaktifkan akses sementara',
                value: _maintenanceMode,
                onChanged: (value) {
                  setState(() {
                    _maintenanceMode = value;
                  });
                },
              ),

              const Divider(height: 1),
              _SwitchTile(
                icon: Icons.person_add,
                title: 'Izinkan Registrasi Baru',
                subtitle: 'User baru bisa mendaftar',
                value: _allowNewRegistrations,
                onChanged: (value) {
                  setState(() {
                    _allowNewRegistrations = value;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Backup & Keamanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _SettingCard(
          child: Column(
            children: [
              _SelectTile(
                icon: Icons.backup,
                title: 'Frekuensi Backup',
                subtitle: 'Setiap $_backupFrequency hari',
                onTap: () {
                  _showBackupFrequencyDialog();
                },
              ),

              const Divider(height: 1),
              _ActionTile(
                icon: Icons.cloud_upload,
                title: 'Backup Manual',
                subtitle: 'Backup data sekarang',
                onTap: () {
                  _showBackupDialog();
                },
              ),

              const Divider(height: 1),
              _ActionTile(
                icon: Icons.security,
                title: 'Log Keamanan',
                subtitle: 'Lihat aktivitas sistem',
                onTap: () {
                  // TODO: Navigate to security logs
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Database',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _SettingCard(
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.analytics,
                title: 'Statistik Database',
                subtitle: 'Ukuran dan performa',
                onTap: () {
                  // TODO: Show database stats
                },
              ),

              const Divider(height: 1),
              _ActionTile(
                icon: Icons.cleaning_services,
                title: 'Bersihkan Data Lama',
                subtitle: 'Hapus data lebih dari 1 tahun',
                onTap: () {
                  _showCleanOldDataDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Indonesia'),
              value: 'Indonesia',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Cache'),
        content: const Text('Yakin ingin menghapus semua cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Data'),
        content: const Text(
          'Data Anda akan dikirim via email dalam format PDF',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permintaan download berhasil. Cek email Anda'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showTimePickerDialog(bool isOpenTime) {
    showTimePicker(context: context, initialTime: TimeOfDay.now()).then((time) {
      if (time != null) {
        setState(() {
          final timeString =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          if (isOpenTime) {
            _defaultOpenTime = timeString;
          } else {
            _defaultCloseTime = timeString;
          }
        });
      }
    });
  }

  void _showBackupFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frekuensi Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 3, 7, 14, 30].map((days) {
            return RadioListTile<int>(
              title: Text('Setiap $days hari'),
              value: days,
              groupValue: _backupFrequency,
              onChanged: (value) {
                setState(() {
                  _backupFrequency = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Database'),
        content: const Text('Yakin ingin melakukan backup sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup dimulai...'),
                  backgroundColor: AppColors.primaryOrange,
                ),
              );
            },
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  void _showCleanOldDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bersihkan Data Lama'),
        content: const Text(
          'Hapus semua data lebih dari 1 tahun? Aksi ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data lama berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;

  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryOrange),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryOrange,
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryOrange),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryOrange),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
