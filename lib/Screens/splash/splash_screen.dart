import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _checkAndNavigate();
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

  // ✅ TO'G'RI NAVIGATION LOGIC
  Future<void> _checkAndNavigate() async {
    try {
      // Animation uchun kutish
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();

      // 1️⃣ Onboarding ko'rilganmi tekshirish
      final onboardingShown = prefs.getBool('onboarding_shown') ?? false;

      if (!onboardingShown) {
        // Birinchi marta - Onboarding ga o'tish
        print('📱 First time user - showing onboarding');
        Get.offAllNamed('/onboarding');
        return;
      }

      // 2️⃣ AuthController initialize
      await Get.putAsync<AuthController>(() async {
        return AuthController();
      });

      // 3️⃣ User logged in yoki yo'qligini tekshirish
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Logged in - Home ga o'tish
        print('✅ User logged in: ${user.email}');
        Get.offAllNamed('/home');
      } else {
        // Not logged in - Register ga o'tish
        print('❌ User not logged in - showing register');
        Get.offAllNamed('/register'); // ✅ REGISTER GA O'TADI
      }
    } catch (e) {
      print('Navigation error: $e');
      if (mounted) {
        // Error bo'lsa Register ga o'tish
        Get.offAllNamed('/register'); // ✅ REGISTER GA O'TADI
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
                        height: 120,
                        width: 120,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/Logotip/image.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Agar rasm topilmasa, default icon
                            return const Icon(
                              Icons.work_rounded,
                              size: 60,
                              color: AppConstants.primaryColor,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Imkon Job',
                        style: TextStyle(
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
