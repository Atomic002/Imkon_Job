import 'package:get/get.dart';
import 'package:flutter/material.dart';

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

  void changeLanguage(String code) {
    selectedLanguage.value = code;
    final lang = languages.firstWhere((l) => l['code'] == code);
    Get.updateLocale(lang['locale'] as Locale);
  }
}
