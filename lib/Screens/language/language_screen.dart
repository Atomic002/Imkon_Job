import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:version1/controller/language_controller.dart';
import '../../config/constants.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanguageController());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'select_language'.tr,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Выберите язык • Choose language',
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.languages.length,
                  itemBuilder: (context, index) {
                    final lang = controller.languages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusLarge,
                        ),
                        child: InkWell(
                          onTap: () {
                            controller.changeLanguage(lang['code'] as String);
                            Get.offNamed('/login');
                          },
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusLarge,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppConstants.borderColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusLarge,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  lang['flag'] as String,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  lang['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppConstants.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
