import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  final selectedLanguage = 'uz_UZ'.obs;

  final languages = [
    {
      'code': 'uz_UZ',
      'name': 'O\'zbekcha (Lotin)',
      'flag': '🇺🇿',
      'locale': const Locale('uz', 'UZ'),
    },
    {
      'code': 'uz_UZ_CYRILLIC',
      'name': 'Ўзбекча (Кирилл)',
      'flag': '🇺🇿',
      'locale': const Locale('uz', 'UZ'),
    },
    {
      'code': 'ru_RU',
      'name': 'Русский',
      'flag': '🇷🇺',
      'locale': const Locale('ru', 'RU'),
    },
    {
      'code': 'en_US',
      'name': 'English',
      'flag': '🇬🇧',
      'locale': const Locale('en', 'US'),
    },
  ];

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  // Saqlangan tilni yuklash
  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('selected_language') ?? 'uz_UZ';
      selectedLanguage.value = savedLang;

      final lang = languages.firstWhere(
        (l) => l['code'] == savedLang,
        orElse: () => languages[0],
      );
      Get.updateLocale(lang['locale'] as Locale);
      print('✅ Loaded language: $savedLang');
    } catch (e) {
      print('❌ Load language error: $e');
    }
  }

  // Tilni o'zgartirish
  Future<void> changeLanguage(String code) async {
    try {
      selectedLanguage.value = code;
      final lang = languages.firstWhere((l) => l['code'] == code);
      Get.updateLocale(lang['locale'] as Locale);

      // Tilni saqlash
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', code);

      Get.snackbar(
        'language_changed'.tr,
        getCurrentLanguageName(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('✅ Language changed to: $code');
    } catch (e) {
      print('❌ Change language error: $e');
      Get.snackbar(
        'error'.tr,
        'Tilni o\'zgartirishda xatolik',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // Joriy til nomini olish
  String getCurrentLanguageName() {
    final lang = languages.firstWhere(
      (l) => l['code'] == selectedLanguage.value,
      orElse: () => languages[0],
    );
    return lang['name'] as String;
  }

  // Joriy til flagini olish
  String getCurrentLanguageFlag() {
    final lang = languages.firstWhere(
      (l) => l['code'] == selectedLanguage.value,
      orElse: () => languages[0],
    );
    return lang['flag'] as String;
  }

  // Kirill yoki Lotin ekanligini tekshirish
  bool isCyrillic() {
    return selectedLanguage.value == 'uz_UZ_CYRILLIC';
  }
}
