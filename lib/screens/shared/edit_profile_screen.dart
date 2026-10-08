// screens/shared/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/theme.dart';
import '../../widgets/PhoneNumberInput.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isUploadingImage = false;
  String? _newProfileImageUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadUserData();
      _isInitialized = true;
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('User not found');
      }

      final newEmail = _emailController.text.trim();
      final emailChanged = user.email != newEmail;

      // Jika email berubah, JANGAN IZINKAN karena akan menyebabkan masalah login
      if (emailChanged) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maaf, email tidak bisa diubah. Silakan hubungi admin jika perlu mengubah email.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update data di Firestore
      final Map<String, dynamic> updateData = {
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Tambahkan profileImage jika ada yang baru
      if (_newProfileImageUrl != null) {
        updateData['profileImage'] = _newProfileImageUrl!;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update(updateData);

      // Update user di AuthProvider
      await authProvider.refreshUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving profile: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    Center(child: _buildProfilePicture(user)),
                    const SizedBox(height: 24),

                    // Role Badge
                    _buildRoleBadge(user),
                    const SizedBox(height: 24),

                    // Section Title
                    const Text(
                      'Informasi Akun',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username Field
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field (Read-only)
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Email tidak dapat diubah',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field dengan label
                    const Text(
                      'Nomor Telepon',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PhoneNumberInput(
                      onChanged: (value) {
                        _phoneController.text = value;
                      },
                      initialPhoneNumber: _phoneController.text,
                    ),
                    const SizedBox(height: 16),

                    // Conditional fields berdasarkan role
                    if (user.role == 'Pengguna' || user.role == 'Pemilik Resto') ...[
                      _buildTextField(
                        controller: _addressController,
                        label: 'Alamat',
                        icon: Icons.location_on,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Info tambahan untuk Admin
                    if (user.role == 'Admin') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akun Admin memiliki akses penuh ke sistem',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Info tambahan untuk Pemilik Resto
                    if (user.role == 'Pemilik Resto') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.restaurant, size: 16, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kelola restoran dan terima reservasi pelanggan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Info tambahan untuk Pengguna
                    if (user.role == 'Pengguna') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cari dan reservasi restoran favoritmu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePicture(UserModel user) {
    final profileImageUrl = _newProfileImageUrl ?? user.profileImage;

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryOrange.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: _isUploadingImage
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                      strokeWidth: 2,
                    ),
                  )
                : profileImageUrl != null && profileImageUrl.isNotEmpty
                ? Image.network(
                    profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.primaryOrange,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.primaryOrange,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  )
                : Icon(Icons.person, size: 60, color: AppColors.primaryOrange),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploadingImage ? null : _pickAndUploadProfileImage,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadProfileImage() async {
    // Show dialog untuk pilih sumber gambar
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryOrange,
                  ),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryOrange,
                  ),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload to Cloudinary
      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'profile_pictures',
      );

      if (uploadedUrl != null) {
        setState(() {
          _newProfileImageUrl = uploadedUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal upload foto profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? AppColors.primaryOrange : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(30),
            color: enabled ? Colors.white : Colors.grey[100],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            validator: validator,
            decoration: InputDecoration(
              hintText: enabled ? 'Isikan $label' : label,
              hintStyle: TextStyle(
                color: enabled ? Colors.grey : Colors.grey[500],
              ),
              prefixIcon: Icon(
                icon,
                color: enabled ? AppColors.primaryOrange : Colors.grey[400],
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              color: enabled ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(UserModel user) {
    Color roleColor;
    switch (user.role) {
      case 'Admin':
        roleColor = Colors.red;
        break;
      case 'Pemilik Resto':
        roleColor = Colors.blue;
        break;
      case 'Pengguna':
        roleColor = Colors.green;
        break;
      default:
        roleColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: roleColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Role Akun',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                user.displayRole,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
