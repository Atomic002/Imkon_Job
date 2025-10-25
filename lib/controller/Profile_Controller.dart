import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/job_post.dart';
import 'package:version1/Models/user_model.dart';

class ProfileController extends GetxController {
  final user = Rxn<UserModel>();
  final userPosts = <JobPost>[].obs;
  final isLoading = false.obs;
  final stats = <String, int>{'posts': 0, 'views': 0, 'likes': 0}.obs;

  final supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  // ==================== LOAD USER DATA ====================
  Future<void> loadUserData() async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ User not logged in');
        user.value = null;
        return;
      }

      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      user.value = UserModel.fromJson(response);
      print('✅ User loaded: ${user.value?.fullName}');

      await loadUserPosts();
      calculateStats();
    } catch (e) {
      print('❌ Load user data error: $e');
      user.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== LOAD USER POSTS (FIXED) ====================
  Future<void> loadUserPosts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // ✅ 'posts' jadvalidan ma'lumot olish
      final response = await supabase
          .from('posts')
          .select('''
            *,
            users!inner(
              id,
              first_name,
              last_name,
              username,
              profile_photo_url
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      userPosts.value = (response as List)
          .map((p) => JobPost.fromJson(p as Map<String, dynamic>))
          .toList();

      print('✅ ${userPosts.length} ta post yuklandi');
    } catch (e) {
      print('❌ Load posts error: $e');
      userPosts.value = [];
    }
  }

  // ==================== CALCULATE STATS ====================
  void calculateStats() {
    int totalViews = 0;
    int totalLikes = 0;

    for (var post in userPosts) {
      totalViews += post.views;
      totalLikes += post.likes;
    }

    stats.value = {
      'posts': userPosts.length,
      'views': totalViews,
      'likes': totalLikes,
    };
  }

  // ==================== UPDATE PROFILE ====================
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? bio,
    String? location,
  }) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.snackbar(
          'error'.tr,
          'user_not_found'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      await supabase
          .from('users')
          .update({
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'bio': bio?.trim(),
            'location': location?.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'success'.tr,
        'profile_updated'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update profile error: $e');
      Get.snackbar(
        'error'.tr,
        'update_failed'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UPLOAD PROFILE PHOTO (FIXED) ====================
  Future<bool> uploadProfilePhoto(File imageFile) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Eski rasmni o'chirish
      if (user.value?.profilePhotoUrl != null) {
        try {
          final oldPath = user.value!.profilePhotoUrl!
              .split('profile_pictures/')[1]
              .split('?')[0];
          await supabase.storage.from('profile_pictures').remove([oldPath]);
        } catch (e) {
          print('⚠️ Old photo delete error: $e');
        }
      }

      // Yangi rasmni yuklash
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage
          .from('profile_pictures')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Public URL olish
      final imageUrl = supabase.storage
          .from('profile_pictures')
          .getPublicUrl(fileName);

      // Database yangilash
      await supabase
          .from('users')
          .update({
            'profile_photo_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'success'.tr,
        'photo_updated'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Upload photo error: $e');
      Get.snackbar(
        'error'.tr,
        'photo_upload_failed'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== DELETE PROFILE PHOTO ====================
  Future<bool> deleteProfilePhoto() async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      if (user.value?.profilePhotoUrl != null) {
        try {
          final path = user.value!.profilePhotoUrl!
              .split('profile_pictures/')[1]
              .split('?')[0];
          await supabase.storage.from('profile_pictures').remove([path]);
        } catch (e) {
          print('⚠️ Photo delete error: $e');
        }
      }

      await supabase
          .from('users')
          .update({
            'profile_photo_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'success'.tr,
        'photo_deleted'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Delete photo error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UPDATE POST ====================
  Future<bool> updatePost({
    required String postId,
    required String title,
    required String description,
    required String location,
    required int salaryMin,
    required int salaryMax,
  }) async {
    try {
      isLoading.value = true;

      await supabase
          .from('posts')
          .update({
            'title': title.trim(),
            'description': description.trim(),
            'location': location.trim(),
            'salary_min': salaryMin,
            'salary_max': salaryMax,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId);

      await loadUserPosts();
      calculateStats();

      Get.snackbar(
        'success'.tr,
        'post_updated'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Update post error: $e');
      Get.snackbar(
        'error'.tr,
        'post_update_failed'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== DELETE POST ====================
  Future<bool> deletePost(String postId) async {
    try {
      isLoading.value = true;

      await supabase.from('posts').delete().eq('id', postId);

      userPosts.removeWhere((p) => p.id == postId);
      calculateStats();

      Get.snackbar(
        'success'.tr,
        'post_deleted'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Delete post error: $e');
      Get.snackbar(
        'error'.tr,
        'post_delete_failed'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== GET SAVED POSTS ====================
  Future<List<JobPost>> getSavedPosts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await supabase
          .from('saved_posts')
          .select('''
            posts!inner(
              *,
              users!inner(
                id,
                first_name,
                last_name,
                username,
                profile_photo_url
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final savedPosts = (response as List)
          .map(
            (item) => JobPost.fromJson(item['posts'] as Map<String, dynamic>),
          )
          .toList();

      return savedPosts;
    } catch (e) {
      print('❌ Get saved posts error: $e');
      return [];
    }
  }

  // ==================== SAVE/UNSAVE POST ====================
  Future<bool> savePost(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('saved_posts').insert({
        'user_id': userId,
        'post_id': postId,
      });

      Get.snackbar(
        'success'.tr,
        'post_saved'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Save post error: $e');
      return false;
    }
  }

  Future<bool> unsavePost(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase
          .from('saved_posts')
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);

      Get.snackbar(
        'success'.tr,
        'post_unsaved'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Unsave post error: $e');
      return false;
    }
  }

  // ==================== REFRESH ====================
  Future<void> refreshProfile() async {
    await loadUserData();
  }

  void clearData() {
    user.value = null;
    userPosts.clear();
    stats.value = {'posts': 0, 'views': 0, 'likes': 0};
  }

  @override
  void onClose() {
    clearData();
    super.onClose();
  }
}
