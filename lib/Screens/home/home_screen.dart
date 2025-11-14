import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:version1/Widgets/post_card.dart';
import 'package:version1/controller/home_controller.dart';
import '../../config/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(controller),
            Expanded(
              child: Obx(() {
                // Loading state
                if (controller.isLoading.value && controller.posts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Empty state
                if (controller.posts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.refreshPosts,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_outline_rounded,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'E\'lonlar topilmadi',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: controller.refreshPosts,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Yangilash'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Posts PageView - Simple vertical scroll
                return PageView.builder(
                  controller: controller.pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (index) {
                    controller.currentPostIndex.value = index;
                    if (index < controller.posts.length) {
                      controller.recordPostView(controller.posts[index].id);
                    }
                  },
                  itemCount: controller.posts.length,
                  itemBuilder: (context, index) {
                    final post = controller.posts[index];
                    return PostCard(
                      post: post,
                      onLike: () => controller.toggleLike(post.id),
                      isLiked: controller.likedPosts[post.id] ?? false,
                      onTap: () {
                        _showPostDetails(context, post, controller);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ==================== SHOW POST DETAILS ====================
  void _showPostDetails(
    BuildContext context,
    dynamic post,
    HomeController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Full description and details
                    Text(
                      post.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Yopish',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  Widget _buildAppBar(HomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: AppConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/Logotip/image.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Agar rasm topilmasa, default icon
                return const Icon(
                  Icons.work_rounded,
                  size: 24,
                  color: AppConstants.primaryColor,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // JobHub text
          const Text(
            'Imknon Job',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 26),
            onPressed: () {
              controller.refreshPosts();
            },
            color: AppConstants.textSecondary,
            tooltip: 'Yangilash',
          ),
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () {
                  try {
                    Get.toNamed('/notifications');
                  } catch (e) {
                    Get.snackbar(
                      'Xato',
                      'Bildirishnomalar sahifasi topilmadi',
                      backgroundColor: Colors.orange,
                    );
                  }
                },
                color: AppConstants.textSecondary,
              ),
              Obx(() {
                final count = controller.notificationCount.value;
                if (count == 0) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppConstants.errorColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM NAV ====================
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'home'.tr,
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.search_rounded,
                label: 'search'.tr,
                isActive: false,
                onTap: () {
                  try {
                    Get.toNamed('/search');
                  } catch (e) {
                    Get.snackbar(
                      'Xato',
                      'Qidiruv sahifasi topilmadi',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
              _buildAddButton(),
              _buildNavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'messages'.tr,
                isActive: false,
                onTap: () {
                  try {
                    Get.toNamed('/chat');
                  } catch (e) {
                    Get.snackbar(
                      'Xato',
                      'Chat sahifasi topilmadi',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'profile'.tr,
                isActive: false,
                onTap: () {
                  try {
                    Get.toNamed('/profile');
                  } catch (e) {
                    Get.snackbar(
                      'Xato',
                      'Profil sahifasi topilmadi',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== NAV ITEM ====================
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondary,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? AppConstants.primaryColor
                      : AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ADD BUTTON ====================
  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            try {
              Get.toNamed('/create_post');
            } catch (e) {
              Get.snackbar(
                'Xato',
                'E\'lon yaratish sahifasi topilmadi',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            }
          },
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
