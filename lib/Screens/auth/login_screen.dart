import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:version1/Widgets/custom_button.dart';
import 'package:version1/Widgets/custom_text_field.dart';
import 'package:version1/controller/auth_controller.dart';
import '../../config/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ✅ Title
              Text(
                'welcome'.tr + ' 👋',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Subtitle
              Text(
                'Akkauntingizga kiring',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 50),

              // ✅ USERNAME FIELD
              CustomTextField(
                controller: controller.usernameController,
                label: 'username'.tr,
                hint: 'enter_username'.tr,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),

              // ✅ PASSWORD FIELD
              Obx(
                () => CustomTextField(
                  controller: controller.passwordController,
                  label: 'password'.tr,
                  hint: 'enter_password'.tr,
                  icon: Icons.lock_outline_rounded,
                  obscureText: controller.isPasswordHidden.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppConstants.textSecondary,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ FORGOT PASSWORD
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Forgot password sahifasiga o'tish
                    // Get.toNamed('/forgot-password');
                  },
                  child: Text(
                    'forgot_password'.tr,
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ✅ LOGIN BUTTON
              Obx(
                () => CustomButton(
                  text: 'login'.tr,
                  onPressed: controller.login,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 20),

              // ✅ REGISTER LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'dont_have_account'.tr + ' ',
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed('/register'),
                    child: Text(
                      'register_now'.tr,
                      style: const TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
