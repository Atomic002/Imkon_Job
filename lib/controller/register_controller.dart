import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var currentStep = 0.obs;
  final pageController = PageController();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();

  var isPasswordHidden = true.obs;
  var userType = ''.obs;
  var isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void selectUserType(String type) {
    userType.value = type;
  }

  void nextStep() {
    if (currentStep.value < 3) {
      currentStep.value++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final username = usernameController.text.trim();
    final bio = bioController.text.trim();
    final type = userType.value;

    // ✅ VALIDATION
    if (email.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        type.isEmpty) {
      Get.snackbar(
        'Xato',
        'Iltimos, barcha maydonlarni to\'ldiring',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Email format tekshirish
    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Xato',
        'To\'g\'ri email kiriting',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Parol uzunligi
    if (password.length < 6) {
      Get.snackbar(
        'Xato',
        'Parol kamida 6 ta belgidan iborat bo\'lishi kerak',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Username uzunligi
    if (username.length < 3) {
      Get.snackbar(
        'Xato',
        'Username kamida 3 ta belgidan iborat bo\'lishi kerak',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // 1️⃣ Username bandligini tekshirish
      final existingUsername = await supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        Get.snackbar(
          'Xato',
          'Bu username allaqachon ishlatilgan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      // 2️⃣ Supabase Auth orqali ro'yxatdan o'tish (EMAIL TEKSHIRISH BURADA BO'LADI)
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        Get.snackbar(
          'Xato',
          'Ro\'yxatdan o\'tishda muammo yuz berdi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      // 4️⃣ "users" jadvaliga qo'shish
      await supabase.from('users').insert({
        'id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'bio': bio,
        'user_type': type == 'individual' ? 'job_seeker' : 'employer',
        'is_email_verified': false,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      Get.snackbar(
        'Muvaffaqiyatli',
        'Ro\'yxatdan o\'tish yakunlandi! Login qiling.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // ✅ Login sahifasiga o'tish
      Get.offAllNamed('/login');
      clearForm();
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        Get.snackbar(
          'Xato',
          'Bu email allaqachon ro\'yxatdan o\'tgan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Auth Xatosi',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } on PostgrestException catch (e) {
      Get.snackbar(
        'Database Xatosi',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Xato',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    passwordController.clear();
    usernameController.clear();
    bioController.clear();
    userType.value = '';
    currentStep.value = 0;
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    bioController.dispose();
    pageController.dispose();
    super.onClose();
  }
}
