import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  Future<void> _completeRegistration() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateUserRole(_selectedRole!);

      // Navigate based on selected role
      switch (_selectedRole) {
        case 'Pengguna':
          Navigator.pushReplacementNamed(context, '/user-home');
          break;
        case 'Pemilik Resto':
          Navigator.pushReplacementNamed(context, '/owner-home');
          break;
        case 'Admin':
          Navigator.pushReplacementNamed(context, '/admin-home');
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing registration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan waktu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '9:41',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Choose how you want to use Nyam! Makaan',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              const SizedBox(height: 40),

              // Role Selection Cards
              Expanded(
                child: Column(
                  children: [
                    // User Role Card
                    _buildRoleCard(
                      title: 'Pengguna',
                      subtitle:
                          'Browse restaurants, make reservations, and write reviews',
                      icon: Icons.person_outline,
                      isSelected: _selectedRole == 'Pengguna',
                      onTap: () {
                        setState(() {
                          _selectedRole = 'Pengguna';
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Restaurant Owner Role Card
                    _buildRoleCard(
                      title: 'Pemilik Resto',
                      subtitle:
                          'Manage your restaurant, menus, and reservations',
                      icon: Icons.restaurant_outlined,
                      isSelected: _selectedRole == 'Pemilik Resto',
                      onTap: () {
                        setState(() {
                          _selectedRole = 'Pemilik Resto';
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Admin Role Card
                    _buildRoleCard(
                      title: 'Admin',
                      subtitle:
                          'Manage platform content and verify restaurants',
                      icon: Icons.admin_panel_settings_outlined,
                      isSelected: _selectedRole == 'Admin',
                      onTap: () {
                        setState(() {
                          _selectedRole = 'Admin';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip for now
              Center(
                child: TextButton(
                  onPressed: () {
                    // Set default role as User and continue
                    setState(() {
                      _selectedRole = 'Pengguna';
                    });
                    _completeRegistration();
                  },
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkmark for selected role
              if (isSelected)
                Icon(Icons.check_circle, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
