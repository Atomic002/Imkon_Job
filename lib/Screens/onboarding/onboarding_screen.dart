import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final items = [
      OnboardingItem(
        title: 'onboarding_title_1'.tr,
        description: 'onboarding_desc_1'.tr,
        icon: Icons.search_rounded,
        color: AppConstants.primaryColor,
      ),
      OnboardingItem(
        title: 'onboarding_title_2'.tr,
        description: 'onboarding_desc_2'.tr,
        icon: Icons.chat_bubble_rounded,
        color: AppConstants.secondaryColor,
      ),
      OnboardingItem(
        title: 'onboarding_title_3'.tr,
        description: 'onboarding_desc_3'.tr,
        icon: Icons.verified_user_rounded,
        color: AppConstants.accentColor,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Get.offNamed('/language'),
                child: Text(
                  'skip'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(items[index]);
                },
              ),
            ),
            _buildIndicator(items.length),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == items.length - 1) {
                      Get.offNamed('/language');
                    } else {
                      _pageController.nextPage(
                        duration: AppConstants.animationNormal,
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == items.length - 1
                        ? 'get_started'.tr
                        : 'next'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 100, color: item.color),
          ),
          const SizedBox(height: 50),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: item.color,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: AppConstants.animationNormal,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppConstants.primaryColor
                : AppConstants.borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
