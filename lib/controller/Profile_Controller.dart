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
    String? email,
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
              .split('user-pictures/')[1]
              .split('?')[0];
          await supabase.storage.from('user-pictures').remove([oldPath]);
        } catch (e) {
          print('⚠️ Old photo delete error: $e');
        }
      }

      // Yangi rasmni yuklash
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage
          .from('user-pictures')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Public URL olish
      final imageUrl = supabase.storage
          .from('user-pictures')
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
              .split('user-pictures/')[1]
              .split('?')[0];
          await supabase.storage.from('user-pictures').remove([path]);
        } catch (e) {
          print('⚠️ Photo delete error: $e');
        }
      }

      await supabase
          .from('users')
          .update({
            'user_photo_url': null,
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

  // ==================== UPDATE PHONE NUMBER ====================
  Future<bool> updatePhoneNumber(String newPhone, String password) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Parolni tekshirish
      final email = user.value?.email ?? '';
      final authResult = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResult.user == null) {
        Get.snackbar(
          'error'.tr,
          'incorrect_password'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Telefon raqam bandligini tekshirish
      final existing = await supabase
          .from('users')
          .select()
          .eq('phone_number', newPhone)
          .maybeSingle();

      if (existing != null) {
        Get.snackbar(
          'error'.tr,
          'phone_already_exists'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Telefon raqamni yangilash
      await supabase
          .from('users')
          .update({
            'phone_number': newPhone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'success'.tr,
        'phone_updated'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update phone error: $e');
      Get.snackbar(
        'error'.tr,
        'phone_update_failed'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UPDATE PASSWORD ====================
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    try {
      isLoading.value = true;

      final email = user.value?.email ?? '';

      // Eski parolni tekshirish
      final authResult = await supabase.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );

      if (authResult.user == null) {
        Get.snackbar(
          'error'.tr,
          'incorrect_old_password'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Yangi parolni o'rnatish
      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      Get.snackbar(
        'success'.tr,
        'password_updated'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update password error: $e');
      Get.snackbar(
        'error'.tr,
        'password_update_failed'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UPDATE USER TYPE ====================
  Future<bool> updateUserType(String newUserType) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase
          .from('users')
          .update({
            'user_type': newUserType,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'success'.tr,
        'user_type_updated'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update user type error: $e');
      Get.snackbar(
        'error'.tr,
        'user_type_update_failed'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UPDATE POST ====================
  // ==================== UPDATE POST (TO'LIQ VERSIYA) ====================
  Future<bool> updatePost({
    required String postId,
    required String title,
    required String description,
    required String location,
    required int salaryMin,
    required int salaryMax,
    String? salaryType,
    String? postType,
    int? categoryId,
    int? subCategoryId,
    String? requirementsMain,
    String? requirementsBasic,
    String? skills,
    String? experience,
    String? phoneNumber,
  }) async {
    try {
      isLoading.value = true;

      final updateData = {
        'title': title.trim(),
        'description': description.trim(),
        'location': location.trim(),
        'salary_min': salaryMin,
        'salary_max': salaryMax,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Ixtiyoriy fieldlar
      if (salaryType != null) updateData['salary_type'] = salaryType;
      if (postType != null) updateData['post_type'] = postType;
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (subCategoryId != null) updateData['sub_category_id'] = subCategoryId;
      if (requirementsMain != null)
        updateData['requirements_main'] = requirementsMain.trim();
      if (requirementsBasic != null)
        updateData['requirements_basic'] = requirementsBasic.trim();
      if (skills != null) updateData['skills'] = skills.trim();
      if (experience != null) updateData['experience'] = experience.trim();
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;

      await supabase.from('posts').update(updateData).eq('id', postId);

      await loadUserPosts();
      calculateStats();

      Get.snackbar(
        'Muvaffaqiyatli',
        'E\'lon yangilandi!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update post error: $e');
      Get.snackbar(
        'Xatolik',
        'E\'lonni yangilashda xato',
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

  // ==================== RESTORE POST (Tarixdan qaytarish) ====================
  Future<bool> restorePost(String postId) async {
    try {
      isLoading.value = true;

      await supabase
          .from('posts')
          .update({
            'status': 'approved',
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId);

      await loadUserPosts();
      calculateStats();

      Get.snackbar(
        'Muvaffaqiyatli',
        'E\'lon qayta faollashtirildi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Restore post error: $e');
      Get.snackbar(
        'Xatolik',
        'E\'lonni qaytarishda xato',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== MARK POST AS COMPLETED ====================
  Future<bool> markPostAsCompleted(String postId, String? applicantId) async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // ✅ FAQAT STATUS O'ZGARTIRISH
      await supabase
          .from('posts')
          .update({
            'status': 'successfully_completed',
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId);

      // ❌ BU QATORLARNI O'CHIRING (completed_posts jadvaliga qo'shish kerak emas)
      // await supabase.from('completed_posts').insert({...});

      await loadUserPosts();
      calculateStats();

      Get.snackbar(
        'Muvaffaqiyatli',
        'E\'lon bajarilgan deb belgilandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Mark completed error: $e');
      Get.snackbar(
        'Xatolik',
        'Xato: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== GET COMPLETED POSTS ====================
  Future<List<JobPost>> getCompletedPosts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await supabase
          .from('posts') // ✅ TO'G'RIDAN-TO'G'RI posts jadvalidan
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
          .eq('status', 'successfully_completed') // ✅ Status bo'yicha filter
          .order('updated_at', ascending: false);

      return (response as List)
          .map((item) => JobPost.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Get completed posts error: $e');
      return [];
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

  // ==================== DELETE ACCOUNT ====================
  Future<bool> deleteAccount(String password) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      final email = user.value?.email;

      if (userId == null || email == null) {
        Get.snackbar(
          'Xato',
          'Foydalanuvchi topilmadi!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // 1. Parolni tekshirish
      try {
        final authResult = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (authResult.user == null) {
          Get.snackbar(
            'Xato',
            'Parol noto\'g\'ri!',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
      } catch (e) {
        Get.snackbar(
          'Xato',
          'Parol noto\'g\'ri!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // 2. Postlarni o'chirish
      try {
        await supabase.from('posts').delete().eq('user_id', userId);
        print('✅ Posts deleted');
      } catch (e) {
        print('⚠️ Posts delete error: $e');
      }

      // 3. Saved posts ni o'chirish (agar jadval mavjud bo'lsa)
      try {
        await supabase.from('saved_posts').delete().eq('user_id', userId);
        print('✅ Saved posts deleted');
      } catch (e) {
        print('⚠️ Saved posts delete error (maybe table doesn\'t exist): $e');
        // Xato bo'lsa ham davom etamiz
      }

      // 4. Profile rasmini o'chirish
      if (user.value?.profilePhotoUrl != null) {
        try {
          final path = user.value!.profilePhotoUrl!
              .split('profile_pictures/')[1]
              .split('?')[0];
          await supabase.storage.from('profile_pictures').remove([path]);
          print('✅ Profile photo deleted');
        } catch (e) {
          print('⚠️ Photo delete error: $e');
        }
      }

      // 5. Users jadvalidan o'chirish
      try {
        await supabase.from('users').delete().eq('id', userId);
        print('✅ User data deleted');
      } catch (e) {
        print('❌ User delete error: $e');
        Get.snackbar(
          'Xato',
          'Foydalanuvchi ma\'lumotlarini o\'chirishda xato',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // 6. Auth dan o'chirish (agar admin API mavjud bo'lsa)
      try {
        // Admin API mavjud bo'lsa
        await supabase.auth.admin.deleteUser(userId);
        print('✅ Auth user deleted');
      } catch (e) {
        print('⚠️ Auth delete error (might need admin): $e');
        // Oddiy logout qilamiz
        await supabase.auth.signOut();
      }

      clearData();

      Get.snackbar(
        'Muvaffaqiyatli',
        'Akkaunt muvaffaqiyatli o\'chirildi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      print('❌ Delete account error: $e');
      Get.snackbar(
        'Xato',
        'Akkauntni o\'chirishda xato yuz berdi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isLoading.value = false;
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
