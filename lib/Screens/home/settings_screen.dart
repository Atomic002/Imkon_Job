import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:version1/config/constants.dart';
import 'package:version1/controller/auth_controller.dart';
import 'package:version1/controller/language_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Controllers olamiz (GetX yordamida)
    final authController = Get.find<AuthController>();
    final languageController = Get.find<LanguageController>();

    return Scaffold(
      // ✅ Top AppBar
      appBar: AppBar(
        title: Text('settings'.tr),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
      ),

      // ✅ Body - Scroll qiladigan list
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          // ==================== ACCOUNT SETTINGS ====================
          _buildSectionTitle('account_settings'.tr),

          // Change Password
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'change_password'.tr,
            onTap: () => _showChangePasswordDialog(context),
          ),

          // Edit Profile
          _buildSettingItem(
            icon: Icons.edit_outlined,
            title: 'edit_profile'.tr,
            onTap: () => Get.toNamed('/edit_profile'),
          ),

          const SizedBox(height: 24),

          // ==================== LANGUAGE SETTINGS ====================
          _buildSectionTitle('language_settings'.tr),

          // ✅ Obx - reaktiv, til o'zgarganda qayta rebuild bo'ladi
          Obx(
            () => Column(
              children: languageController.languages.map((lang) {
                return _buildLanguageItem(
                  flag: lang['flag'] as String,
                  name: lang['name'] as String,
                  code: lang['code'] as String,
                  isSelected:
                      languageController.selectedLanguage.value == lang['code'],
                  onTap: () =>
                      languageController.changeLanguage(lang['code'] as String),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ==================== APP SETTINGS ====================
          _buildSectionTitle('app_settings'.tr),

          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'notifications'.tr,
            onTap: () {
              Get.snackbar(
                'Bildirishnomalar',
                'Bildirishnomalar sozlamalari hozircha mavjud emas',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),

          const SizedBox(height: 24),

          // ==================== OTHER ====================
          _buildSectionTitle('other'.tr),

          _buildSettingItem(
            icon: Icons.info_outlined,
            title: 'about_app'.tr,
            onTap: () {
              Get.snackbar(
                'Ilova haqida',
                'JobHub v1.0.0\n\nIsh e\'lonlarini joylashtirish va qidirish platformasi',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),

          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'help'.tr,
            onTap: () {
              Get.snackbar(
                'Yordam',
                'Yordam uchun support@jobhub.uz ga yozing',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),

          const SizedBox(height: 32),

          // ==================== LOGOUT BUTTON ====================
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Confirm dialog ko'rsatish
                Get.dialog(
                  AlertDialog(
                    title: const Text('Chiqishni tasdiqlang'),
                    content: const Text('Haqiqatan ham chiqmoqchimisiz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Bekor qilish'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          authController.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text(
                          'Ha, chiqib borish',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'logout'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }

  // ========================================
  // ✅ SECTION TITLE WIDGET
  // ========================================
  // Bu bolim sarlavhasini yaratadi (masalan: "Account Settings")
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppConstants.textPrimary,
        ),
      ),
    );
  }

  // ========================================
  // ✅ SETTING ITEM WIDGET
  // ========================================
  // Bu oddiy setting row (icon + title + arrow)
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // Bosilganda bu funksiya ishga tushar
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          // Row - gorizontal qatorga joylashtirish
          child: Row(
            children: [
              // 1️⃣ Icon (chapda)
              Icon(icon, color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 16),

              // 2️⃣ Title (o'rtada, kengayadi)
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // 3️⃣ Arrow (o'ng tarafda)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppConstants.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ✅ LANGUAGE ITEM WIDGET
  // ========================================
  // Bu til tanlash uchun special widget
  Widget _buildLanguageItem({
    required String flag, // 🇺🇿
    required String name, // O'zbekcha
    required String code, // uz_UZ
    required bool isSelected, // Tanlangan yoki yo'q?
    required VoidCallback onTap, // Bosilganda
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            // ✅ Tanlangan bo'lsa - light blue fon
            color: isSelected
                ? AppConstants.primaryColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            // ✅ Tanlangan bo'lsa - blue border
            border: Border.all(
              color: isSelected ? AppConstants.primaryColor : Colors.grey[200]!,
              width: isSelected ? 2 : 1, // Tanlanganda qalinroq
            ),
          ),
          child: Row(
            children: [
              // 1️⃣ Flag emoji (chapda)
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),

              // 2️⃣ Til nomi (o'rtada, kengayadi)
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    // Tanlangan bo'lsa - qora, tanlanmagan bo'lsa - pushti
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textPrimary,
                    // Tanlangan bo'lsa - qalin
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),

              // 3️⃣ Checkmark (o'ng tarafda, faqat tanlanganda ko'rinadi)
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppConstants.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ✅ PASSWORD CHANGE DIALOG
  // ========================================
  // Parolni o'zgartirish uchun popup
  void _showChangePasswordDialog(BuildContext context) {
    // Text controllerslar ma'lumot uchun
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final authController = Get.find<AuthController>();

    Get.dialog(
      AlertDialog(
        title: Text('change_password'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Yangi parol kiritish
              TextField(
                controller: newPasswordController,
                obscureText: true, // Nuqtalar ko'rinadi
                decoration: InputDecoration(
                  labelText: 'new_password'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Parolni tasdiqlash
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'confirm_password'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // ✅ Cancel button
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),

          // ✅ Save button
          ElevatedButton(
            onPressed: () {
              // Parollar mos kelmasa xato
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                Get.snackbar(
                  'Xato',
                  'Parollar mos kelmadi',
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
                return;
              }

              // Parol bo'sh bo'lmasa
              if (newPasswordController.text.isEmpty) {
                Get.snackbar(
                  'Xato',
                  'Parolni kiriting',
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
                return;
              }

              // Parol kamida 6 ta belgidan iborat bo'lishi kerak
              if (newPasswordController.text.length < 6) {
                Get.snackbar(
                  'Xato',
                  'Parol kamida 6 ta belgidan iborat bo\'lishi kerak',
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
                return;
              }

              // ✅ Supabase ga parolni o'zgartirish
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}
