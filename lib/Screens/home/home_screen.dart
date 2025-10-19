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
            _buildAppBar(),
            // ❌ Category filter olib tashlandi
            Expanded(
              child: Obx(() {
                // Loading state
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Empty state
                if (controller.posts.isEmpty) {
                  return Center(
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
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Posts PageView - Carousel Slider
                return PageView.builder(
                  controller: controller.pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (index) {
                    controller.currentPostIndex.value = index;
                    // ✅ View recording qo'shildi
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
                      // ✅ Post detail-ga o'tish
                      onTap: () {
                        Get.toNamed('/post_detail', arguments: post);
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

  Widget _buildAppBar() {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppConstants.primaryGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: const Icon(
              Icons.work_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'JobHub',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const Spacer(),
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
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
                color: AppConstants.textSecondary,
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConstants.errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                'Create post sahifasi topilmadi',
                backgroundColor: Colors.orange,
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
