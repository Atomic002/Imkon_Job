import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/controller/auth_controller.dart';
import '../../config/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkAuthAndNavigate();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  // ✅ AUTH CHECK va NAVIGATION
  Future<void> _checkAuthAndNavigate() async {
    try {
      // ✅ AuthController initialize qilish
      await Get.putAsync<AuthController>(() async {
        return AuthController();
      });

      // ✅ User logged in yoki yo'qligini tekshirish
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // Animation uchun 2 soniya kutish
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (user != null) {
        // ✅ Login qilgan - Home ga o'tish
        print('✅ User logged in: ${user.email}');
        Get.offAllNamed('/home');
      } else {
        // ✅ Login qilmagan - Onboarding ga o'tish
        print('❌ User not logged in');
        Get.offAllNamed('/onboarding');
      }
    } catch (e) {
      print('Auth check error: $e');
      // Error bo'lsa Onboarding ga o'tish
      if (mounted) {
        Get.offAllNamed('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.primaryGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.work_rounded,
                          size: 80,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'JobHub',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ish topish oson bo\'ldi!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
