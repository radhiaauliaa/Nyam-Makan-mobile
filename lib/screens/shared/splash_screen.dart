// screens/shared/splash_screen.dart
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _orangeSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo fade animation (transisi logo orange ke cream)
    _logoFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Orange slide animation (slide dari kanan ke kiri)
    _orangeSlideAnimation =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
          ),
        );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Tunggu sebentar dengan logo orange di background putih
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Mulai animasi slide orange
    _controller.forward();

    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Navigate ke login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Background putih
              Container(color: Colors.white),

              // Orange slide dari bawah
              SlideTransition(
                position: _orangeSlideAnimation,
                child: Container(
                  color: const Color(0xFFDF5500),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                ),
              ),

              // Logo dan tagline
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo dengan transisi opacity
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Logo orange (fade out)
                        Opacity(
                          opacity: _logoFadeAnimation.value,
                          child: Image.asset(
                            'assets/nyam_makaan.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Logo cream (fade in)
                        Opacity(
                          opacity: 1.0 - _logoFadeAnimation.value,
                          child: Image.asset(
                            'assets/logo_cream.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Tagline dengan warna dinamis
                    Text(
                      'Temukan makanan dan resto',
                      style: TextStyle(
                        fontSize: 16,
                        color: _controller.value > 0.5
                            ? Colors.white
                            : const Color(0xFFDF5500),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'enak disekitar mu yuk!',
                      style: TextStyle(
                        fontSize: 16,
                        color: _controller.value > 0.5
                            ? Colors.white
                            : const Color(0xFFDF5500),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
