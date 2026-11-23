import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_home_screen.dart';
import '../auth/login_screen.dart';
import '../owner/owner_home_screen.dart';
import '../user/home_screen.dart';
import 'splash_screen.dart';

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _openLandingPage();
  }

  Future<void> _openLandingPage() async {
    try {
      final user = await context.read<AuthProvider>().restoreSession();
      if (!mounted) return;

      final destination = user == null
          ? const SplashScreen()
          : _homeForRole(user.role);

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Widget _homeForRole(String role) {
    switch (role) {
      case 'Pengguna':
        return const HomeScreen();
      case 'Pemilik Resto':
        return const OwnerHomeScreen();
      case 'Admin':
        return const AdminHomeScreen();
      default:
        throw StateError('Role akun tidak valid: $role');
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      body: Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sesi tidak dapat dipulihkan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _openLandingPage();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Ke Halaman Login'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
