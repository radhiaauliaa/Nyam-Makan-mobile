import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/theme.dart';
import '../../widgets/PhoneNumberInput.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User tidak ditemukan')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: _startEditing),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Menyimpan perubahan...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(user),

                  const SizedBox(height: 32),

                  // Profile Form
                  _buildProfileForm(user),

                  const SizedBox(height: 32),

                  // Statistics
                  _buildStatistics(user),

                  const SizedBox(height: 32),

                  // Actions
                  _buildActionButtons(authProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        // Profile Picture
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                image: user.profileImage != null
                    ? DecorationImage(
                        image: NetworkImage(user.profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.profileImage == null
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // User Info
        Text(
          user.username,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 4),

        Text(
          user.email,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.displayRole,
            style: const TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm(UserModel user) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Profil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            enabled: _isEditing,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username harus diisi';
              }
              if (value.length < 3) {
                return 'Username minimal 3 karakter';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          EmailTextField(
            controller: _emailController,
            enabled: false, // Email tidak bisa diubah
          ),

          const SizedBox(height: 16),

          PhoneNumberInput(
            onChanged: (value) {
              _phoneController.text = value;
            },
            initialPhoneNumber: _phoneController.text,
          ),

          if (_isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Saya',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Ulasan', '${user.reviewCount}', Icons.reviews),
            _buildStatCard('Favorit', '${user.favoriteCount}', Icons.favorite),
            _buildStatCard('Reservasi', '12', Icons.event_available),
            _buildStatCard('Poin', '1,240', Icons.card_giftcard),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    return Column(
      children: [
        _buildActionTile('Riwayat Reservasi', Icons.history, () {
          // Navigate to reservation history
        }),

        _buildActionTile('Restoran Favorit', Icons.favorite_border, () {
          // Navigate to favorites
        }),

        _buildActionTile('Ulasan Saya', Icons.rate_review, () {
          // Navigate to my reviews
        }),

        _buildActionTile('Pengaturan Notifikasi', Icons.notifications_none, () {
          // Navigate to notification settings
        }),

        _buildActionTile('Bantuan & Dukungan', Icons.help_outline, () {
          // Navigate to help
        }),

        _buildActionTile('Tentang Aplikasi', Icons.info_outline, () {
          // Navigate to about
        }),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showLogoutDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Keluar'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _loadUserData(); // Reset to original values
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final updatedUser = authProvider.user!.copyWith(
          username: _usernameController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        );

        await userProvider.updateProfile(updatedUser);

        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }
}
