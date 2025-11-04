import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // ✅ SCREEN CONTROL
  var currentScreen = 0.obs; // 0 = Register Form, 1 = Profile Photo

  // ✅ ACCOUNT TYPE
  var userType = 'job_seeker'.obs; // Default: Ish qidiruvchi

  // ✅ PERSONAL INFO
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyNameController = TextEditingController();

  // ✅ CONTACT INFO
  final phoneController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // ✅ PROFILE PHOTO
  var profilePhotoPath = ''.obs;
  File? profilePhotoFile;

  var isPasswordHidden = true.obs;
  var isLoading = false.obs;

  // ✅ Telefon formatter
  final phoneFormatter = PhoneInputFormatter();

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void selectUserType(String type) {
    userType.value = type;
  }

  // ✅ Go to Profile Photo Screen
  void goToProfilePhotoScreen() {
    // Validation
    final phoneDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (userType.value == 'employer') {
      if (companyNameController.text.trim().isEmpty) {
        Get.snackbar(
          'Xato',
          'Kompaniya nomini kiriting',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }
    } else {
      if (firstNameController.text.trim().isEmpty ||
          lastNameController.text.trim().isEmpty) {
        Get.snackbar(
          'Xato',
          'Ism va familyangizni kiriting',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }
    }

    if (phoneDigits.length != 9) {
      Get.snackbar(
        'Xato',
        'Telefon raqam 9 ta raqamdan iborat bo\'lishi kerak',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (username.length < 3) {
      Get.snackbar(
        'Xato',
        'Username kamida 3 ta belgidan iborat bo\'lishi kerak',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar(
        'Xato',
        'Parol kamida 6 ta belgidan iborat bo\'lishi kerak',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    currentScreen.value = 1;
  }

  void goBackToForm() {
    currentScreen.value = 0;
  }

  // ✅ PROFILE PHOTO FUNCTIONS
  Future<void> pickProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        profilePhotoFile = File(image.path);
        profilePhotoPath.value = image.path;
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Rasm tanlanmadi: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        profilePhotoFile = File(image.path);
        profilePhotoPath.value = image.path;
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Rasm olinmadi: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ✅ UPLOAD PHOTO TO SUPABASE STORAGE
  Future<String?> uploadProfilePhoto(String userId) async {
    if (profilePhotoFile == null) return null;

    try {
      final fileExt = profilePhotoFile!.path.split('.').last;
      final filePath = '$userId.$fileExt';

      try {
        await supabase.storage.from('user-pictures').remove([filePath]);
      } catch (e) {
        // Ignore if file doesn't exist
      }

      await supabase.storage
          .from('user-pictures')
          .upload(
            filePath,
            profilePhotoFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = supabase.storage
          .from('user-pictures')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('❌ Photo upload error: $e');
      return null;
    }
  }

  // ✅ REGISTER USER
  Future<void> registerUser() async {
    final phoneDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phone = '+998$phoneDigits';
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();
    final type = userType.value;

    // Fake email yaratish
    final email =
        '${username}_${DateTime.now().millisecondsSinceEpoch}@jobhub.uz';

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
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 2️⃣ Telefon raqam bandligini tekshirish
      final existingPhone = await supabase
          .from('users')
          .select()
          .eq('phone_number', phone)
          .maybeSingle();

      if (existingPhone != null) {
        Get.snackbar(
          'Xato',
          'Bu telefon raqam allaqachon ro\'yxatdan o\'tgan',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 3️⃣ Supabase Auth orqali ro'yxatdan o'tish
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        Get.snackbar(
          'Xato',
          'Ro\'yxatdan o\'tishda muammo yuz berdi',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 4️⃣ Profile photo upload (agar tanlangan bo'lsa)
      String? photoUrl;
      if (profilePhotoFile != null) {
        photoUrl = await uploadProfilePhoto(user.id);
      }

      // 5️⃣ Ism/Kompaniya nomini aniqlash
      String firstName = '';
      String lastName = '';
      if (type == 'employer') {
        firstName = companyNameController.text.trim();
        lastName = '';
      } else {
        firstName = firstNameController.text.trim();
        lastName = lastNameController.text.trim();
      }

      // 6️⃣ "users" jadvaliga qo'shish
      await supabase.from('users').insert({
        'id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'phone_number': phone,
        'profile_photo_url': photoUrl,
        'user_type': type,
        'is_email_verified': false,
        'is_active': true,
        'rating': 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      Get.snackbar(
        'Muvaffaqiyatli',
        'Xush kelibsiz! Profilingizni to\'ldiring.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // ✅ TO'G'RIDAN-TO'G'RI PROFILE SAHIFASIGA
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/home'); // Yoki '/profile' bo'lishi mumkin
      clearForm();
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        Get.snackbar(
          'Xato',
          'Bu email allaqachon ro\'yxatdan o\'tgan',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Auth Xatosi',
          e.message,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        e.toString(),
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
    companyNameController.clear();
    phoneController.clear();
    passwordController.clear();
    usernameController.clear();
    userType.value = 'job_seeker';
    profilePhotoPath.value = '';
    profilePhotoFile = null;
    currentScreen.value = 0;
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    companyNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.onClose();
  }
}

// ✅ TELEFON FORMATTER CLASS
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    String digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 9) {
      digitsOnly = digitsOnly.substring(0, 9);
    }

    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
