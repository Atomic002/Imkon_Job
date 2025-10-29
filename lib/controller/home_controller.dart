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

  // 🔥 SCROLL LISTENER - currentPostIndex ni update qilish qo'shildi
  void _onPageScroll() {
    final page = pageController.page?.round() ?? 0;
    if (page != currentPostIndex.value) {
      currentPostIndex.value = page;
    }

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

      notificationCount.value = response.length;
    } catch (e) {
      print('Load notification count error: $e');
    }
  }

  // ==================== HELPER: Convert Image URLs ====================
  Future<List<String>?> _convertImageUrls(List? images) async {
    if (images == null || images.isEmpty) {
      return null;
    }

    final List<Future<String>> urlFutures = images.map<Future<String>>((
      img,
    ) async {
      String imagePath = img['image_url'] as String? ?? '';
      if (imagePath.isEmpty) return '';

      String path = imagePath;
      if (imagePath.startsWith('http')) {
        final uri = Uri.parse(imagePath);
        if (uri.pathSegments.length > 2) {
          path = uri.pathSegments.sublist(2).join('/');
        }
      }

      try {
        final signedUrl = await supabase.storage
            .from('post-images')
            .createSignedUrl(path, 86400);
        return signedUrl;
      } catch (e) {
        print('⚠️ Signed URL yaratishda xato: $e');
        try {
          final publicUrl = supabase.storage
              .from('post-images')
              .getPublicUrl(path);
          return publicUrl;
        } catch (e2) {
          print('⚠️ Public URL olishda xato: $e2');
          return '';
        }
      }
    }).toList();

    final allUrls = await Future.wait(urlFutures);
    return allUrls
        .where((url) => url.isNotEmpty && url.startsWith('http'))
        .toList();
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
            salary_type,
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
            post_type,
            skills,
            experience,
            users!inner(first_name, last_name, profile_photo_url, username),
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
          final images = item['post_images'] as List?;
          final imageUrls = await _convertImageUrls(images);

          if (imageUrls != null && imageUrls.isNotEmpty) {
            print('🖼️ Post ${item['id']}: ${imageUrls.length} ta image');
          }

          final post = JobPost.fromJson(item);
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

      // Initialize liked posts
      for (var post in posts) {
        likedPosts[post.id] = false;
      }

      await checkUserLikes();
    } catch (e) {
      print('❌ Load posts error: $e');
      posts.value = [];
      Get.snackbar(
        'Xato',
        'E\'lonlarni yuklashda xato: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== LOAD MORE POSTS (PAGINATION) ====================
  Future<void> loadMorePosts() async {
    if (isLoadingMore || !hasMorePosts || isLoading.value) return;

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
            salary_type,
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
            post_type,
            skills,
            experience,
            users!inner(first_name, last_name, profile_photo_url, username),
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
          final images = item['post_images'] as List?;
          await _convertImageUrls(images);

          final post = JobPost.fromJson(item);
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
    if (selectedCategory.value != categoryId) {
      selectedCategory.value = categoryId;
      filterPostsByCategory();
    }
  }

  // ==================== FILTER POSTS BY CATEGORY ====================
  Future<void> filterPostsByCategory() async {
    if (selectedCategory.value == 'all') {
      await loadPosts();
      return;
    }

    try {
      isLoading.value = true;

      // Category ID mapping
      final categoryMap = {
        'it': 1,
        'construction': 2,
        'education': 3,
        'service': 4,
        'transport': 5,
      };

      final categoryId = categoryMap[selectedCategory.value];
      if (categoryId == null) {
        await loadPosts();
        return;
      }

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
            salary_type,
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
            post_type,
            skills,
            experience,
            users!inner(first_name, last_name, profile_photo_url, username),
            post_images(image_url)
          ''')
          .eq('status', 'approved')
          .eq('is_active', true)
          .eq('category_id', categoryId)
          .order('created_at', ascending: false)
          .limit(INITIAL_BATCH);

      final filteredPosts = <JobPost>[];
      for (var item in response) {
        try {
          final images = item['post_images'] as List?;
          await _convertImageUrls(images);
          filteredPosts.add(JobPost.fromJson(item));
        } catch (e) {
          print('Filter parse error: $e');
        }
      }

      posts.value = filteredPosts;
      currentOffset = filteredPosts.length;
      hasMorePosts = filteredPosts.length >= INITIAL_BATCH;

      for (var post in posts) {
        likedPosts[post.id] = false;
      }
      await checkUserLikes();
    } catch (e) {
      print('Filter error: $e');
      Get.snackbar(
        'Xato',
        'Kategoriya bo\'yicha filtrlashda xato',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== TOGGLE LIKE ====================
  // ==================== TOGGLE LIKE (IMPROVED) ====================
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
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final wasLiked = likedPosts[postId] ?? false;

      // Optimistic update
      likedPosts[postId] = !wasLiked;

      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        if (!wasLiked) {
          posts[postIndex] = posts[postIndex].copyWith(
            likes: posts[postIndex].likes + 1,
          );

          try {
            await supabase.from('post_likes').upsert({
              'post_id': postId,
              'user_id': userId,
              'created_at': DateTime.now().toIso8601String(),
            }, onConflict: 'post_id,user_id');
          } catch (e) {
            print('❌ Like insert error: $e');
            // Revert changes
            likedPosts[postId] = wasLiked;
            posts[postIndex] = posts[postIndex].copyWith(
              likes: posts[postIndex].likes - 1,
            );
            rethrow;
          }
        } else {
          posts[postIndex] = posts[postIndex].copyWith(
            likes: posts[postIndex].likes - 1,
          );

          try {
            await supabase.from('post_likes').delete().match({
              'post_id': postId,
              'user_id': userId,
            });
          } catch (e) {
            print('❌ Like delete error: $e');
            // Revert changes
            likedPosts[postId] = wasLiked;
            posts[postIndex] = posts[postIndex].copyWith(
              likes: posts[postIndex].likes + 1,
            );
            rethrow;
          }
        }
      }

      posts.refresh();
      likedPosts.refresh();
    } catch (e) {
      print('❌ Toggle like error: $e');

      Get.snackbar(
        'Xato',
        'Like qilishda xato. Iltimos, qayta urinib ko\'ring',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
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
        posts[postIndex] = posts[postIndex].copyWith(
          views: posts[postIndex].views + 1,
        );
        posts.refresh();
      }

      print('✅ View recorded for post: $postId');
    } catch (e) {
      print('⚠️ Record view error: $e');
    }
  }

  // ==================== REFRESH POSTS (PULL TO REFRESH) ====================
  Future<void> refreshPosts() async {
    await loadPosts();
    await loadNotificationCount();
    Get.snackbar(
      '✅ Yangilandi',
      'E\'lonlar muvaffaqiyatli yangilandi',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
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
            id,
            user_id,
            title,
            description,
            category_id,
            sub_category_id,
            location,
            status,
            salary_type,
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
            post_type,
            skills,
            experience,
            users!inner(first_name, last_name, profile_photo_url, username),
            post_images(image_url)
          ''')
          .eq('status', 'approved')
          .eq('is_active', true)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      final searchResults = <JobPost>[];
      for (var item in response) {
        try {
          final images = item['post_images'] as List?;
          await _convertImageUrls(images);

          searchResults.add(JobPost.fromJson(item));
        } catch (e) {
          print('Search result parse error: $e');
        }
      }

      posts.value = searchResults;
      currentOffset = searchResults.length;
      hasMorePosts = false; // Search results don't have pagination

      for (var post in posts) {
        likedPosts[post.id] = false;
      }
      await checkUserLikes();
    } catch (e) {
      print('Search error: $e');
      Get.snackbar(
        'Xato',
        'Qidirishda xato',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
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
