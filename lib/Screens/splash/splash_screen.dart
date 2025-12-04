import 'package:flutter/material.dart';
import 'package:flutter_application_2/Services/connective_service.dart';
import 'package:flutter_application_2/controller/auth_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _hasNavigated = false;
  Worker? _connectivityWorker; // ✅ Worker to'g'ri dispose qilish uchun

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeApp();
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

  /// ✅ ASOSIY INITIALIZATION
  Future<void> _initializeApp() async {
    try {
      print('🚀 ===== SPLASH START =====');

      // 1️⃣ Minimum splash time (animation uchun)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // 2️⃣ ConnectivityService tekshirish
      if (!Get.isRegistered<ConnectivityService>()) {
        print('⚠️ ConnectivityService not found - waiting...');
        await Future.delayed(const Duration(milliseconds: 500));

        if (!Get.isRegistered<ConnectivityService>()) {
          print('❌ ConnectivityService still not available');
          _navigateToRegister();
          return;
        }
      }

      final connectivityService = Get.find<ConnectivityService>();
      print('✅ ConnectivityService found');

      // 3️⃣ Internet bor yoki yo'qligini tekshirish
      if (connectivityService.isConnected.value) {
        print('✅ Internet available - proceeding...');
        await _proceedToNextScreen();
      } else {
        print('⚠️ No internet - waiting for connection...');
        _waitForInternet(connectivityService);
      }
    } catch (e, stackTrace) {
      print('❌ Splash initialization error: $e');
      print('StackTrace: $stackTrace');

      if (mounted && !_hasNavigated) {
        _navigateToRegister();
      }
    }
  }

  /// ✅ Internet kutish (faqat bir marta navigate)
  void _waitForInternet(ConnectivityService connectivityService) {
    if (_hasNavigated) return;

    _connectivityWorker = ever(connectivityService.isConnected, (isConnected) {
      if (isConnected && !_hasNavigated && mounted) {
        print('✅ Internet restored - proceeding...');
        _connectivityWorker?.dispose(); // ✅ Worker'ni to'xtatish
        _proceedToNextScreen();
      }
    });
  }

  /// ✅ Keyingi screen'ga o'tish
  Future<void> _proceedToNextScreen() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    try {
      print('📱 Checking navigation route...');

      // 1️⃣ ONBOARDING TEKSHIRISH
      final prefs = await SharedPreferences.getInstance();
      final onboardingShown = prefs.getBool('onboarding_shown') ?? false;

      if (!onboardingShown) {
        print('📱 First launch - showing onboarding');
        _navigateToOnboarding();
        return;
      }

      // 2️⃣ AuthController'ni init qilish (agar hali init qilinmagan bo'lsa)
      if (!Get.isRegistered<AuthController>()) {
        print('🔐 Initializing AuthController...');
        Get.put(AuthController()); // ✅ Oddiy put (async emas!)
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // 3️⃣ AUTH TEKSHIRISH
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session != null) {
        final userId = session.user.id;
        print('✅ Active session found: $userId');

        // User active ekanligini tekshirish
        try {
          final userData = await supabase
              .from('users')
              .select('is_active')
              .eq('id', userId)
              .single();

          if (userData['is_active'] == true) {
            print('✅ User is active - navigating to home');
            _navigateToHome();
          } else {
            print('⚠️ User is inactive - logging out');
            await supabase.auth.signOut();
            _navigateToRegister();
          }
        } catch (e) {
          print('⚠️ User check error: $e');
          _navigateToHome(); // Xato bo'lsa ham home'ga o'tish
        }
      } else {
        print('❌ No active session - showing register');
        _navigateToRegister();
      }
    } catch (e, stackTrace) {
      print('❌ Navigation error: $e');
      print('StackTrace: $stackTrace');

      if (mounted && !_hasNavigated) {
        _navigateToRegister();
      }
    }
  }

  /// ✅ Navigation metodlari
  void _navigateToOnboarding() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Get.offAllNamed('/onboarding');
      }
    });
  }

  void _navigateToHome() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Get.offAllNamed('/home');
      }
    });
  }

  void _navigateToRegister() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Get.offAllNamed('/register');
      }
    });
  }

  @override
  void dispose() {
    _connectivityWorker?.dispose(); // ✅ Worker'ni tozalash
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
                      // Logo
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
                            return const Icon(
                              Icons.work_rounded,
                              size: 60,
                              color: AppConstants.primaryColor,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      // App name
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

                      // Tagline
                      const Text(
                        'Ish topish oson bo\'ldi!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Loading indicator
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Status text
                      Obx(() {
                        final connectivityService =
                            Get.find<ConnectivityService>();

                        return Text(
                          connectivityService.isConnected.value
                              ? 'Yuklanmoqda...'
                              : 'Internet kutilmoqda...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        );
                      }),
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
