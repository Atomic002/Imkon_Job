import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:version1/Widgets/custom_button.dart';
import 'package:version1/Widgets/custom_text_field.dart';
import 'package:version1/controller/register_controller.dart';
import '../../config/constants.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => Text('${'step'.tr} ${controller.currentStep.value + 1}/4'),
        ),
      ),
      body: Column(
        children: [
          Obx(
            () => LinearProgressIndicator(
              value: (controller.currentStep.value + 1) / 4,
              backgroundColor: AppConstants.borderColor,
              valueColor: const AlwaysStoppedAnimation(
                AppConstants.primaryColor,
              ),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: PageView(
              controller: controller.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                Step1Personal(),
                Step2Contact(),
                Step3Account(),
                Step4Type(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Step 1: Personal Info
class Step1Personal extends StatelessWidget {
  const Step1Personal({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'personal_info'.tr,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'personal_info_desc'.tr,
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          CustomTextField(
            controller: controller.firstNameController,
            label: 'first_name'.tr,
            hint: 'enter_first_name'.tr,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: controller.lastNameController,
            label: 'last_name'.tr,
            hint: 'enter_last_name'.tr,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 40),
          CustomButton(text: 'next'.tr, onPressed: controller.nextStep),
        ],
      ),
    );
  }
}

// Step 2: Contact Info (phone qismi olib tashlandi)
class Step2Contact extends StatelessWidget {
  const Step2Contact({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'contact_info'.tr,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'contact_info_desc'.tr,
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          CustomTextField(
            controller: controller.emailController,
            label: 'email'.tr,
            hint: 'enter_email'.tr,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'back'.tr,
                  onPressed: controller.previousStep,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'next'.tr,
                  onPressed: controller.nextStep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Step 3: Account Info
class Step3Account extends StatelessWidget {
  const Step3Account({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'account_info'.tr,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'account_info_desc'.tr,
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          CustomTextField(
            controller: controller.usernameController,
            label: 'username'.tr,
            hint: 'enter_username'.tr,
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          CustomTextField(
            controller: controller.bioController,
            label: 'bio'.tr,
            hint: 'enter_bio'.tr,
            icon: Icons.info_outline_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'back'.tr,
                  onPressed: controller.previousStep,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'next'.tr,
                  onPressed: controller.nextStep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Step 4: User Type
class Step4Type extends StatelessWidget {
  const Step4Type({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'account_type'.tr,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'account_type_desc'.tr,
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Obx(
            () => Column(
              children: [
                _buildTypeCard(
                  title: 'individual'.tr,
                  description: 'individual_desc'.tr,
                  icon: Icons.person_outline_rounded,
                  isSelected: controller.userType.value == 'individual',
                  onTap: () => controller.selectUserType('individual'),
                ),
                const SizedBox(height: 16),
                _buildTypeCard(
                  title: 'company'.tr,
                  description: 'company_desc'.tr,
                  icon: Icons.business_outlined,
                  isSelected: controller.userType.value == 'company',
                  onTap: () => controller.selectUserType('company'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'back'.tr,
                  onPressed: controller.previousStep,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'confirm'.tr,
                  onPressed: controller.registerUser, // ✅ shu yer o‘zgardi
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor
                  : AppConstants.borderColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppConstants.textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppConstants.primaryColor,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
