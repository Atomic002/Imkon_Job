import 'package:flutter/material.dart';
import 'package:flutter_application_2/Models/user_model.dart';
import 'package:flutter_application_2/Services/connective_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final phoneController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final loginType = 'phone'.obs;
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;

  final supabase = Supabase.instance.client;
  final storage = GetStorage();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _checkSession();
  }

  /// ✅ Session tekshirish - FAQAT INTERNET BO'LGANDA
  Future<void> _checkSession() async {
    try {
      print('🔍 ===== SESSION CHECK START =====');

      await Future.delayed(const Duration(milliseconds: 100));

      // 🌐 INTERNET TEKSHIRISH (xavfsiz)
      final connectivityService = Get.isRegistered<ConnectivityService>()
          ? Get.find<ConnectivityService>()
          : null;

      if (connectivityService == null) {
        print('⚠️ ConnectivityService not ready - waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
        return _checkSession(); // Retry
      }

      if (!connectivityService.isConnected.value) {
        print('⚠️ No internet - skipping auth check');
        print('📱 Will check when internet is available');

        // ✅ Internet qaytganda tekshirish
        ever(connectivityService.isConnected, (isConnected) {
          if (isConnected) {
            print('✅ Internet restored - checking session...');
            _checkSession();
          }
        });

        return;
      }

      // ✅ Supabase session tekshirish
      final session = supabase.auth.currentSession;
      print('   Session: ${session?.user.id}');

      if (session != null) {
        final userId = session.user.id;
        print('✅ Active session found: $userId');

        // User ma'lumotlarini yuklash
        await _loadUser(userId);

        if (currentUser.value?.isActive == true) {
          print('✅ User active: ${currentUser.value?.username}');

          // Storage'ga saqlash
          await storage.write('userId', userId);
          await storage.write('isLoggedIn', true);
          await storage.write('username', currentUser.value?.username);
          await storage.write('userType', currentUser.value?.userType);

          // Home'ga o'tish
          if (Get.currentRoute == '/login' || Get.currentRoute == '/') {
            await Future.delayed(const Duration(milliseconds: 300));
            Get.offAllNamed('/home');
          }
        } else {
          print('❌ User not active, logging out');
          await logout();
        }
      } else {
        print('❌ No active session');
        await storage.write('isLoggedIn', false);
        await storage.remove('userId');
      }
    } catch (e) {
      print('❌ Session check error: $e');

      // ✅ Internet xatosi bo'lsa, logout QILMAYDI
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        print('⚠️ Network error - keeping session');
        return;
      }

      // Boshqa xatolar uchun logout
      await logout();
    }
  }

  /// ✅ User ma'lumotlarini yuklash
  Future<void> _loadUser(String userId) async {
    try {
      print('📥 Loading user: $userId');

      // 🌐 Internet tekshirish (xavfsiz)
      final connectivityService = Get.isRegistered<ConnectivityService>()
          ? Get.find<ConnectivityService>()
          : null;

      if (connectivityService != null &&
          !connectivityService.isConnected.value) {
        print('⚠️ No internet - cannot load user data');
        throw Exception('No internet connection');
      }

      final userData = await supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      currentUser.value = UserModel.fromJson(userData);

      print('✅ User loaded:');
      print('   Username: ${currentUser.value?.username}');
      print('   FirstName: ${currentUser.value?.firstName}');
      print('   Phone: ${currentUser.value?.phoneNumber}');
    } catch (e) {
      print('❌ Load user error: $e');

      // ✅ Faqat internet xatosi bo'lsa, logout QILMAYDI
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('No internet connection')) {
        print('⚠️ Network error - will retry when online');
        return;
      }

      // Boshqa xatolar uchun logout
      await logout();
    }
  }

  void setLoginType(String type) {
    loginType.value = type;
    phoneController.clear();
    usernameController.clear();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  /// ✅ LOGIN - Supabase Auth bilan
  Future<void> login() async {
    // 🌐 Internet tekshirish (xavfsiz)
    final connectivityService = Get.isRegistered<ConnectivityService>()
        ? Get.find<ConnectivityService>()
        : null;

    if (connectivityService != null && !connectivityService.isConnected.value) {
      _showError('Internet yo\'q. Iltimos, internetga ulaning');
      return;
    }

    late final password = passwordController.text.trim();

    String identifier = '';
    if (loginType.value == 'phone') {
      final cleanPhone = phoneController.text.replaceAll(' ', '');
      if (cleanPhone.length != 9) {
        _showError('To\'liq telefon raqamni kiriting');
        return;
      }
      identifier = '+998$cleanPhone';
    } else {
      identifier = usernameController.text.trim();
    }

    if (identifier.isEmpty || password.isEmpty) {
      _showError('Iltimos, barcha maydonlarni to\'ldiring');
      return;
    }

    try {
      isLoading.value = true;
      print('🔐 ===== LOGIN START =====');

      // 1️⃣ Database'dan username topish
      final userQuery = supabase.from('users').select('*');

      final userResponse = loginType.value == 'phone'
          ? await userQuery.eq('phone_number', identifier).maybeSingle()
          : await userQuery.eq('username', identifier).maybeSingle();

      if (userResponse == null) {
        _showError(
          loginType.value == 'phone'
              ? 'Bu telefon raqam topilmadi'
              : 'Bu username topilmadi',
        );
        return;
      }

      print('📦 User found: ${userResponse['username']}');

      if (userResponse['is_active'] == false) {
        _showError('Bu akkaunt bloklangan');
        return;
      }

      // 2️⃣ Supabase Auth orqali login
      final email = '${userResponse['username']}@app.local';

      print('   Logging in: $email');

      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        _showError('Login xatosi');
        return;
      }

      final userId = authResponse.user!.id;
      print('✅ Login successful: $userId');

      // 3️⃣ User ma'lumotlarini saqlash
      currentUser.value = UserModel.fromJson(userResponse);

      // 4️⃣ Storage'ga saqlash
      await storage.write('userId', userId);
      await storage.write('isLoggedIn', true);
      await storage.write('username', currentUser.value?.username);
      await storage.write('userType', currentUser.value?.userType);

      print('💾 Saved to storage');

      _showSuccess(
        'Xush kelibsiz, ${currentUser.value?.firstName ?? currentUser.value?.username}!',
      );

      _clearFields();

      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAllNamed('/home');
    } catch (e) {
      print('❌ Login error: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        _showError('Internet bilan bog\'lanishda xatolik');
      } else if (e.toString().contains('Invalid login credentials')) {
        _showError('Username yoki parol noto\'g\'ri');
      } else {
        _showError('Login xatosi: ${e.toString()}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ LOGOUT - Supabase Auth
  Future<void> logout() async {
    try {
      isLoading.value = true;
      print('👋 ===== LOGOUT START =====');

      // 🌐 Internet bo'lsa Supabase'dan logout (xavfsiz)
      final connectivityService = Get.isRegistered<ConnectivityService>()
          ? Get.find<ConnectivityService>()
          : null;

      if (connectivityService != null &&
          connectivityService.isConnected.value) {
        await supabase.auth.signOut();
        print('✅ Supabase logout successful');
      } else {
        print('⚠️ No internet - local logout only');
      }

      // Local storage tozalash (har doim)
      await storage.remove('userId');
      await storage.remove('username');
      await storage.remove('userType');
      await storage.write('isLoggedIn', false);

      currentUser.value = null;
      _clearFields();

      print('✅ Logout successful');
      Get.offAllNamed('/login');
    } catch (e) {
      print('❌ Logout error: $e');

      // Xato bo'lsa ham local data tozalash
      await storage.erase();
      currentUser.value = null;
      Get.offAllNamed('/login');
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFields() {
    phoneController.clear();
    usernameController.clear();
    passwordController.clear();
  }

  void _showError(String message) {
    Get.snackbar(
      'Xato',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Muvaffaqiyatli',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  // ✅ Getter metodlar
  UserModel? getCurrentUser() => currentUser.value;

  String? getCurrentUserId() {
    final sessionUserId = supabase.auth.currentUser?.id;
    if (sessionUserId != null) return sessionUserId;

    if (currentUser.value?.id != null) return currentUser.value!.id;

    return storage.read('userId');
  }

  bool isLoggedIn() {
    return supabase.auth.currentSession != null;
  }

  Future<void> refreshUser() async {
    // 🌐 Internet tekshirish (xavfsiz)
    final connectivityService = Get.isRegistered<ConnectivityService>()
        ? Get.find<ConnectivityService>()
        : null;

    if (connectivityService != null && !connectivityService.isConnected.value) {
      print('⚠️ No internet - cannot refresh user');
      _showError('Internet yo\'q');
      return;
    }

    final userId = getCurrentUserId();
    if (userId != null) {
      await _loadUser(userId);
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
