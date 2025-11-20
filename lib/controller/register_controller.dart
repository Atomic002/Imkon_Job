import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:version1/controller/auth_controller.dart';
import 'dart:io';

class RegisterController extends GetxController {
  final supabase = Supabase.instance.client;
  final storage = GetStorage();
  final ImagePicker _picker = ImagePicker();

  var currentScreen = 0.obs;
  var userType = 'job_seeker'.obs;
  var isPasswordHidden = true.obs;
  var isLoading = false.obs;
  var profilePhotoPath = ''.obs;
  File? profilePhotoFile;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final phoneController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final phoneFormatter = PhoneInputFormatter();

  /// ✅ REGISTER - Supabase Auth bilan
  Future<void> registerUser() async {
    final phoneDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phone = '+998$phoneDigits';
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();
    final type = userType.value;

    // Validatsiya
    if (password.length < 6) {
      _showError('Parol kamida 6 ta belgidan iborat bo\'lishi kerak');
      return;
    }

    if (phoneDigits.length != 9) {
      _showError('To\'g\'ri telefon raqam kiriting');
      return;
    }

    if (username.length < 3) {
      _showError('Username kamida 3 ta belgidan iborat bo\'lishi kerak');
      return;
    }

    String? authUserId;

    try {
      isLoading.value = true;

      print('📝 ===== REGISTRATION START =====');
      print('   Username: $username');
      print('   Phone: $phone');

      // ✅ 1️⃣ Database'da tekshirish
      final existingUsername = await supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        _showError('Bu username allaqachon ishlatilgan');
        isLoading.value = false;
        return;
      }

      final existingPhone = await supabase
          .from('users')
          .select('phone_number')
          .eq('phone_number', phone)
          .maybeSingle();

      if (existingPhone != null) {
        _showError('Bu telefon raqam allaqachon ro\'yxatdan o\'tgan');
        isLoading.value = false;
        return;
      }

      // ✅ 2️⃣ Ism/Kompaniya
      String firstName = '';
      String lastName = '';
      if (type == 'employer') {
        firstName = companyNameController.text.trim();
        if (firstName.isEmpty) {
          _showError('Kompaniya nomini kiriting');
          isLoading.value = false;
          return;
        }
      } else {
        firstName = firstNameController.text.trim();
        lastName = lastNameController.text.trim();
        if (firstName.isEmpty) {
          _showError('Ismingizni kiriting');
          isLoading.value = false;
          return;
        }
      }

      print('   FirstName: $firstName');

      // ✅ 3️⃣ Supabase Auth - Sign Up
      final email = '$username@app.local';
      print('📤 Creating auth user: $email');

      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Auth user yaratilmadi');
      }

      authUserId = authResponse.user!.id;
      print('✅ Auth user created: $authUserId');

      // ✅ 4️⃣ Database'ga yozish (UPDATE yoki INSERT)
      print('⏳ Waiting for trigger...');
      await Future.delayed(const Duration(seconds: 2));

      // Trigger yaratganini tekshirish
      var userExists = await supabase
          .from('users')
          .select('id')
          .eq('id', authUserId)
          .maybeSingle();

      final userData = {
        'username': username,
        'first_name': firstName,
        'last_name': type == 'employer'
            ? null
            : (lastName.isEmpty ? null : lastName),
        'phone_number': phone,
        'user_type': type,
        'is_active': true,
        'rating': 0.0,
      };

      if (userExists == null) {
        // INSERT
        print('📤 Inserting user...');
        await supabase.from('users').insert({'id': authUserId, ...userData});
        print('✅ User inserted');
      } else {
        // UPDATE
        print('📤 Updating user...');
        await supabase.from('users').update(userData).eq('id', authUserId);
        print('✅ User updated');
      }

      // ✅ 5️⃣ Verification
      final verifyUser = await supabase
          .from('users')
          .select('*')
          .eq('id', authUserId)
          .single();

      print('✅ User verified:');
      print('   Username: ${verifyUser['username']}');
      print('   FirstName: ${verifyUser['first_name']}');
      print('   Phone: ${verifyUser['phone_number']}');

      // ✅ 6️⃣ Upload photo
      if (profilePhotoFile != null) {
        print('📷 Uploading photo...');
        try {
          final photoUrl = await uploadProfilePhoto(authUserId);
          if (photoUrl != null) {
            await supabase
                .from('users')
                .update({'profile_photo_url': photoUrl})
                .eq('id', authUserId);
            print('✅ Photo uploaded');
          }
        } catch (e) {
          print('⚠️ Photo upload failed: $e');
        }
      }

      // ✅ 7️⃣ Storage'ga saqlash
      print('💾 Saving to storage...');
      await storage.write('userId', authUserId);
      await storage.write('isLoggedIn', true);
      await storage.write('username', username);
      await storage.write('userType', type);

      // ✅ 8️⃣ AuthController'ni yangilash
      try {
        final authController = Get.find<AuthController>();
        await authController.refreshUser();
        print('✅ AuthController refreshed');
      } catch (e) {
        print('⚠️ AuthController not found: $e');
      }

      print('✅ ===== REGISTRATION COMPLETE =====');

      _showSuccess('Xush kelibsiz, $firstName!');

      // ✅ FIX: clearForm() ni OLDIN chaqiring
      _clearFormSafely();

      // KEYIN screen'ga o'ting
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/home');
    } catch (e, stackTrace) {
      print('❌ ===== REGISTRATION ERROR =====');
      print('   Error: $e');
      print('   Stack: $stackTrace');

      // Rollback
      if (authUserId != null) {
        print('🔄 Rolling back...');
        try {
          await supabase.auth.signOut();
          print('✅ Auth user logged out');
        } catch (rollbackError) {
          print('❌ Rollback error: $rollbackError');
        }
      }

      String errorMessage = e.toString();

      if (errorMessage.contains('User already registered')) {
        errorMessage = 'Bu username allaqachon ro\'yxatdan o\'tgan';
      } else if (errorMessage.contains('password')) {
        errorMessage = 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
      }

      _showError(errorMessage);
    } finally {
      isLoading.value = false;
    }
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

  /// ✅ Xavfsiz tozalash (controller dispose bo'lmagan bo'lsa)
  void _clearFormSafely() {
    try {
      // ignore: invalid_use_of_protected_member
      if (firstNameController.hasListeners) {
        firstNameController.clear();
        lastNameController.clear();
        companyNameController.clear();
        phoneController.clear();
        passwordController.clear();
        usernameController.clear();
      }
      userType.value = 'job_seeker';
      profilePhotoPath.value = '';
      profilePhotoFile = null;
      currentScreen.value = 0;
    } catch (e) {
      print('⚠️ Clear form error (ignored): $e');
    }
  }

  /// Public clearForm (agar boshqa joyda kerak bo'lsa)
  void clearForm() => _clearFormSafely();

  Future<String?> uploadProfilePhoto(String userId) async {
    if (profilePhotoFile == null) return null;

    try {
      final fileExt = profilePhotoFile!.path.split('.').last;
      final fileName = '$userId.$fileExt';

      try {
        await supabase.storage.from('user-pictures').remove([fileName]);
      } catch (e) {}

      await supabase.storage
          .from('user-pictures')
          .upload(
            fileName,
            profilePhotoFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      return supabase.storage.from('user-pictures').getPublicUrl(fileName);
    } catch (e) {
      print('❌ Photo upload error: $e');
      return null;
    }
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void selectUserType(String type) {
    userType.value = type;
  }

  void goToProfilePhotoScreen() {
    currentScreen.value = 1;
  }

  void goBackToForm() {
    currentScreen.value = 0;
  }

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
      _showError('Rasm tanlanmadi');
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
      _showError('Rasm olinmadi');
    }
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
