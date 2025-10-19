import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:version1/controller/Profile_Controller.dart';
import 'package:version1/controller/auth_controller.dart';
import '../../config/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.put(ProfileController());

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final user = profileController.user.value;

          // Loading state
          if (profileController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // User null bo'lsa
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_rounded,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login qiling',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Login sahifasiga o'tish
                      if (Get.currentRoute != '/login') {
                        Get.toNamed('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          // User data mavjud
          return Column(
            children: [
              // ==================== HEADER ====================
              Container(
                decoration: const BoxDecoration(
                  gradient: AppConstants.primaryGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'profile'.tr,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _showSettingsDialog(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Profile avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: user.profilePhotoUrl != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      user.profilePhotoUrl!,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: AppConstants.primaryColor,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@${user.username}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.badge_rounded,
                                        size: 16,
                                        color: AppConstants.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.userType == 'job_seeker'
                                            ? 'Ish qidiruvchi'
                                            : 'Ish beruvchi',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ==================== CONTENT ====================
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  children: [
                    _buildStatCard(profileController),
                    const SizedBox(height: 20),
                    _buildBioCard(user.bio),
                    const SizedBox(height: 20),
                    if (user.location != null) ...[
                      _buildLocationCard(user.location!),
                      const SizedBox(height: 20),
                    ],
                    _buildMenuSection(context),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ==================== SETTINGS DIALOG ====================
  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Row(
                children: [
                  const Text(
                    'Sozlamalar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Settings list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                ),
                children: [
                  _buildSettingItem(
                    Icons.language,
                    'Til',
                    'O\'zbekcha',
                    onTap: () {
                      Get.back();
                      _showLanguageDialog(context);
                    },
                  ),
                  _buildSettingItem(
                    Icons.notifications_outlined,
                    'Bildirishnomalar',
                    'Yoqilgan',
                    onTap: () {
                      Get.back();
                      Get.snackbar(
                        'Sozlamalar',
                        'Bildirishnomalar sozlamalari',
                      );
                    },
                  ),
                  _buildSettingItem(
                    Icons.privacy_tip_outlined,
                    'Maxfiylik',
                    '',
                    onTap: () {
                      Get.back();
                      Get.snackbar('Sozlamalar', 'Maxfiylik sozlamalari');
                    },
                  ),
                  _buildSettingItem(
                    Icons.help_outline,
                    'Yordam',
                    '',
                    onTap: () {
                      Get.back();
                      Get.snackbar('Yordam', 'Yordam markazi tez kunda');
                    },
                  ),
                  _buildSettingItem(
                    Icons.info_outline,
                    'Ilova haqida',
                    'v1.0.0',
                    onTap: () {
                      Get.back();
                      _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String trailing, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppConstants.textSecondary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              if (trailing.isNotEmpty)
                Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppConstants.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tilni tanlang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('O\'zbekcha'),
              leading: Radio(
                value: 'uz',
                groupValue: 'uz',
                onChanged: (val) {},
              ),
            ),
            ListTile(
              title: const Text('Русский'),
              leading: Radio(
                value: 'ru',
                groupValue: 'uz',
                onChanged: (val) {},
              ),
            ),
            ListTile(
              title: const Text('English'),
              leading: Radio(
                value: 'en',
                groupValue: 'uz',
                onChanged: (val) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JobHub'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versiya: 1.0.0'),
            SizedBox(height: 8),
            Text('Ish topish va ishchi yollash platformasi'),
            SizedBox(height: 16),
            Text(
              '© 2025 JobHub. Barcha huquqlar himoyalangan.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Yopish')),
        ],
      ),
    );
  }

  // ==================== STAT CARD ====================
  Widget _buildStatCard(ProfileController controller) {
    return Obx(() {
      final postCount = controller.userPosts.length;
      final likes = controller.userPosts.fold(
        0,
        (sum, post) => sum + post.likes,
      );
      final views = controller.userPosts.fold(
        0,
        (sum, post) => sum + post.views,
      );

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('$postCount', 'Postlar'),
            Container(width: 1, height: 40, color: AppConstants.borderColor),
            _buildStatItem('$views', 'Ko\'rishlar'),
            Container(width: 1, height: 40, color: AppConstants.borderColor),
            _buildStatItem('$likes', 'Yoqtirishlar'),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==================== BIO CARD ====================
  Widget _buildBioCard(String? bio) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Haqida',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio ?? 'Haqida ma\'lumot yo\'q',
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LOCATION CARD ====================
  Widget _buildLocationCard(String location) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppConstants.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MENU SECTION ====================
  Widget _buildMenuSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menyu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            Icons.edit_outlined,
            'Profilni tahrirlash',
            onTap: () {
              // Edit profile dialog
              _showEditProfileDialog(context);
            },
          ),
          _buildMenuItem(
            Icons.add_rounded,
            'E\'lon yaratish',
            onTap: () {
              // Check if route exists
              if (Get.currentRoute != '/create_post') {
                try {
                  Get.toNamed('/create_post');
                } catch (e) {
                  Get.snackbar(
                    'Xatolik',
                    'E\'lon yaratish sahifasi topilmadi',
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                }
              }
            },
          ),
          _buildMenuItem(
            Icons.work_history_outlined,
            'Mening e\'lonlarim',
            onTap: () {
              _showMyPostsDialog(context);
            },
          ),
          _buildMenuItem(
            Icons.bookmark_outlined,
            'Saqlangan',
            onTap: () {
              Get.snackbar(
                'Tez kunda',
                'Saqlangan e\'lonlar funksiyasi ishlab chiqilmoqda',
              );
            },
          ),
          _buildMenuItem(
            Icons.logout_rounded,
            'Chiqish',
            color: AppConstants.errorColor,
            onTap: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Chiqishni tasdiqlang'),
                  content: const Text('Haqiqatan ham chiqmoqchimisiz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Bekor qilish'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        try {
                          final authController = Get.find<AuthController>();
                          authController.logout();
                        } catch (e) {
                          Get.snackbar(
                            'Xatolik',
                            'Chiqishda xatolik yuz berdi',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text(
                        'Ha, chiqish',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    Get.snackbar(
      'Tez kunda',
      'Profilni tahrirlash funksiyasi ishlab chiqilmoqda',
      backgroundColor: AppConstants.primaryColor,
      colorText: Colors.white,
    );
  }

  void _showMyPostsDialog(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXLarge),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mening e\'lonlarim',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (profileController.userPosts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_off_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'E\'lonlar yo\'q',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: profileController.userPosts.length,
                  itemBuilder: (context, index) {
                    final post = profileController.userPosts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.work,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        title: Text(
                          post.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${post.views} ko\'rishlar • ${post.likes} yoqtirishlar',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Tahrirlash'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'O\'chirish',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              Get.dialog(
                                AlertDialog(
                                  title: const Text('O\'chirishni tasdiqlang'),
                                  content: const Text(
                                    'Bu e\'lonni o\'chirmoqchimisiz?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: const Text('Bekor qilish'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Get.back();
                                        Get.back();
                                        Get.snackbar(
                                          'Muvaffaqiyatli',
                                          'E\'lon o\'chirildi',
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        'O\'chirish',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color ?? AppConstants.textSecondary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: color ?? AppConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: color ?? AppConstants.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
