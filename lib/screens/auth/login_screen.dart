import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../user/home_screen.dart';
import '../owner/owner_home_screen.dart';
import '../admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Pengguna'; // Default role

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    // Detect if this is a suspension/rejection message
    final isSuspension = message.contains('ditolak') || 
                        message.contains('dinonaktifkan') ||
                        message.contains('ditangguhkan');
    
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa dismiss dengan tap di luar
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                isSuspension ? Icons.block : Icons.error_outline,
                size: 60,
                color: isSuspension ? Colors.red : AppColors.primaryOrange,
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSuspension ? Colors.red[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSuspension ? Colors.red[900] : AppColors.primaryOrange,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Contact info untuk suspension
              if (isSuspension) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Butuh Bantuan?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hubungi admin di:\nadmin@nyammakan.com',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuspension ? Colors.red : AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final requestedRole = _selectedRole;

      print('🔄 Attempting login with: ${_usernameController.text}');

      await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        requestedRole,
      );

      // Debug: Check auth state
      print(
        '🔍 After login - isAuthenticated: ${authProvider.isAuthenticated}',
      );
      print('🔍 After login - user: ${authProvider.user?.username}');
      print('🔍 After login - user role: ${authProvider.user?.role}');

      // Gunakan role dari provider yang sudah di-load
      final actualRole = authProvider.user?.role;

      if (actualRole == 'Pengguna') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (actualRole == 'Pemilik Resto') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerHomeScreen()),
        );
      } else if (actualRole == 'Admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else {
        print('❌ Unknown role: $actualRole');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      setState(() {
        _isLoading = false;
      });

      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      _showErrorDialog('Login Gagal', errorMessage);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.signInWithGoogle(_selectedRole);

      final user = authProvider.user;
      if (user != null) {
        // Auto-fill form dengan data user dari Firestore
        _usernameController.text = user.username;
        _passwordController.text = '••••••••'; // Placeholder password

        // Set role dropdown sesuai role user
        if (user.role == 'Pengguna') {
          _selectedRole = 'Pengguna';
        } else if (user.role == 'Pemilik Resto') {
          _selectedRole = 'Pemilik Resto';
        } else if (user.role == 'Admin') {
          _selectedRole = 'Admin';
        }

        // Show filled form briefly (500ms)
        setState(() {
          _isLoading = false;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        // Show loading again
        setState(() {
          _isLoading = true;
        });

        await Future.delayed(const Duration(milliseconds: 800));

        // Navigate based on role
        final actualRole = user.role;
        if (actualRole == 'Pengguna') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (actualRole == 'Pemilik Resto') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OwnerHomeScreen()),
          );
        } else if (actualRole == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      print('❌ Google Login error: $e');
      setState(() {
        _isLoading = false;
      });

      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      _showErrorDialog('Google Login Gagal', errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryOrange,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo_cream.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 30),

                // White Card with Form
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Orange Line
                        Container(
                          width: 50,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hello Text
                        Text(
                          'Hello!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppColors.primaryOrange,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Login as Dropdown
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryOrange,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              hintText: 'Login as',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primaryOrange,
                            ),
                            dropdownColor: Colors.white,
                            items: [
                              DropdownMenuItem(
                                value: 'Pengguna',
                                child: Text(
                                  'Pengguna',
                                  style: TextStyle(
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Pemilik Resto',
                                child: Text(
                                  'Pemilik Resto',
                                  style: TextStyle(
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Admin',
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppColors.primaryOrange,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.primaryOrange,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 4),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
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
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Login with Google Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            icon: Image.network(
                              'https://www.google.com/favicon.ico',
                              height: 20,
                              width: 20,
                            ),
                            label: Text(
                              'Login with Google',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have account? ",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Text(
                              ' now',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
