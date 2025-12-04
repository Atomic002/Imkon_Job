import 'package:flutter/material.dart';
import 'package:flutter_application_2/Models/job_post.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Shares tracking
  Future<void> recordShare(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      String? deviceId;
      if (userId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      }

      await supabase.from('post_shares').insert({
        'post_id': postId,
        'user_id': userId,
        'device_id': deviceId,
        'shared_at': DateTime.now().toIso8601String(),
      });

      // Update local count
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        posts[index].shares++;
        posts.refresh();
      }
    } catch (e) {
      print('Share tracking error: $e');
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

    final validUrls = <String>[];

    for (var img in images) {
      try {
        String imagePath = img['image_url'] as String? ?? '';
        if (imagePath.isEmpty) continue;

        String path = imagePath;

        // Agar URL bo'lsa, path'ni ajratib olish
        if (imagePath.startsWith('http')) {
          final uri = Uri.parse(imagePath);
          if (uri.pathSegments.length > 2) {
            path = uri.pathSegments.sublist(2).join('/');
          }
        }

        try {
          // ✅ Signed URL yaratish
          final signedUrl = await supabase.storage
              .from('post-images')
              .createSignedUrl(path, 86400);

          if (signedUrl.isNotEmpty) {
            validUrls.add(signedUrl);
          }
        } catch (e) {
          // ✅ Signed URL ishlamasa, Public URL
          try {
            final publicUrl = supabase.storage
                .from('post-images')
                .getPublicUrl(path);

            if (publicUrl.isNotEmpty) {
              validUrls.add(publicUrl);
            }
          } catch (e2) {
            print('⚠️ Image not found: $path');
          }
        }
      } catch (e) {
        print('⚠️ Image processing error: $e');
      }
    }

    return validUrls.isNotEmpty ? validUrls : null;
  }

  // ==================== LOAD POSTS (ONLINE ONLY) ====================
  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      currentOffset = 0;
      hasMorePosts = true;

      print('🔄 Postlar yuklanmoqda (Online)...');

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
            phone_number,
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
          await _convertImageUrls(images);

          final post = JobPost.fromJson(item);
          loadedPosts.add(post);
        } catch (e) {
          print('❌ Post convert error: $e');
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
      hasMorePosts = false;

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
