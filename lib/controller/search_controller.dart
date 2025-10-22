import 'package:flutter/material.dart';
import 'package:get/get.dart';

// SearchService import qiling
// import '../services/search_service.dart';

class SearchController extends GetxController {
  // SearchService instance (yuqorida import qilganingizdan keyin uncomment qiling)
  // final SearchService _searchService = SearchService();

  // Controllers
  final searchTextController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final selectedUserType = Rxn<String>(); // 'employer' or 'job_seeker'
  final selectedCategory = Rxn<Map<String, dynamic>>();
  final selectedSubCategory = Rxn<Map<String, dynamic>>();
  final selectedRegion = Rxn<String>();
  final selectedDistrict = Rxn<String>();

  // Lists
  final categories = <Map<String, dynamic>>[].obs;
  final subCategories = <Map<String, dynamic>>[].obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final popularSearches = <String>[].obs;

  // O'zbekiston viloyatlari
  final regions = <String>[
    'Toshkent shahri',
    'Andijon',
    'Buxoro',
    'Farg\'ona',
    'Jizzax',
    'Xorazm',
    'Namangan',
    'Navoiy',
    'Qashqadaryo',
    'Qoraqalpog\'iston',
    'Samarqand',
    'Sirdaryo',
    'Surxondaryo',
    'Toshkent viloyati',
  ].obs;

  // Rayonlar (har bir viloyat uchun)
  final Map<String, List<String>> districts = {
    'Toshkent shahri': [
      'Bektemir',
      'Chilonzor',
      'Mirobod',
      'Olmazor',
      'Sergeli',
      'Shayxontohur',
      'Uchtepa',
      'Yashnobod',
      'Yakkasaroy',
      'Yunusobod',
      'Yangihayot',
    ],
    'Andijon': [
      'Andijon shahri',
      'Xo\'jaobod',
      'Asaka',
      'Baliqchi',
      'Bo\'z',
      'Buloqboshi',
      'Izboskan',
      'Jalolquduq',
      'Marhamat',
      'Oltinko\'l',
      'Paxtaobod',
      'Qo\'rg\'ontepa',
      'Shahrixon',
      'Ulug\'nor',
      'Xonobod',
    ],
    'Farg\'ona': [
      'Farg\'ona shahri',
      'Beshariq',
      'Bog\'dod',
      'Buvayda',
      'Dang\'ara',
      'Farg\'ona',
      'Furqat',
      'O\'zbekiston',
      'Qo\'qon',
      'Qo\'shtepa',
      'Quva',
      'Rishton',
      'So\'x',
      'Toshloq',
      'Uchko\'prik',
      'Yozyovon',
    ],
    'Namangan': [
      'Namangan shahri',
      'Chortoq',
      'Chust',
      'Kosonsoy',
      'Mingbuloq',
      'Norin',
      'Pop',
      'To\'raqo\'rg\'on',
      'Uchqo\'rg\'on',
      'Uychi',
      'Yangiqo\'rg\'on',
    ],
    'Samarqand': [
      'Samarqand shahri',
      'Bulung\'ur',
      'Ishtixon',
      'Jomboy',
      'Kattaqo\'rg\'on',
      'Narpay',
      'Nurobod',
      'Oqdaryo',
      'Payariq',
      'Pastdarg\'om',
      'Qo\'shrabot',
      'Samarqand',
      'Toyloq',
      'Urgut',
    ],
  };

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  // Initial data yuklash
  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      // API dan kategoriyalarni yuklash
      // final cats = await _searchService.getCategories();
      // categories.value = cats;

      // Hozircha test uchun statik ma'lumotlar
      categories.value = [
        {'id': 1, 'name': 'IT', 'icon_url': '💻'},
        {'id': 2, 'name': 'Qurilish', 'icon_url': '🏗️'},
        {'id': 3, 'name': 'Ta\'lim', 'icon_url': '📚'},
        {'id': 4, 'name': 'Xizmatlar', 'icon_url': '🛎️'},
        {'id': 5, 'name': 'Transport', 'icon_url': '🚗'},
        {'id': 6, 'name': 'Dizayn', 'icon_url': '🎨'},
      ];

      // Mashhur qidiruvlar
      // final popular = await _searchService.getPopularSearches();
      // popularSearches.value = popular;

      popularSearches.value = [
        'Flutter Developer',
        'React Developer',
        'UI Designer',
        'Mobile Developer',
        'Backend Developer',
        'Frontend Developer',
      ];
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Ma\'lumotlarni yuklashda xato: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // User type tanlash
  void selectUserType(String type) {
    selectedUserType.value = type;
    // Reset other filters
    selectedCategory.value = null;
    selectedSubCategory.value = null;
    selectedRegion.value = null;
    selectedDistrict.value = null;
    subCategories.clear();
    searchResults.clear();
  }

  // Kategoriya tanlash
  Future<void> selectCategory(Map<String, dynamic> category) async {
    selectedCategory.value = category;
    selectedSubCategory.value = null;

    // Sub kategoriyalarni yuklash
    try {
      // final subs = await _searchService.getSubCategories(category['id']);
      // subCategories.value = subs;

      // Test uchun statik ma'lumotlar
      if (category['id'] == 1) {
        // IT
        subCategories.value = [
          {'id': 1, 'name': 'Frontend', 'category_id': 1},
          {'id': 2, 'name': 'Backend', 'category_id': 1},
          {'id': 3, 'name': 'Mobile', 'category_id': 1},
          {'id': 4, 'name': 'DevOps', 'category_id': 1},
          {'id': 5, 'name': 'QA/Testing', 'category_id': 1},
        ];
      } else if (category['id'] == 6) {
        // Dizayn
        subCategories.value = [
          {'id': 6, 'name': 'UI/UX', 'category_id': 6},
          {'id': 7, 'name': 'Grafik dizayn', 'category_id': 6},
          {'id': 8, 'name': '3D Modeling', 'category_id': 6},
        ];
      } else {
        subCategories.value = [];
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Sub kategoriyalarni yuklashda xato: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  // Sub kategoriya tanlash
  void selectSubCategory(Map<String, dynamic> subCategory) {
    selectedSubCategory.value = subCategory;
  }

  // Viloyat tanlash
  void selectRegion(String region) {
    selectedRegion.value = region;
    selectedDistrict.value = null;
  }

  // Rayon tanlash
  void selectDistrict(String district) {
    selectedDistrict.value = district;
  }

  // Qidirish
  Future<void> performSearch() async {
    if (selectedUserType.value == null) {
      Get.snackbar(
        'Ogohlantirish',
        'Iltimos ish beruvchi yoki ish qidiruvchini tanlang',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
      );
      return;
    }

    isLoading.value = true;
    try {
      // API dan qidirish
      // final results = await _searchService.searchPosts(
      //   searchQuery: searchTextController.text,
      //   userType: selectedUserType.value,
      //   categoryId: selectedCategory.value?['id'],
      //   subCategoryId: selectedSubCategory.value?['id'],
      //   region: selectedRegion.value,
      //   district: selectedDistrict.value,
      // );
      // searchResults.value = results;

      // Test uchun statik natijalar
      await Future.delayed(const Duration(seconds: 1));
      searchResults.value = [
        {
          'id': '1',
          'title': 'Flutter Developer kerak',
          'description':
              'Tajribali Flutter developer kerak. Remote ishlash imkoniyati mavjud.',
          'location':
              '${selectedRegion.value ?? "Toshkent"}, ${selectedDistrict.value ?? "Yunusobod"}',
          'users': {
            'full_name': 'IT Company',
            'avatar_url': null,
            'user_type': selectedUserType.value,
          },
          'categories': selectedCategory.value,
          'views_count': 125,
          'likes_count': 15,
        },
        {
          'id': '2',
          'title': 'Senior Mobile Developer',
          'description':
              'Android va iOS uchun native app development. 3+ yil tajriba talab etiladi.',
          'location':
              '${selectedRegion.value ?? "Toshkent"}, ${selectedDistrict.value ?? "Chilonzor"}',
          'users': {
            'full_name': 'Tech Solutions',
            'avatar_url': null,
            'user_type': selectedUserType.value,
          },
          'categories': selectedCategory.value,
          'views_count': 89,
          'likes_count': 8,
        },
      ];

      if (searchResults.isEmpty) {
        Get.snackbar(
          'Natija topilmadi',
          'Bu filtrlar bo\'yicha hech qanday e\'lon topilmadi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withOpacity(0.1),
          colorText: Colors.blue,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Qidirishda xato: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mashhur qidiruvdan tanlash
  void selectPopularSearch(String searchText) {
    searchTextController.text = searchText;
  }

  // Filtrlarni tozalash
  void clearFilters() {
    searchTextController.clear();
    selectedUserType.value = null;
    selectedCategory.value = null;
    selectedSubCategory.value = null;
    selectedRegion.value = null;
    selectedDistrict.value = null;
    subCategories.clear();
    searchResults.clear();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }
}
