import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/job_post.dart';

class FilterController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Controllers
  final searchController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final isSearchPerformed = false.obs;
  final selectedPostType = Rxn<String>();
  final selectedCategory = Rxn<Map<String, dynamic>>();
  final selectedSubCategory = Rxn<Map<String, dynamic>>();
  final selectedRegion = Rxn<String>();
  final selectedDistrict = Rxn<String>();
  final searchText = ''.obs;

  // Lists
  final categories = <Map<String, dynamic>>[].obs;
  final subCategories = <Map<String, dynamic>>[].obs;
  final filteredPosts = <JobPost>[].obs;
  final likedPostIds = <String>[].obs;

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
    _initializeController();
  }

  void _initializeController() {
    // FAQAT KATEGORIYA VA LIKED POSTS YUKLASH
    // applyFilters() ni bu yerda chaqirmaydi!
    loadCategories();
    loadLikedPosts();

    searchController.addListener(() {
      searchText.value = searchController.text;
    });
  }

  // ✅ KATEGORIYALARNI YUKLASH
  Future<void> loadCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name')
          .order('name', ascending: true);

      categories.value = List<Map<String, dynamic>>.from(response);
      print('✅ ${categories.length} ta kategoriya yuklandi');
    } catch (e) {
      print('❌ Kategoriya yuklash xatosi: $e');
      _showError('failed_to_load_categories'.tr);
    }
  }

  // ✅ YOQTIRILGAN POSTLARNI YUKLASH
  Future<void> loadLikedPosts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId);

      likedPostIds.value = List<String>.from(
        response.map((item) => item['post_id'].toString()),
      );
      print('✅ ${likedPostIds.length} ta liked post yuklandi');
    } catch (e) {
      print('⚠️ Liked posts yuklash xatosi: $e');
    }
  }

  // ✅ POST TURINI TANLASH
  void selectPostType(String type) {
    if (selectedPostType.value == type) {
      selectedPostType.value = null;
    } else {
      selectedPostType.value = type;
    }
    // Post turi o'zgarganda boshqa filtrlarni tozalash
    selectedCategory.value = null;
    selectedSubCategory.value = null;
    subCategories.clear();
    isSearchPerformed.value = false;
    filteredPosts.clear();
  }

  // ✅ KATEGORIYANI TANLASH
  Future<void> selectCategory(Map<String, dynamic> category) async {
    selectedCategory.value = category;
    selectedSubCategory.value = null;

    try {
      isLoading.value = true;
      final response = await _supabase
          .from('sub_categories')
          .select('id, name')
          .eq('category_id', category['id'])
          .order('name', ascending: true);

      subCategories.value = List<Map<String, dynamic>>.from(response);
      print('✅ ${subCategories.length} ta sub-kategoriya yuklandi');
    } catch (e) {
      print('❌ Sub-kategoriya yuklash xatosi: $e');
      _showError('failed_to_load_subcategories'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ SUB-KATEGORIYANI TANLASH
  void selectSubCategory(Map<String, dynamic> subCategory) {
    if (selectedSubCategory.value?['id'] == subCategory['id']) {
      selectedSubCategory.value = null;
    } else {
      selectedSubCategory.value = subCategory;
    }
  }

  // ✅ VILOYATNI TANLASH
  void selectRegion(String region) {
    selectedRegion.value = region;
    selectedDistrict.value = null;
  }

  // ✅ TUMANNI TANLASH
  void selectDistrict(String district) {
    selectedDistrict.value = district;
  }

  // ✅ BUTUN VILOYATNI TANLASH
  void selectWholeRegion() {
    selectedDistrict.value = null;
    print('✅ Butun viloyat tanlandi: ${selectedRegion.value}');
  }

  // ✅ QIDIRUV TEXTNI TOZALASH
  void clearSearchText() {
    searchController.clear();
    searchText.value = '';
  }

  // ✅ KATEGORIYANI TOZALASH
  void clearCategory() {
    selectedCategory.value = null;
    selectedSubCategory.value = null;
    subCategories.clear();
  }

  // ✅ SUB-KATEGORIYANI TOZALASH
  void clearSubCategory() {
    selectedSubCategory.value = null;
  }

  // ✅ MANZILNI TOZALASH
  void clearLocation() {
    selectedRegion.value = null;
    selectedDistrict.value = null;
  }

  // ✅ MANZIL DISPLAYI
  String getLocationDisplay() {
    if (selectedDistrict.value != null) {
      return '${selectedRegion.value}, ${selectedDistrict.value}';
    } else if (selectedRegion.value != null) {
      return selectedRegion.value!;
    }
    return 'select_option'.tr;
  }

  // ✅ QIDIRUV MUMKINLIGINI TEKSHIRISH
  bool canSearch() => selectedPostType.value != null;

  // ✅ AKTIV FILTRLAR BORLIGINI TEKSHIRISH
  bool hasActiveFilters() {
    return selectedCategory.value != null ||
        selectedSubCategory.value != null ||
        selectedRegion.value != null ||
        selectedDistrict.value != null ||
        searchText.value.isNotEmpty;
  }

  // ✅ FILTRLARNI QO'LLASH (ASOSIY QIDIRUV FUNKSIYASI)
  Future<void> applyFilters() async {
    if (!canSearch()) {
      _showWarning('post_type_filter'.tr, 'select_post_type'.tr);
      return;
    }

    final postType = selectedPostType.value!;
    final searchQuery = searchController.text.trim();
    final categoryId = selectedCategory.value?['id'];
    final subCategoryId = selectedSubCategory.value?['id'];
    final region = selectedRegion.value;
    final district = selectedDistrict.value;

    print('🔍 Qidiruv boshlandi:');
    print('   Post turi: $postType');
    print('   Qidiruv matni: $searchQuery');
    print('   Kategoriya ID: $categoryId');
    print('   Sub-kategoriya ID: $subCategoryId');
    print('   Viloyat: $region');
    print('   Tuman: $district');

    try {
      isLoading.value = true;

      var query = _supabase.from('posts').select('''
        id, user_id, title, description, category_id, sub_category_id,
        location, status, salary_type, salary_min, salary_max,
        requirements_main, requirements_basic, views_count, likes_count,
        shares_count, duration_days, is_active, created_at, post_type,
        skills, experience, phone_number,
        users!posts_user_id_fkey(id, username, first_name, last_name, profile_photo_url, user_type, location),
        categories(id, name),
        sub_categories(id, name),
        post_images(image_url)
      ''');

      // Asosiy filtrlar
      query = query
          .eq('is_active', true)
          .eq('status', 'approved')
          .eq('post_type', postType);

      // Qidiruv matni bo'yicha filter
      if (searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      // Kategoriya filtri
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      // Sub-kategoriya filtri
      if (subCategoryId != null) {
        query = query.eq('sub_category_id', subCategoryId);
      }

      // ✅ MANZIL FILTRI (Tuzatilgan)
      if (region != null) {
        if (district != null) {
          // Tuman tanlangan: "Farg'ona, Beshariq"
          query = query.ilike('location', '%$region%$district%');
        } else {
          // Faqat viloyat: "Farg'ona"
          query = query.ilike('location', '%$region%');
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(50); // 100 dan 50 ga kamaytirildi

      print('✅ ${response.length} ta e\'lon topildi');

      // Postlarni parse qilish
      final List<JobPost> posts = await _parsePosts(response);

      filteredPosts.assignAll(posts);
      isSearchPerformed.value = true;

      if (posts.isEmpty) {
        _showInfo('no_results_found'.tr, 'try_different_filters'.tr);
      } else {
        Get.snackbar(
          'success'.tr,
          '${posts.length} ta e\'lon topildi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Qidiruv xatosi: $e');
      print('Stack trace: $stackTrace');
      _showError('Qidiruv amalga oshmadi');
      filteredPosts.clear();
      isSearchPerformed.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ POSTLARNI PARSE QILISH (OPTIMALLASHTIRILGAN)
  Future<List<JobPost>> _parsePosts(List<dynamic> response) async {
    final List<JobPost> posts = [];

    for (var i = 0; i < response.length; i++) {
      try {
        final json = Map<String, dynamic>.from(response[i]);

        // Rasmlarni qayta ishlash (PARALLEL EMAS, KETMA-KET)
        if (json['post_images'] != null && json['post_images'] is List) {
          List<dynamic> processedImages = [];

          for (var img in json['post_images']) {
            if (img['image_url'] != null) {
              String imagePath = img['image_url'];

              if (imagePath.startsWith('http://') ||
                  imagePath.startsWith('https://')) {
                processedImages.add({'image_url': imagePath});
              } else {
                try {
                  final publicUrl = _supabase.storage
                      .from('post_images')
                      .getPublicUrl(imagePath);
                  processedImages.add({'image_url': publicUrl});
                } catch (imgError) {
                  print('⚠️ Rasm URL xatosi: $imgError');
                }
              }
            }
          }

          json['post_images'] = processedImages;
        }

        final post = JobPost.fromJson(json);
        posts.add(post);
      } catch (e) {
        print('❌ Post parsing xatosi (index $i): $e');
        continue;
      }
    }

    return posts;
  }

  // ✅ LIKE/UNLIKE FUNKSIYASI
  Future<void> toggleLike(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _showWarning('error'.tr, 'please_login'.tr);
        return;
      }

      final isLiked = likedPostIds.contains(postId);

      if (isLiked) {
        // Unlike
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        likedPostIds.remove(postId);
        _updatePostLikeCount(postId, -1);
      } else {
        // Like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
          'liked_at': DateTime.now().toIso8601String(),
        });

        likedPostIds.add(postId);
        _updatePostLikeCount(postId, 1);
      }
    } catch (e) {
      print('❌ Like xatosi: $e');
      _showError('error'.tr);
    }
  }

  // ✅ POST LIKE COUNTNI YANGILASH
  void _updatePostLikeCount(String postId, int change) {
    final postIndex = filteredPosts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final updatedPost = filteredPosts[postIndex];
      updatedPost.likes = (updatedPost.likes + change).clamp(0, 999999);
      filteredPosts[postIndex] = updatedPost;
      filteredPosts.refresh();
    }
  }

  // ✅ POST YOQTIRILGANLIGINI TEKSHIRISH
  bool isPostLiked(String postId) => likedPostIds.contains(postId);

  // ✅ BARCHA FILTRLARNI TOZALASH
  void resetFilters() {
    searchController.clear();
    searchText.value = '';
    selectedPostType.value = null;
    selectedCategory.value = null;
    selectedSubCategory.value = null;
    selectedRegion.value = null;
    selectedDistrict.value = null;
    subCategories.clear();
    filteredPosts.clear();
    isSearchPerformed.value = false;

    Get.snackbar(
      'success'.tr,
      'Filtrlar tozalandi',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // ✅ HELPER FUNKSIYALAR
  void _showError(String message) {
    Get.snackbar(
      'Xatolik',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showWarning(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
