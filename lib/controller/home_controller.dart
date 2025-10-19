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

  final supabase = Supabase.instance.client;

  // ✅ Categories
  final categories = [
    {'id': 'all', 'name': 'all_categories', 'icon': '🌐'},
    {'id': 'it', 'name': 'it', 'icon': '💻'},
    {'id': 'construction', 'name': 'construction', 'icon': '🏗️'},
    {'id': 'education', 'name': 'education', 'icon': '📚'},
    {'id': 'service', 'name': 'service', 'icon': '🛎️'},
    {'id': 'transport', 'name': 'transport', 'icon': '🚗'},
  ];

  get filteredPosts => null;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  // ==================== LOAD POSTS FROM SUPABASE ====================
  Future<void> loadPosts() async {
    try {
      isLoading.value = true;

      // ✅ Supabase query
      final response = await supabase
          .from('posts')
          .select()
          .eq('status', 'approved')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(50);

      print('📊 Response: $response');
      print('📊 Response type: ${response.runtimeType}');

      // ✅ Empty check
      if (response == null || (response is List && response.isEmpty)) {
        print('⚠️ Response bo\'sh');
        posts.value = [];
        return;
      }

      // ✅ Convert to JobPost
      final loadedPosts = <JobPost>[];

      if (response is List) {
        for (var item in response) {
          try {
            final post = JobPost.fromJson(item as Map<String, dynamic>);
            loadedPosts.add(post);
          } catch (e) {
            print('❌ Post convert error: $e');
            print('❌ Item: $item');
          }
        }
      }

      posts.value = loadedPosts;
      print('✅ ${posts.length} ta post yuklandi');

      // ✅ Initialize liked posts
      for (var post in posts) {
        likedPosts[post.id] = false;
      }

      // ✅ Check user likes
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

  // ==================== CHECK USER LIKES ====================
  Future<void> checkUserLikes() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // ✅ User likes ni olish
      final likedPostIds = await supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId);

      if (likedPostIds is List) {
        for (var like in likedPostIds) {
          final postId = like['post_id'] as String?;
          if (postId != null) {
            likedPosts[postId] = true;
          }
        }
        likedPosts.refresh();
      }
    } catch (e) {
      print('Check likes error: $e');
    }
  }

  // ==================== SELECT CATEGORY ====================
  void selectCategory(String categoryId) {
    selectedCategory.value = categoryId;
    // Keyinroq filter logic qo'shish mumkin
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

      // ✅ Local state update
      final wasLiked = likedPosts[postId] ?? false;
      likedPosts[postId] = !wasLiked;

      // ✅ Find post
      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        if (!wasLiked) {
          // ✅ LIKE
          posts[postIndex].likes++;

          // Supabase insert
          await supabase
              .from('post_likes')
              .insert({'post_id': postId, 'user_id': userId})
              .onError((error, stackTrace) {
                // Revert
                likedPosts[postId] = wasLiked;
                posts[postIndex].likes--;
                print('Like insert error: $error');
              });
        } else {
          // ✅ UNLIKE
          posts[postIndex].likes--;

          // Supabase delete
          await supabase
              .from('post_likes')
              .delete()
              .eq('post_id', postId)
              .eq('user_id', userId)
              .onError((error, stackTrace) {
                // Revert
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
      });

      print('✅ View recorded for post: $postId');
    } catch (e) {
      print('⚠️ Record view error: $e');
      // Don't show error to user - this is not critical
    }
  }

  // ==================== REFRESH POSTS ====================
  Future<void> refreshPosts() async {
    await loadPosts();
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
          .select()
          .eq('status', 'approved')
          .ilike('title', '%$query%')
          .order('created_at', ascending: false)
          .limit(50);

      if (response is List) {
        posts.value = response
            .map((p) => JobPost.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
