import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: Obx(() => Text('Qadam ${controller.currentStep.value + 1}/5')),
      ),
      body: Column(
        children: [
          Obx(
            () => LinearProgressIndicator(
              value: (controller.currentStep.value + 1) / 5,
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
                Step1AccountType(),
                Step2Personal(),
                Step3Contact(),
                Step4Location(),
                Step5ProfilePhoto(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 1: ACCOUNT TYPE ====================
class Step1AccountType extends StatelessWidget {
  const Step1AccountType({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Akkount turini tanlang',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Siz ish izlayapsizmi yoki xodim qidiryapsizmi?',
            style: TextStyle(fontSize: 16, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: 40),
          Obx(
            () => Column(
              children: [
                _buildTypeCard(
                  title: 'Shaxsiy akkount',
                  description: 'Ish izlayotgan shaxslar uchun',
                  icon: Icons.person_outline_rounded,
                  isSelected: controller.userType.value == 'individual',
                  onTap: () => controller.selectUserType('individual'),
                ),
                const SizedBox(height: 16),
                _buildTypeCard(
                  title: 'Kompaniya akkaunt',
                  description: 'Xodim izlayotgan kompaniyalar uchun',
                  icon: Icons.business_outlined,
                  isSelected: controller.userType.value == 'company',
                  onTap: () => controller.selectUserType('company'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          CustomButton(text: 'Keyingi', onPressed: controller.nextStep),
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

// ==================== STEP 2: PERSONAL INFO ====================
class Step2Personal extends StatelessWidget {
  const Step2Personal({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Obx(() {
        final isCompany = controller.userType.value == 'company';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCompany ? 'Kompaniya ma\'lumotlari' : 'Shaxsiy ma\'lumotlar',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompany
                  ? 'Kompaniya nomi va boshqa ma\'lumotlarni kiriting'
                  : 'Ismingiz va familyangizni kiriting',
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 40),

            if (isCompany) ...[
              // ✅ KOMPANIYA UCHUN
              CustomTextField(
                controller: controller.companyNameController,
                label: 'Kompaniya nomi',
                hint: 'Masalan: IT Solutions LLC',
                icon: Icons.business_outlined,
              ),
            ] else ...[
              // ✅ SHAXS UCHUN
              CustomTextField(
                controller: controller.firstNameController,
                label: 'Ism',
                hint: 'Masalan: Jahongir',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: controller.lastNameController,
                label: 'Familya',
                hint: 'Masalan: Xolmatov',
                icon: Icons.person_outline_rounded,
              ),
            ],

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Orqaga',
                    onPressed: controller.previousStep,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Keyingi',
                    onPressed: controller.nextStep,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

// ==================== STEP 3: CONTACT INFO ====================
class Step3Contact extends StatelessWidget {
  const Step3Contact({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aloqa ma\'lumotlari',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Telefon raqam, email va parolingizni kiriting',
            style: TextStyle(fontSize: 16, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: 40),

          // ✅ TELEFON RAQAM - +998 avtomatik
          TextField(
            controller: controller.phoneController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              controller.phoneFormatter,
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: InputDecoration(
              labelText: 'Telefon raqam',
              hintText: '90 123 45 67',
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '+998 ',
              prefixStyle: const TextStyle(
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(color: AppConstants.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(color: AppConstants.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(
                  color: AppConstants.primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Format: +998 XX XXX XX XX',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ✅ USERNAME
          CustomTextField(
            controller: controller.usernameController,
            label: 'Username',
            hint: 'Masalan: jahongir_dev',
            icon: Icons.alternate_email_rounded,
          ),

          const SizedBox(height: 20),

          // ✅ EMAIL (Ixtiyoriy)

          // ✅ PAROL
          Obx(
            () => CustomTextField(
              controller: controller.passwordController,
              label: 'Parol (kamida 6 ta belgi)',
              hint: '••••••',
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

          // ✅ BIO (Majburiy)
          CustomTextField(
            controller: controller.bioController,
            label: 'Bio (o\'zingiz haqingizda)',
            hint: 'Masalan: Men dasturchi va dizaynerman...',
            icon: Icons.info_outline_rounded,
            maxLines: 3,
          ),

          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Orqaga',
                  onPressed: controller.previousStep,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Keyingi',
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

// ==================== STEP 4: LOCATION (DROPDOWN) ====================
class Step4Location extends StatelessWidget {
  const Step4Location({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manzil ma\'lumotlari',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yashash joyingizni tanlang',
            style: TextStyle(fontSize: 16, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: 40),

          // ✅ VILOYAT DROPDOWN
          Obx(
            () => DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Viloyat',
                prefixIcon: const Icon(Icons.location_city_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: const BorderSide(color: AppConstants.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: const BorderSide(
                    color: AppConstants.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              value: controller.selectedRegion.value.isEmpty
                  ? null
                  : controller.selectedRegion.value,
              hint: const Text('Viloyatni tanlang'),
              items: controller.regions.keys.map((region) {
                return DropdownMenuItem(value: region, child: Text(region));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectRegion(value);
                }
              },
            ),
          ),
          const SizedBox(height: 20),

          // ✅ TUMAN DROPDOWN
          Obx(
            () => DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tuman',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: const BorderSide(color: AppConstants.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: const BorderSide(
                    color: AppConstants.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              value: controller.selectedDistrict.value.isEmpty
                  ? null
                  : controller.selectedDistrict.value,
              hint: const Text('Tumanni tanlang'),
              items: controller.availableDistricts.map((district) {
                return DropdownMenuItem(value: district, child: Text(district));
              }).toList(),
              onChanged: controller.selectedRegion.value.isEmpty
                  ? null
                  : (value) {
                      if (value != null) {
                        controller.selectDistrict(value);
                      }
                    },
            ),
          ),
          const SizedBox(height: 20),

          // ✅ MAHALLA/QISHLOQ DROPDOWN
          Obx(
            () => DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Mahalla/Qishloq',
                prefixIcon: const Icon(Icons.home_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: const BorderSide(color: AppConstants.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: const BorderSide(
                    color: AppConstants.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              value: controller.selectedVillage.value.isEmpty
                  ? null
                  : controller.selectedVillage.value,
              hint: const Text('Mahallani tanlang'),
              items: controller.availableVillages.map((village) {
                return DropdownMenuItem(value: village, child: Text(village));
              }).toList(),
              onChanged: controller.selectedDistrict.value.isEmpty
                  ? null
                  : (value) {
                      if (value != null) {
                        controller.selectVillage(value);
                      }
                    },
            ),
          ),
          const SizedBox(height: 20),

          // ✅ YASHASH MANZILI (Ko'cha, uy)
          CustomTextField(
            controller: controller.addressController,
            label: 'Manzil (ko\'cha, uy raqami)',
            hint: 'Masalan: Amir Temur ko\'chasi, 15-uy',
            icon: Icons.place_outlined,
            maxLines: 2,
          ),

          const SizedBox(height: 20),

          // ✅ TO'LIQ MANZIL PREVIEW
          Obx(() {
            if (controller.selectedRegion.value.isNotEmpty &&
                controller.selectedDistrict.value.isNotEmpty &&
                controller.selectedVillage.value.isNotEmpty &&
                controller.addressController.text.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  border: Border.all(
                    color: AppConstants.primaryColor,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'To\'liq manzil:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${controller.selectedRegion.value}, ${controller.selectedDistrict.value}, ${controller.selectedVillage.value}, ${controller.addressController.text}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Orqaga',
                  onPressed: controller.previousStep,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Keyingi',
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

// ==================== STEP 5: PROFILE PHOTO ====================
class Step5ProfilePhoto extends StatelessWidget {
  const Step5ProfilePhoto({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil rasmi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Profil rasmingizni yuklang (ixtiyoriy)',
            style: TextStyle(fontSize: 16, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: 40),

          // ✅ PHOTO PICKER
          Center(
            child: Obx(() {
              return GestureDetector(
                onTap: controller.pickProfilePhoto,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.primaryColor,
                      width: 3,
                    ),
                  ),
                  child: controller.profilePhotoPath.value.isEmpty
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 50,
                              color: AppConstants.textSecondary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Rasm tanlang',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(90),
                          child: Image.file(
                            File(controller.profilePhotoPath.value),
                            fit: BoxFit.cover,
                            width: 180,
                            height: 180,
                          ),
                        ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // ✅ BUTTONS - Rasm tanlash
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: controller.takePhoto,
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Kamera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppConstants.primaryColor,
                  side: const BorderSide(
                    color: AppConstants.primaryColor,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: controller.chooseFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text('Galereya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Orqaga',
                  onPressed: controller.previousStep,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => CustomButton(
                    text: 'Ro\'yxatdan o\'tish',
                    onPressed: controller.registerUser,
                    isLoading: controller.isLoading.value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
