import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;

  final supabase = Supabase.instance.client;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Xato',
        'Iltimos, barcha maydonlarni to\'ldiring',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // 1️⃣ Username orqali email topamiz
      final userResponse = await supabase
          .from('users')
          .select('id, email, is_active')
          .eq('username', username)
          .maybeSingle();

      if (userResponse == null) {
        Get.snackbar(
          'Xato',
          'Bunday foydalanuvchi topilmadi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 2️⃣ Akkaunt active ekanligini tekshirish
      if (userResponse['is_active'] == false) {
        Get.snackbar(
          'Xato',
          'Bu akkaunt bloklangan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 3️⃣ Email va parol orqali Supabase Auth ga kirish
      final email = userResponse['email'];
      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        Get.snackbar(
          'Muvaffaqiyatli',
          'Akkauntga kiirdingiz!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // ✅ Clear fields
        usernameController.clear();
        passwordController.clear();

        // ✅ Home sahifasiga o'tish
        Get.offAllNamed('/home');
      }
    } on AuthException catch (e) {
      String errorMessage = 'Auth xatosi yuz berdi';

      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Email yoki parol noto\'g\'ri';
      } else if (e.message.contains('User not found')) {
        errorMessage = 'Bunday foydalanuvchi topilmadi';
      } else {
        errorMessage = e.message;
      }

      Get.snackbar(
        'Xato',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Tizimda muammo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await supabase.auth.signOut();
      usernameController.clear();
      passwordController.clear();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Chiqishda muammo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Joriy user ma'lumotlarini olish
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Xato: $e');
      return null;
    }
  }

  // ✅ User session tekshirish
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void changePassword(String text) {}
}
