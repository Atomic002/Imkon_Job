import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/job_post.dart';

class HomeController extends GetxController {
  // ✅ Observable variables
  final pageController = PageController();
  final currentPostIndex = 0.obs;
  final selectedCategory = 'all'.obs;
  final likedPosts = <String, bool>{}.obs;
  final posts = <JobPost>[].obs;
  final isLoading = false.obs;
  final notificationCount = 0.obs;

  final supabase = Supabase.instance.client;

  // 🔥 PAGINATION VARIABLES
  static const int INITIAL_BATCH = 30;
  static const int NEXT_BATCH = 20;
  int currentOffset = 0;
  bool hasMorePosts = true;
  bool isLoadingMore = false;

  // ✅ Categories
  final categories = [
    {'id': 'all', 'name': 'all_categories', 'icon': '🌐'},
    {'id': 'it', 'name': 'it', 'icon': '💻'},
    {'id': 'construction', 'name': 'construction', 'icon': '🏗️'},
    {'id': 'education', 'name': 'education', 'icon': '📚'},
    {'id': 'service', 'name': 'service', 'icon': '🛎️'},
    {'id': 'transport', 'name': 'transport', 'icon': '🚗'},
  ];

  @override
  void onInit() {
    super.onInit();
    loadPosts();
    loadNotificationCount();
    pageController.addListener(_onPageScroll);
  }

  // 🔥 SCROLL LISTENER
  void _onPageScroll() {
    if (currentPostIndex.value >= posts.length - 5 &&
        !isLoadingMore &&
        hasMorePosts) {
      loadMorePosts();
    }
  }

  // ==================== LOAD NOTIFICATION COUNT ====================
  Future<void> loadNotificationCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      if (response != null) {
        notificationCount.value = response.length;
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  // ==================== HELPER: Convert Image URLs ====================
  List<String>? _convertImageUrls(List? images) {
    if (images == null || images.isEmpty) {
      print('⚠️ Images bo\'sh yoki null');
      return null;
    }

    print('📦 Raw images data: $images');

    return images.map((img) {
      String imageUrl = img['image_url'] as String;

      print('🔍 Original URL: $imageUrl');

      // ✅ Agar URL to'liq bo'lmasa, Supabase Storage'dan public URL yasash
      if (!imageUrl.startsWith('http')) {
        imageUrl = supabase.storage
            .from('posts') // Bucket nomi
            .getPublicUrl(imageUrl);

        print('✅ Converted URL: $imageUrl');
      } else {
        print('✅ URL allaqachon to\'liq: $imageUrl');
      }

      return imageUrl;
    }).toList();
  }

  // ==================== LOAD POSTS FROM SUPABASE (INITIAL) ====================
  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      currentOffset = 0;
      hasMorePosts = true;

      print('🔄 Postlar yuklanmoqda...');

      final response = await supabase
          .from('posts')
          .select('''
            id,
            user_id,
            title,
            description,
            category_id,
            sub_category_id,
            location,
            status,
            salary_min,
            salary_max,
            requirements_main,
            requirements_basic,
            views_count,
            likes_count,
            shares_count,
            duration_days,
            is_active,
            created_at,
            users!inner(first_name, last_name, profile_photo_url),
            post_images(image_url)
          ''')
          .eq('status', 'approved')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(INITIAL_BATCH);

      print('📊 Database dan ${response.length} ta post olindi');

      if (response.isEmpty) {
        print('⚠️ Hech qanday post topilmadi');
        posts.value = [];
        return;
      }

      final loadedPosts = <JobPost>[];

      for (var item in response) {
        try {
          // ✅ Image URL'larni to'g'ri formatga o'tkazish
          final images = item['post_images'] as List?;
          final imageUrls = _convertImageUrls(images);

          if (imageUrls != null && imageUrls.isNotEmpty) {
            print('🖼️ Post ${item['id']}: ${imageUrls.length} ta image');
          }

          // ✅ users dan ma'lumot olish
          final user = item['users'] as Map<String, dynamic>?;
          final firstName = user?['first_name'] as String? ?? '';
          final lastName = user?['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();

          final post = JobPost(
            id: item['id'] as String,
            title: item['title'] as String? ?? 'Sarlavha yo\'q',
            description: item['description'] as String? ?? '',
            categoryIdNum: item['category_id'] as int? ?? 0,
            subCategoryId: item['sub_category_id'] as int?,
            location:
                item['location'] as String? ?? 'Joylashuv ko\'rsatilmagan',
            salaryMin: item['salary_min'] as int? ?? 0,
            salaryMax: item['salary_max'] as int? ?? 0,
            company: fullName.isEmpty ? 'Kompaniya' : fullName,
            companyLogo: user?['profile_photo_url'] as String?,
            userId: item['user_id'] as String? ?? '',
            views: item['views_count'] as int? ?? 0,
            likes: item['likes_count'] as int? ?? 0,
            createdAt: DateTime.parse(item['created_at'] as String),
            imageUrls: imageUrls,
            requirementsMain: item['requirements_main'] as String?,
            requirementsBasic: item['requirements_basic'] as String?,
            status: item['status'] as String? ?? 'approved',
            isActive: item['is_active'] as bool? ?? true,
            sharesCount: item['shares_count'] as int?,
            durationDays: item['duration_days'] as int?,
          );

          loadedPosts.add(post);
        } catch (e) {
          print('❌ Post convert error: $e');
          print('❌ Item: $item');
        }
      }

      posts.value = loadedPosts;
      currentOffset = loadedPosts.length;
      hasMorePosts = loadedPosts.length >= INITIAL_BATCH;

      print('✅ ${posts.length} ta post yuklandi');

      for (var post in posts) {
        likedPosts[post.id] = false;
      }

      await checkUserLikes();
    } catch (e) {
      print('❌ Load posts error: $e');
      posts.value = [];
      Get.snackbar(
        'Xato',
        'E\'lonlarni yuklashda xato',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== LOAD MORE POSTS (PAGINATION) ====================
  Future<void> loadMorePosts() async {
    if (isLoadingMore || !hasMorePosts) return;

    isLoadingMore = true;
    print('📥 Qo\'shimcha postlar yuklanmoqda... (offset: $currentOffset)');

    try {
      final response = await supabase
          .from('posts')
          .select('''
            id,
            user_id,
            title,
            description,
            category_id,
            sub_category_id,
            location,
            status,
            salary_min,
            salary_max,
            requirements_main,
            requirements_basic,
            views_count,
            likes_count,
            shares_count,
            duration_days,
            is_active,
            created_at,
            users!inner(first_name, last_name, profile_photo_url),
            post_images(image_url)
          ''')
          .eq('status', 'approved')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(currentOffset, currentOffset + NEXT_BATCH - 1);

      if (response.isEmpty) {
        hasMorePosts = false;
        print('📭 Boshqa post yo\'q');
        return;
      }

      print('✅ ${response.length} ta qo\'shimcha post olindi');

      final newPosts = <JobPost>[];

      for (var item in response) {
        try {
          // ✅ Image URL'larni to'g'ri formatga o'tkazish
          final images = item['post_images'] as List?;
          final imageUrls = _convertImageUrls(images);

          final user = item['users'] as Map<String, dynamic>?;
          final firstName = user?['first_name'] as String? ?? '';
          final lastName = user?['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();

          final post = JobPost(
            id: item['id'] as String,
            title: item['title'] as String? ?? 'Sarlavha yo\'q',
            description: item['description'] as String? ?? '',
            categoryIdNum: item['category_id'] as int? ?? 0,
            subCategoryId: item['sub_category_id'] as int?,
            location:
                item['location'] as String? ?? 'Joylashuv ko\'rsatilmagan',
            salaryMin: item['salary_min'] as int? ?? 0,
            salaryMax: item['salary_max'] as int? ?? 0,
            company: fullName.isEmpty ? 'Kompaniya' : fullName,
            companyLogo: user?['profile_photo_url'] as String?,
            userId: item['user_id'] as String? ?? '',
            views: item['views_count'] as int? ?? 0,
            likes: item['likes_count'] as int? ?? 0,
            createdAt: DateTime.parse(item['created_at'] as String),
            imageUrls: imageUrls,
            requirementsMain: item['requirements_main'] as String?,
            requirementsBasic: item['requirements_basic'] as String?,
            status: item['status'] as String? ?? 'approved',
            isActive: item['is_active'] as bool? ?? true,
            sharesCount: item['shares_count'] as int?,
            durationDays: item['duration_days'] as int?,
          );

          newPosts.add(post);
          likedPosts[post.id] = false;
        } catch (e) {
          print('❌ Post convert error: $e');
        }
      }

      posts.addAll(newPosts);
      currentOffset += newPosts.length;

      if (newPosts.length < NEXT_BATCH) {
        hasMorePosts = false;
      }

      print('✅ Jami ${posts.length} ta post mavjud');

      await checkUserLikes();
    } catch (e) {
      print('❌ Load more posts error: $e');
    } finally {
      isLoadingMore = false;
    }
  }

  // ==================== CHECK USER LIKES ====================
  Future<void> checkUserLikes() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final likedPostIds = await supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId);

      for (var like in likedPostIds) {
        final postId = like['post_id'] as String?;
        if (postId != null) {
          likedPosts[postId] = true;
        }
      }
      likedPosts.refresh();
    } catch (e) {
      print('Check likes error: $e');
    }
  }

  // ==================== SELECT CATEGORY ====================
  void selectCategory(String categoryId) {
    selectedCategory.value = categoryId;
  }

  // ==================== TOGGLE LIKE ====================
  Future<void> toggleLike(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        Get.snackbar(
          'Xato',
          'Iltimos, avval login qiling',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final wasLiked = likedPosts[postId] ?? false;
      likedPosts[postId] = !wasLiked;

      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        if (!wasLiked) {
          posts[postIndex].likes++;

          await supabase
              .from('post_likes')
              .insert({'post_id': postId, 'user_id': userId})
              .catchError((error) {
                likedPosts[postId] = wasLiked;
                posts[postIndex].likes--;
                print('Like insert error: $error');
              });
        } else {
          posts[postIndex].likes--;

          await supabase
              .from('post_likes')
              .delete()
              .eq('post_id', postId)
              .eq('user_id', userId)
              .catchError((error) {
                likedPosts[postId] = wasLiked;
                posts[postIndex].likes++;
                print('Like delete error: $error');
              });
        }
      }

      posts.refresh();
      likedPosts.refresh();
    } catch (e) {
      print('❌ Toggle like error: $e');
      Get.snackbar(
        'Xato',
        'Like qilishda xato',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ==================== RECORD POST VIEW ====================
  Future<void> recordPostView(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      await supabase.from('post_views').insert({
        'post_id': postId,
        'user_id': userId,
        'viewed_at': DateTime.now().toIso8601String(),
      });

      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1 && !isClosed) {
        posts[postIndex].views++;
        posts.refresh();
      }

      print('✅ View recorded for post: $postId');
    } catch (e) {
      print('⚠️ Record view error: $e');
    }
  }

  // ==================== REFRESH POSTS ====================
  Future<void> refreshPosts() async {
    await loadPosts();
    await loadNotificationCount();
  }

  // ==================== SEARCH POSTS ====================
  Future<void> searchPosts(String query) async {
    try {
      if (query.isEmpty) {
        await loadPosts();
        return;
      }

      isLoading.value = true;

      final response = await supabase
          .from('posts')
          .select('''
            *,
            users!inner(first_name, last_name, profile_photo_url),
            post_images(image_url)
          ''')
          .eq('status', 'approved')
          .eq('is_active', true)
          .ilike('title', '%$query%')
          .order('created_at', ascending: false);

      final searchResults = <JobPost>[];
      for (var item in response) {
        try {
          // ✅ Image URL'larni to'g'ri formatga o'tkazish
          final images = item['post_images'] as List?;
          final imageUrls = _convertImageUrls(images);

          final user = item['users'] as Map<String, dynamic>?;
          final firstName = user?['first_name'] as String? ?? '';
          final lastName = user?['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();

          searchResults.add(
            JobPost(
              id: item['id'] as String,
              title: item['title'] as String? ?? '',
              description: item['description'] as String? ?? '',
              categoryIdNum: item['category_id'] as int? ?? 0,
              subCategoryId: item['sub_category_id'] as int?,
              location: item['location'] as String? ?? '',
              salaryMin: item['salary_min'] as int? ?? 0,
              salaryMax: item['salary_max'] as int? ?? 0,
              company: fullName.isEmpty ? 'Kompaniya' : fullName,
              companyLogo: user?['profile_photo_url'] as String?,
              userId: item['user_id'] as String? ?? '',
              views: item['views_count'] as int? ?? 0,
              likes: item['likes_count'] as int? ?? 0,
              createdAt: DateTime.parse(item['created_at'] as String),
              imageUrls: imageUrls,
              requirementsMain: item['requirements_main'] as String?,
              requirementsBasic: item['requirements_basic'] as String?,
            ),
          );
        } catch (e) {
          print('Search result parse error: $e');
        }
      }

      posts.value = searchResults;
    } catch (e) {
      print('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    pageController.removeListener(_onPageScroll);
    pageController.dispose();
    super.onClose();
  }
}
