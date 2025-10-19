import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/job_post.dart';
import 'package:version1/Models/user_model.dart';

class ProfileController extends GetxController {
  // Observable variables
  final user = Rxn<UserModel>();
  final userPosts = <JobPost>[].obs;
  final isLoading = false.obs;
  final stats = <String, int>{'posts': 0, 'views': 0, 'likes': 0}.obs;

  final supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  // ==================== LOAD USER PROFILE ====================
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;

      // 1. Current user ID olish
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('User not logged in');
        return;
      }

      // 2. User ma'lumotlarini olish
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      user.value = UserModel.fromJson(response);
      print('User loaded: ${user.value?.fullName}');

      // 3. User postlarini olish
      await loadUserPosts(userId);

      // 4. Statistikani hisoblash
      calculateStats();
    } catch (e) {
      print('Load profile error: $e');
      Get.snackbar(
        'Xato',
        'Profil yuklashda xato: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== LOAD USER POSTS ====================
  Future<void> loadUserPosts(String userId) async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('user_id', userId)
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      userPosts.value = (response as List)
          .map((p) => JobPost.fromJson(p as Map<String, dynamic>))
          .toList();

      print('${userPosts.length} ta post yuklandi');
    } catch (e) {
      print('Load posts error: $e');
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

    stats['posts'] = userPosts.length;
    stats['views'] = totalViews;
    stats['likes'] = totalLikes;
    stats.refresh();
  }

  // ==================== UPDATE PROFILE ====================
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String bio,
    String? location,
  }) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('users')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'bio': bio,
            'location': location,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Local update
      if (user.value != null) {
        user.value = UserModel(
          id: user.value!.id,
          firstName: firstName,
          lastName: lastName,
          username: user.value!.username,
          email: user.value!.email,
          bio: bio,
          profilePhotoUrl: user.value!.profilePhotoUrl,
          userType: user.value!.userType,
          isEmailVerified: user.value!.isEmailVerified,
          location: location,
          rating: user.value!.rating,
          isActive: user.value!.isActive,
          createdAt: user.value!.createdAt,
        );
        user.refresh();
      }

      Get.snackbar(
        'Muvaffaqiyatli',
        'Profil yangilandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Profil yangilantirishda xato: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UPLOAD PROFILE PHOTO ====================
  Future<void> uploadProfilePhoto(String imagePath) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final fileName = 'profile_$userId.jpg';

      // Supabase Storage ga yuklash
      await supabase.storage
          .from('profiles')
          .upload(
            fileName,
            imagePath as File,
            fileOptions: const FileOptions(upsert: true),
          );

      // Public URL olish
      final publicUrl = supabase.storage
          .from('profiles')
          .getPublicUrl(fileName);

      // Database da yangilash
      await supabase
          .from('users')
          .update({
            'profile_photo_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Local update
      if (user.value != null) {
        user.value = UserModel(
          id: user.value!.id,
          firstName: user.value!.firstName,
          lastName: user.value!.lastName,
          username: user.value!.username,
          email: user.value!.email,
          bio: user.value!.bio,
          profilePhotoUrl: publicUrl,
          userType: user.value!.userType,
          isEmailVerified: user.value!.isEmailVerified,
          location: user.value!.location,
          rating: user.value!.rating,
          isActive: user.value!.isActive,
          createdAt: user.value!.createdAt,
        );
        user.refresh();
      }

      Get.snackbar(
        'Muvaffaqiyatli',
        'Rasm o\'zgartirildi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Rasm yuklashda xato: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== DELETE POST ====================
  Future<void> deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);

      userPosts.removeWhere((p) => p.id == postId);
      calculateStats();

      Get.snackbar(
        'Muvaffaqiyatli',
        'E\'lon o\'chirildi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Xato',
        'E\'lon o\'chirishda xato: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ==================== GET USER RATING ====================
  Future<double> getUserRating() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0.0;

      final response = await supabase
          .from('users')
          .select('rating')
          .eq('id', userId)
          .single();

      return (response['rating'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Get rating error: $e');
      return 0.0;
    }
  }

  // ==================== REFRESH PROFILE ====================
  Future<void> refreshProfile() async {
    await loadUserProfile();
  }
}
