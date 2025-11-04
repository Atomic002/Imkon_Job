import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:version1/controller/register_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());

    return Scaffold(
      body: Obx(() {
        if (controller.currentScreen.value == 0) {
          return const RegisterFormScreen();
        } else {
          return const ProfilePhotoScreen();
        }
      }),
    );
  }
}

// ==================== SCREEN 1: REGISTER FORM ====================
class RegisterFormScreen extends StatelessWidget {
  const RegisterFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ✅ LOGO
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ TITLE
              const Center(
                child: Text(
                  'Ro\'yxatdan o\'tish',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1F36),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Akkountingizni yarating',
                  style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 30),

              // ✅ USER TYPE TABS
              Obx(
                () => Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTypeTab(
                          'Ish qidiruvchi',
                          Icons.person_search_rounded,
                          controller.userType.value == 'job_seeker',
                          () => controller.selectUserType('job_seeker'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildTypeTab(
                          'Ish beruvchi',
                          Icons.business_rounded,
                          controller.userType.value == 'employer',
                          () => controller.selectUserType('employer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ✅ PERSONAL INFO
              Obx(() {
                if (controller.userType.value == 'employer') {
                  return _buildTextField(
                    controller: controller.companyNameController,
                    label: 'Kompaniya nomi',
                    hint: 'Masalan: IT Solutions LLC',
                    icon: Icons.business_outlined,
                  );
                } else {
                  return Column(
                    children: [
                      _buildTextField(
                        controller: controller.firstNameController,
                        label: 'Ism',
                        hint: 'Masalan: Jahongir',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: controller.lastNameController,
                        label: 'Familya',
                        hint: 'Masalan: Xolmatov',
                        icon: Icons.person_outline_rounded,
                      ),
                    ],
                  );
                }
              }),
              const SizedBox(height: 16),

              // ✅ PHONE NUMBER
              _buildPhoneField(controller),
              const SizedBox(height: 16),

              // ✅ USERNAME
              _buildTextField(
                controller: controller.usernameController,
                label: 'Username',
                hint: 'Masalan: jahongir_dev',
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 16),

              // ✅ PASSWORD
              Obx(
                () => _buildTextField(
                  controller: controller.passwordController,
                  label: 'Parol (kamida 6 ta belgi)',
                  hint: '••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: controller.isPasswordHidden.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF6B7280),
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ✅ CONTINUE BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.goToProfilePhotoScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Davom etish',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ LOGIN LINK
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Akkauntingiz bormi?',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => Get.toNamed('/login'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Kirish',
                        style: TextStyle(
                          color: Colors.indigo.shade600,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.indigo.shade600
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.indigo.shade600
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: Icon(icon, color: Colors.indigo.shade400),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(RegisterController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Telefon raqam',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.phoneController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            controller.phoneFormatter,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: InputDecoration(
            hintText: '90 123 45 67',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_outlined, color: Colors.indigo.shade400),
                  const SizedBox(width: 8),
                  const Text(
                    '+998',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== SCREEN 2: PROFILE PHOTO ====================
class ProfilePhotoScreen extends StatelessWidget {
  const ProfilePhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
          onPressed: controller.goBackToForm,
        ),
        title: const Text(
          'Profil rasmi',
          style: TextStyle(
            color: Color(0xFF1A1F36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Profil rasmingizni qo\'shing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rasm qo\'shish ixtiyoriy, keyinroq ham qo\'shishingiz mumkin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              const Spacer(),

              // ✅ PHOTO PREVIEW
              Obx(() {
                return GestureDetector(
                  onTap: controller.pickProfilePhoto,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade100,
                          Colors.purple.shade100,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: controller.profilePhotoPath.value.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                size: 50,
                                color: Colors.indigo.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Rasm qo\'shish',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade600,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.file(
                              File(controller.profilePhotoPath.value),
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                            ),
                          ),
                  ),
                );
              }),

              const SizedBox(height: 30),

              // ✅ PHOTO OPTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPhotoOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: controller.takePhoto,
                  ),
                  const SizedBox(width: 20),
                  _buildPhotoOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galereya',
                    onTap: controller.pickProfilePhoto,
                  ),
                ],
              ),

              const Spacer(),

              // ✅ FINISH BUTTON
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Tugatish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ SKIP BUTTON
              TextButton(
                onPressed: controller.registerUser,
                child: Text(
                  'Keyinroq qo\'shaman',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.indigo.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo.shade600, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
