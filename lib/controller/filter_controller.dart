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
    loadCategories();
    loadLikedPosts();
    searchController.addListener(() {
      searchText.value = searchController.text;
    });
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      final response = await _supabase
          .from('categories')
          .select('id, name')
          .order('name', ascending: true);
      categories.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Category load error: $e');
      Get.snackbar(
        'Xatolik',
        'Kategoriyalarni yuklashda xatolik',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

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
    } catch (e) {
      print('⚠️ Liked posts load error: $e');
    }
  }

  void selectPostType(String type) {
    if (selectedPostType.value == type) {
      selectedPostType.value = null;
    } else {
      selectedPostType.value = type;
    }
    selectedCategory.value = null;
    selectedSubCategory.value = null;
    subCategories.clear();
    isSearchPerformed.value = false;
    filteredPosts.clear();
  }

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
    } catch (e) {
      print('❌ Sub-category load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectSubCategory(Map<String, dynamic> subCategory) {
    if (selectedSubCategory.value?['id'] == subCategory['id']) {
      selectedSubCategory.value = null;
    } else {
      selectedSubCategory.value = subCategory;
    }
  }

  void selectRegion(String region) {
    selectedRegion.value = region;
    selectedDistrict.value = null;
  }

  // ✅ TUZATILGAN - Butun viloyat uchun
  void selectDistrict(String district) {
    selectedDistrict.value = district;
  }

  // ✅ YANGI METOD - Butun viloyatni tanlash
  void selectWholeRegion() {
    // Faqat region saqlanadi, district null bo'ladi
    selectedDistrict.value = null;
    print('✅ Butun viloyat tanlandi: ${selectedRegion.value}');
  }

  void clearSearchText() {
    searchController.clear();
    searchText.value = '';
  }

  void clearCategory() {
    selectedCategory.value = null;
    selectedSubCategory.value = null;
    subCategories.clear();
  }

  void clearSubCategory() {
    selectedSubCategory.value = null;
  }

  void clearLocation() {
    selectedRegion.value = null;
    selectedDistrict.value = null;
  }

  // ✅ TUZATILGAN - Display text
  String getLocationDisplay() {
    if (selectedDistrict.value != null) {
      return '${selectedRegion.value}, ${selectedDistrict.value}';
    } else if (selectedRegion.value != null) {
      return selectedRegion.value!; // Faqat viloyat nomi
    }
    return 'Tanlash';
  }

  bool canSearch() => selectedPostType.value != null;

  bool hasActiveFilters() {
    return selectedCategory.value != null ||
        selectedSubCategory.value != null ||
        selectedRegion.value != null ||
        selectedDistrict.value != null ||
        searchText.value.isNotEmpty;
  }

  // ✅ TUZATILGAN - Qidiruv logikasi
  Future<void> applyFilters() async {
    if (!canSearch()) {
      Get.snackbar(
        'Ogohlantirish',
        'Iltimos e\'lon turini tanlang',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final postType = selectedPostType.value!;
    final searchQuery = searchController.text.trim();
    final categoryId = selectedCategory.value?['id'];
    final subCategoryId = selectedSubCategory.value?['id'];
    final region = selectedRegion.value;
    final district = selectedDistrict.value;

    print('🔍 Qidiruv boshlandi: $postType');
    print('📍 Region: $region, District: $district');

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

      query = query
          .eq('is_active', true)
          .eq('status', 'approved')
          .eq('post_type', postType);

      if (searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (subCategoryId != null) {
        query = query.eq('sub_category_id', subCategoryId);
      }

      // ✅ TUZATILGAN - Location filter
      if (region != null) {
        if (district != null) {
          // Agar tuman tanlangan bo'lsa: "Farg'ona, Beshariq"
          query = query.ilike('location', '%$region%$district%');
          print('🔍 Qidiruv patterni (tuman): $region, $district');
        } else {
          // Agar faqat viloyat tanlangan bo'lsa: "Farg'ona"
          query = query.ilike('location', '%$region%');
          print('🔍 Qidiruv patterni (viloyat): $region');
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(100);

      print('✅ ${response.length} ta e\'lon topildi');

      final List<JobPost> posts = [];

      for (var i = 0; i < response.length; i++) {
        try {
          final json = response[i];

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
                    print('⚠️ Image URL conversion error: $imgError');
                  }
                }
              }
            }

            json['post_images'] = processedImages;
          }

          final post = JobPost.fromJson(json);
          posts.add(post);
        } catch (e) {
          print('❌ Post parsing error at index $i: $e');
          continue;
        }
      }

      filteredPosts.assignAll(posts);
      isSearchPerformed.value = true;

      print('✅ ${posts.length} ta post muvaffaqiyatli yuklandi');

      if (posts.isEmpty) {
        Get.snackbar(
          'Natija yo\'q',
          'Hech qanday e\'lon topilmadi',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Qidiruv xatosi: $e');
      print('Stack trace: $stackTrace');

      filteredPosts.clear();
      isSearchPerformed.value = true;

      Get.snackbar(
        'Xatolik',
        'Qidirishda xatolik yuz berdi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.snackbar(
          'Xatolik',
          'Iltimos tizimga kiring',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final isLiked = likedPostIds.contains(postId);

      if (isLiked) {
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        likedPostIds.remove(postId);

        final postIndex = filteredPosts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final updatedPost = filteredPosts[postIndex];
          updatedPost.likes = (updatedPost.likes - 1).clamp(0, 999999);
          filteredPosts[postIndex] = updatedPost;
          filteredPosts.refresh();
        }
      } else {
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });

        likedPostIds.add(postId);

        final postIndex = filteredPosts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final updatedPost = filteredPosts[postIndex];
          updatedPost.likes++;
          filteredPosts[postIndex] = updatedPost;
          filteredPosts.refresh();
        }
      }
    } catch (e) {
      print('❌ Like error: $e');
      Get.snackbar(
        'Xatolik',
        'Like qo\'shishda xatolik',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool isPostLiked(String postId) => likedPostIds.contains(postId);

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
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
