import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/job_post.dart';
import 'package:version1/Models/user_model.dart';

class ProfileController extends GetxController {
  final user = Rxn<UserModel>();
  final userPosts = <JobPost>[].obs;
  final isLoading = false.obs;
  final stats = <String, int>{'posts': 0, 'views': 0, 'likes': 0}.obs;

  final supabase = Supabase.instance.client;
  final storage = GetStorage();

  bool _hasCheckedAuth = false; // ✅ Auth tekshiruv flagі

  @override
  void onInit() {
    super.onInit();
    // ✅ Faqat 1 marta tekshirish
    if (!_hasCheckedAuth) {
      _hasCheckedAuth = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadUserData();
      });
    }
  }

  // ==================== LOAD USER DATA ====================
  Future<void> loadUserData() async {
    // ✅ Agar yuklanayotgan bo'lsa, qayta yuklash kerak emas
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final userId = storage.read('userId');

      if (userId == null || userId.toString().isEmpty) {
        print('❌ User not logged in - redirecting to login');
        user.value = null;
        clearData();

        // ✅ Login sahifasiga o'tkazish
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute != '/login') {
            Get.offAllNamed('/login');
          }
        });
        return;
      }

      print('🔍 Loading user data for ID: $userId');

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

      // ✅ Agar user topilmasa yoki auth xato bo'lsa
      if (e.toString().contains('JWT') ||
          e.toString().contains('PGRST') ||
          e.toString().contains('No rows') ||
          e.toString().contains('not found')) {
        user.value = null;
        clearData();
        await storage.remove('userId');
        await storage.write('isLoggedIn', false);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute != '/login') {
            Get.offAllNamed('/login');
          }
        });
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== LOAD USER POSTS ====================
  Future<void> loadUserPosts() async {
    try {
      final userId = storage.read('userId');
      if (userId == null) return;

      print('📝 Loading posts for user: $userId');

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
    String? firstName,
    String? lastName,
    String? bio,
    String? location,
  }) async {
    try {
      isLoading.value = true;

      final userId = storage.read('userId');
      if (userId == null) {
        Get.snackbar(
          'Xato',
          'User topilmadi',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (firstName != null && firstName.isNotEmpty) {
        updateData['first_name'] = firstName.trim();
      }
      if (lastName != null && lastName.isNotEmpty) {
        updateData['last_name'] = lastName.trim();
      }
      if (bio != null) {
        updateData['bio'] = bio.trim();
      }
      if (location != null) {
        updateData['location'] = location.trim();
      }

      await supabase.from('users').update(updateData).eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'Muvaffaqiyatli',
        'Profil yangilandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update profile error: $e');
      Get.snackbar(
        'Xato',
        'Profilni yangilashda xato',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UPLOAD PROFILE PHOTO ====================
  Future<bool> uploadProfilePhoto(File imageFile) async {
    try {
      isLoading.value = true;

      final userId = storage.read('userId');
      if (userId == null) return false;

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

      final imageUrl = supabase.storage
          .from('user-pictures')
          .getPublicUrl(fileName);

      await supabase
          .from('users')
          .update({
            'profile_photo_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'Muvaffaqiyatli',
        'Rasm yangilandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Upload photo error: $e');
      Get.snackbar(
        'Xato',
        'Rasm yuklanmadi',
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

      final userId = storage.read('userId');
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
            'profile_photo_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'Muvaffaqiyatli',
        'Rasm o\'chirildi',
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

      final userId = storage.read('userId');
      if (userId == null) return false;

      final userResponse = await supabase
          .from('users')
          .select('password')
          .eq('id', userId)
          .single();

      if (userResponse['password'] != password) {
        Get.snackbar(
          'Xato',
          'Parol noto\'g\'ri',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final existing = await supabase
          .from('users')
          .select()
          .eq('phone_number', newPhone)
          .maybeSingle();

      if (existing != null) {
        Get.snackbar(
          'Xato',
          'Bu telefon raqam band',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      await supabase
          .from('users')
          .update({
            'phone_number': newPhone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await loadUserData();

      Get.snackbar(
        'Muvaffaqiyatli',
        'Telefon raqam yangilandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update phone error: $e');
      Get.snackbar(
        'Xato',
        'Telefon yangilanmadi',
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

      final userId = storage.read('userId');
      if (userId == null) return false;

      final userResponse = await supabase
          .from('users')
          .select('password')
          .eq('id', userId)
          .single();

      if (userResponse['password'] != oldPassword) {
        Get.snackbar(
          'Xato',
          'Eski parol noto\'g\'ri',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      await supabase
          .from('users')
          .update({
            'password': newPassword,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      Get.snackbar(
        'Muvaffaqiyatli',
        'Parol yangilandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update password error: $e');
      Get.snackbar(
        'Xato',
        'Parol yangilanmadi',
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

      final userId = storage.read('userId');
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
        'Muvaffaqiyatli',
        'Foydalanuvchi turi yangilandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      return true;
    } catch (e) {
      print('❌ Update user type error: $e');
      Get.snackbar(
        'Xato',
        'Tur yangilanmadi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
        'Muvaffaqiyatli',
        'Post o\'chirildi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Delete post error: $e');
      Get.snackbar(
        'Xato',
        'Post o\'chirilmadi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== RESTORE POST ====================
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
      final userId = storage.read('userId');
      if (userId == null) return false;

      await supabase
          .from('posts')
          .update({
            'status': 'successfully_completed',
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId);

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
      final userId = storage.read('userId');
      if (userId == null) return [];

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
          .eq('status', 'successfully_completed')
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
      final userId = storage.read('userId');
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

  // ==================== SAVE POST ====================
  Future<bool> savePost(String postId) async {
    try {
      final userId = storage.read('userId');
      if (userId == null) return false;

      await supabase.from('saved_posts').insert({
        'user_id': userId,
        'post_id': postId,
      });

      Get.snackbar(
        'Muvaffaqiyatli',
        'Post saqlandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Save post error: $e');
      return false;
    }
  }

  // ==================== UNSAVE POST ====================
  Future<bool> unsavePost(String postId) async {
    try {
      final userId = storage.read('userId');
      if (userId == null) return false;

      await supabase
          .from('saved_posts')
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);

      Get.snackbar(
        'Muvaffaqiyatli',
        'Post o\'chirildi',
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

      final userId = storage.read('userId');
      if (userId == null) {
        Get.snackbar(
          'Xato',
          'Foydalanuvchi topilmadi!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final userResponse = await supabase
          .from('users')
          .select('password')
          .eq('id', userId)
          .single();

      if (userResponse['password'] != password) {
        Get.snackbar(
          'Xato',
          'Parol noto\'g\'ri!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      try {
        await supabase.from('posts').delete().eq('user_id', userId);
        print('✅ Posts deleted');
      } catch (e) {
        print('⚠️ Posts delete error: $e');
      }

      try {
        await supabase.from('saved_posts').delete().eq('user_id', userId);
        print('✅ Saved posts deleted');
      } catch (e) {
        print('⚠️ Saved posts delete error: $e');
      }

      if (user.value?.profilePhotoUrl != null) {
        try {
          final path = user.value!.profilePhotoUrl!
              .split('user-pictures/')[1]
              .split('?')[0];
          await supabase.storage.from('user-pictures').remove([path]);
          print('✅ Profile photo deleted');
        } catch (e) {
          print('⚠️ Photo delete error: $e');
        }
      }

      await supabase.from('users').delete().eq('id', userId);
      print('✅ User data deleted');

      await storage.remove('userId');
      await storage.write('isLoggedIn', false);

      clearData();

      Get.snackbar(
        'Muvaffaqiyatli',
        'Akkaunt muvaffaqiyatli o\'chirildi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/login');
      });

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
    _hasCheckedAuth = false; // ✅ Reset flag
    super.onClose();
  }
}
