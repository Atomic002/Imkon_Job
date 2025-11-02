import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/job_post.dart';
import 'package:version1/Services/ceche_manager.dart';

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
  final _cache = AppCacheManager(); // ✅ CACHE

  // 🔥 PAGINATION VARIABLES
  static const int INITIAL_BATCH = 30;
  static const int NEXT_BATCH = 20;
  int currentOffset = 0;
  bool hasMorePosts = true;
  bool isLoadingMore = false;

  // ✅ Offline mode
  final isOffline = false.obs;

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

  // ==================== LOAD POSTS (CACHE FIRST) ====================
  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      currentOffset = 0;
      hasMorePosts = true;

      print('🔄 Postlar yuklanmoqda...');

      // 1️⃣ AVVAL KESHDAN YUKLASH
      try {
        final cachedData = await _cache.getCachedPosts();
        if (cachedData != null && cachedData.isNotEmpty) {
          print('✅ Keshdan ${cachedData.length} ta post yuklandi');
          posts.value = cachedData
              .map((json) => JobPost.fromJson(json))
              .toList();
          isLoading.value = false;

          // Liked posts'ni set qilish
          for (var post in posts) {
            likedPosts[post.id] = false;
          }
          await checkUserLikes();

          // Background'da yangilash
          _refreshPostsInBackground();
          return;
        }
      } catch (cacheError) {
        print('⚠️ Keshdan yuklashda xatolik: $cacheError');
      }

      // 2️⃣ SERVERDAN YUKLASH
      await _loadFromServer();
    } catch (e) {
      print('❌ Load posts error: $e');

      // Internet yo'q bo'lsa - keshdan yuklashga harakat qilish
      if (_isNetworkError(e)) {
        isOffline.value = true;
        print('📵 Internet aloqasi yo\'q - Keshdan yuklanyapti...');

        try {
          final cachedData = await _cache.getCachedPosts();
          if (cachedData != null && cachedData.isNotEmpty) {
            posts.value = cachedData
                .map((json) => JobPost.fromJson(json))
                .toList();

            for (var post in posts) {
              likedPosts[post.id] = false;
            }

            Get.snackbar(
              '📵 Offline rejim',
              'Keshdan ${posts.length} ta e\'lon ko\'rsatilmoqda',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange.withOpacity(0.9),
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          } else {
            posts.value = [];
            Get.snackbar(
              '❌ Xato',
              'Internet aloqasi yo\'q va keshda ma\'lumot yo\'q',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        } catch (cacheError) {
          print('❌ Keshdan ham yuklanmadi: $cacheError');
          posts.value = [];
        }
      } else {
        posts.value = [];
        Get.snackbar(
          'Xato',
          'E\'lonlarni yuklashda xato: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== LOAD FROM SERVER ====================
  Future<void> _loadFromServer() async {
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
      isOffline.value = false;

      print('✅ ${posts.length} ta post yuklandi');

      // ✅ KESHGA SAQLASH
      try {
        await _cache.cachePosts(loadedPosts.map((p) => p.toJson()).toList());
        print('💾 Postlar keshga saqlandi');

        // Rasmlarni prefetch qilish
        final imageUrls = loadedPosts
            .where((p) => p.imageUrls != null && p.imageUrls!.isNotEmpty)
            .expand((p) => p.imageUrls!)
            .take(20)
            .toList();

        if (imageUrls.isNotEmpty) {
          _cache.prefetchImages(imageUrls);
        }
      } catch (cacheError) {
        print('⚠️ Keshga saqlashda xatolik: $cacheError');
      }

      // Initialize liked posts
      for (var post in posts) {
        likedPosts[post.id] = false;
      }

      await checkUserLikes();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== BACKGROUND REFRESH ====================
  Future<void> _refreshPostsInBackground() async {
    try {
      print('🔄 Background refresh...');

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

      if (response.isEmpty) return;

      final newPosts = <JobPost>[];
      for (var item in response) {
        try {
          final images = item['post_images'] as List?;
          await _convertImageUrls(images);
          newPosts.add(JobPost.fromJson(item));
        } catch (e) {
          print('❌ Background parse error: $e');
        }
      }

      // Agar yangi postlar bo'lsa - update qilish
      if (newPosts.length != posts.length ||
          (newPosts.isNotEmpty &&
              posts.isNotEmpty &&
              newPosts.first.id != posts.first.id)) {
        posts.value = newPosts;
        isOffline.value = false;

        // Keshni yangilash
        await _cache.cachePosts(newPosts.map((p) => p.toJson()).toList());

        print('✅ Background refresh: ${newPosts.length} ta yangi post');
      }
    } catch (e) {
      print('⚠️ Background refresh error: $e');
    }
  }

  // ==================== CHECK IF NETWORK ERROR ====================
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network') ||
        errorString.contains('connection');
  }

  // ==================== LOAD MORE POSTS (PAGINATION) ====================
  Future<void> loadMorePosts() async {
    if (isLoadingMore || !hasMorePosts || isLoading.value || isOffline.value)
      return;

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
