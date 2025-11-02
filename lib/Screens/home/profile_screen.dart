import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:version1/controller/Profile_Controller.dart';
import 'package:version1/controller/auth_controller.dart';
import 'package:version1/controller/language_controller.dart';
import '../../config/constants.dart';
import 'dart:io';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.put(ProfileController());
    final languageController = Get.put(LanguageController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Obx(() {
          final user = profileController.user.value;

          if (profileController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

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
                    'login'.tr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'login'.tr,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // HEADER
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
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Get.back(),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => _showSettingsDialog(
                                  context,
                                  languageController,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (user.profilePhotoUrl != null) {
                                print(
                                  '✅ Opening photo: ${user.profilePhotoUrl}',
                                ); // Debug uchun
                                _showFullProfilePhoto(
                                  context,
                                  user.profilePhotoUrl!,
                                );
                              } else {
                                print('❌ No photo URL');
                                _showProfilePhotoOptions(
                                  context,
                                  profileController,
                                );
                              }
                            },
                            onLongPress: () => _showProfilePhotoOptions(
                              context,
                              profileController,
                            ),
                            child: Stack(
                              children: [
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
                                      ? ClipOval(
                                          child: Image.network(
                                            user.profilePhotoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.person_rounded,
                                                  size: 40,
                                                  color:
                                                      AppConstants.primaryColor,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_rounded,
                                          size: 40,
                                          color: AppConstants.primaryColor,
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppConstants.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons
                                          .zoom_in, // ✅ Bu icon bosish mumkinligini ko'rsatadi
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
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

              // CONTENT
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
                    _buildMenuSection(
                      context,
                      profileController,
                      languageController,
                    ),
                    const SizedBox(height: 30),
                    _buildAppInfoSection(),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

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
            _buildStatItem('$postCount', 'posts'.tr, Icons.work_outline),
            Container(width: 1, height: 50, color: AppConstants.borderColor),
            _buildStatItem('$views', 'views'.tr, Icons.visibility_outlined),
            Container(width: 1, height: 50, color: AppConstants.borderColor),
            _buildStatItem('$likes', 'likes'.tr, Icons.favorite_outline),
          ],
        ),
      );
    });
  }

  // ========== FULL USER INFO SECTION ==========

  // ========== TO'LIQ EDIT DIALOG ==========
  // ========== MAIN EDIT PROFILE MENU ==========
  void _showEditProfileMenu(
    BuildContext context,
    ProfileController profileController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // HEADER
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Profilni tahrirlash',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),

            // MENU ITEMS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildEditMenuItem(
                    Icons.person_outline,
                    'edit_name'.tr, // ✅
                    'edit_name_desc'.tr, // ✅
                    Colors.blue,
                    () => _showEditNameDialog(context, profileController),
                  ),
                  const SizedBox(height: 12),

                  _buildEditMenuItem(
                    Icons.phone_outlined,
                    'Telefon raqam',
                    'Telefon raqamingizni o\'zgartirish',
                    Colors.green,
                    () {
                      Get.back();
                      _showEditPhoneDialog(context, profileController);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildEditMenuItem(
                    Icons.lock_outline,
                    'Parol',
                    'Parolingizni o\'zgartirish',
                    Colors.red,
                    () {
                      Get.back();
                      _showEditPasswordDialog(context, profileController);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildEditMenuItem(
                    Icons.badge_outlined,
                    'Akkount turi',
                    'Ish qidiruvchi yoki Ish beruvchi',
                    Colors.purple,
                    () {
                      Get.back();
                      _showEditUserTypeDialog(context, profileController);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildEditMenuItem(
                    Icons.info_outline,
                    'Bio va Manzil',
                    'Qo\'shimcha ma\'lumotlarni o\'zgartirish',
                    Colors.teal,
                    () {
                      Get.back();
                      _showEditBioLocationDialog(context, profileController);
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

  Widget _buildEditMenuItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== 1. EDIT NAME DIALOG ==========
  void _showEditNameDialog(BuildContext context, ProfileController controller) {
    final user = controller.user.value;
    if (user == null) return;

    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.blue),
            SizedBox(width: 12),
            Text('Ism va Familya'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'first_name_label'.tr,
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: 'last_name_label'.tr,
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            onPressed: () async {
              if (firstNameController.text.trim().isEmpty ||
                  lastNameController.text.trim().isEmpty) {
                Get.snackbar(
                  'Xato',
                  'Barcha maydonlarni to\'ldiring!',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              final success = await controller.updateProfile(
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
              );

              if (success) {
                Get.back();
                Get.snackbar(
                  'Muvaffaqiyatli',
                  'Ism va familya yangilandi!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Saqlash', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== 2. EDIT PHONE DIALOG ==========
  void _showEditPhoneDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    final user = controller.user.value;
    if (user == null) return;

    final phoneController = TextEditingController(
      text: user.phoneNumber?.replaceAll('+998', ''),
    );
    final passwordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.green),
            SizedBox(width: 12),
            Text('Telefon raqam'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: InputDecoration(
                labelText: 'Yangi telefon raqam *',
                hintText: '90 123 45 67',
                prefixIcon: const Icon(Icons.phone_outlined),
                prefixText: '+998 ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Parolingiz (tasdiqlash uchun) *',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Xavfsizlik uchun parolingizni kiriting',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
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
            onPressed: () async {
              final phone = phoneController.text.replaceAll(' ', '');
              if (phone.length != 9 || passwordController.text.isEmpty) {
                Get.snackbar(
                  'Xato',
                  'To\'liq telefon raqam va parolni kiriting!',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              final success = await controller.updatePhoneNumber(
                '+998$phone',
                passwordController.text.trim(),
              );

              if (success) {
                Get.back();
                Get.snackbar(
                  'Muvaffaqiyatli',
                  'Telefon raqam yangilandi!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Saqlash', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== 3. EDIT EMAIL DIALOG ==========

  // ========== 4. EDIT PASSWORD DIALOG ==========
  void _showEditPasswordDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 12),
            Text('Parolni o\'zgartirish'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Eski parol *',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yangi parol (kamida 6 ta) *',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yangi parolni tasdiqlang *',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            onPressed: () async {
              if (oldPasswordController.text.isEmpty ||
                  newPasswordController.text.length < 6 ||
                  confirmPasswordController.text.isEmpty) {
                Get.snackbar(
                  'Xato',
                  'Barcha maydonlarni to\'ldiring! Yangi parol kamida 6 ta belgidan iborat bo\'lishi kerak.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                Get.snackbar(
                  'Xato',
                  'Yangi parollar mos kelmayapti!',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              final success = await controller.updatePassword(
                oldPasswordController.text.trim(),
                newPasswordController.text.trim(),
              );

              if (success) {
                Get.back();
                Get.snackbar(
                  'Muvaffaqiyatli',
                  'Parol yangilandi!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Saqlash', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== 5. EDIT USER TYPE DIALOG ==========
  void _showEditUserTypeDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    final user = controller.user.value;
    if (user == null) return;

    final selectedType = (user.userType).obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.badge, color: Colors.purple),
            SizedBox(width: 12),
            Text('Akkount turi'),
          ],
        ),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserTypeOption(
                'Ish qidiruvchi',
                'Ish izlayotgan shaxslar uchun',
                Icons.person_search,
                'job_seeker',
                selectedType.value == 'job_seeker',
                () => selectedType.value = 'job_seeker',
              ),
              const SizedBox(height: 12),
              _buildUserTypeOption(
                'Ish beruvchi',
                'Xodim izlayotgan kompaniyalar uchun',
                Icons.business,
                'employer',
                selectedType.value == 'employer',
                () => selectedType.value = 'employer',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.updateUserType(
                selectedType.value,
              );

              if (success) {
                Get.back();
                Get.snackbar(
                  'Muvaffaqiyatli',
                  'Akkount turi yangilandi!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Saqlash', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption(
    String title,
    String subtitle,
    IconData icon,
    String value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.purple : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.purple : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  // ========== 6. EDIT BIO & LOCATION DIALOG ==========
  void _showEditBioLocationDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    final user = controller.user.value;
    if (user == null) return;

    final bioController = TextEditingController(text: user.bio);
    final locationController = TextEditingController(text: user.location);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Bio va Manzil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Bio (o\'zingiz haqingizda)',
                        hintText: 'Men dasturchi va dizaynerman...',
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Manzil',
                        hintText: 'Toshkent, Chilonzor...',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Bekor qilish'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await controller.updateProfile(
                            bio: bioController.text.trim(),
                            location: locationController.text.trim(),
                            firstName: '',
                            lastName: '',
                          );

                          if (success) {
                            Get.back();
                            Get.snackbar(
                              'Muvaffaqiyatli',
                              'Ma\'lumotlar yangilandi!',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text(
                          'Saqlash',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppConstants.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 24),
        const SizedBox(height: 8),
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
            fontSize: 12,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

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
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'about_haqida'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio ?? 'no_bio'.tr,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    ProfileController profileController,
    LanguageController languageController,
  ) {
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
          Row(
            children: [
              const Icon(
                Icons.menu_rounded,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'menu'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ BU YERDA O'ZGARISH - To'liq edit menu
          _buildMenuItem(
            Icons.edit_outlined,
            'edit_profile'.tr,
            AppConstants.primaryColor,
            onTap: () => _showEditProfileMenu(
              context,
              profileController,
            ), // ✅ TO'LIQ MENU
          ),

          _buildMenuItem(
            Icons.add_circle_outline,
            'create_post'.tr,
            AppConstants.primaryColor,
            onTap: () {
              if (Get.currentRoute != '/create_post') {
                Get.toNamed('/create_post');
              }
            },
          ),
          _buildMenuItem(
            Icons.work_history_outlined,
            'my_posts'.tr,
            AppConstants.primaryColor,
            onTap: () => _showMyPostsDialog(context, profileController),
          ),
          _buildMenuItem(
            Icons.bookmark_outlined,
            'saved_posts'.tr,
            AppConstants.primaryColor,
            onTap: () => _showSavedPostsDialog(context, profileController),
          ),
          _buildMenuItem(
            Icons.history_rounded,
            'Tarix (Muvaffaqiyatli)',
            Colors.green,
            onTap: () => _showCompletedPostsDialog(context, profileController),
          ),
          _buildMenuItem(
            Icons.language,
            'change_language'.tr,
            AppConstants.primaryColor,
            onTap: () => _showLanguageDialog(context, languageController),
          ),
          const Divider(height: 32),
          _buildMenuItem(
            Icons.logout_rounded,
            'logout'.tr,
            AppConstants.errorColor,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'ImkonJob v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Yaratuvchilar: Rahmatillo Ganiyev & Islomhon',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ==================== SHOW FULL PROFILE PHOTO ====================
  // ==================== SHOW FULL PROFILE PHOTO ====================
  void _showFullProfilePhoto(BuildContext context, String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== PROFILE PHOTO OPTIONS ==========
  void _showProfilePhotoOptions(
    BuildContext context,
    ProfileController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.all(16),
              child: Text(
                'change_photo'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: Text('take_photo'.tr),
              onTap: () async {
                Get.back();
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  await controller.uploadProfilePhoto(File(image.path));
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: Text('choose_from_gallery'.tr),
              onTap: () async {
                Get.back();
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  await controller.uploadProfilePhoto(File(image.path));
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: Text(
                'delete_photo'.tr,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Get.back();
                Get.dialog(
                  AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text('delete_photo'.tr),
                    content: Text('confirm_delete_photo'.tr),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('cancel'.tr),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await controller.deleteProfilePhoto();
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(
                          'delete'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ========== EDIT PROFILE DIALOG ==========

  // ========== MY POSTS DIALOG ==========
  void _showMyPostsDialog(
    BuildContext context,
    ProfileController profileController,
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
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'my_posts'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            Expanded(
              child: Obx(() {
                if (profileController.userPosts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_off_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_posts'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'no_posts_desc'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: profileController.userPosts.length,
                  itemBuilder: (context, index) {
                    final post = profileController.userPosts[index];
                    return _buildPostCard(context, post, profileController);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    dynamic post,
    ProfileController profileController,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      post.getCategoryEmoji(post.categoryIdNum),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.company,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppConstants.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            const Text('Tahrirlash'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Muvaffaqiyatli bajarildi',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'O\'chirish',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditPostDialog(context, post, profileController);
                      } else if (value == 'complete') {
                        _showCompletePostDialog(
                          context,
                          post,
                          profileController,
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmDialog(
                          context,
                          post,
                          profileController,
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ STATUS BADGE (BU YERDA QO'SHILDI!)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(post.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(post.status)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(post.status),
                      size: 16,
                      color: _getStatusColor(post.status),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(post.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(post.status),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (post.description.isNotEmpty)
                Text(
                  post.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.getSalaryRange(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  // ========== EDIT POST DIALOG ==========
  void _showEditPostDialog(
    BuildContext context,
    dynamic post,
    ProfileController profileController,
  ) {
    final titleController = TextEditingController(text: post.title);
    final descController = TextEditingController(text: post.description);
    final locationController = TextEditingController(text: post.location);
    final salaryMinController = TextEditingController(
      text: post.salaryMin.toString(),
    );
    final salaryMaxController = TextEditingController(
      text: post.salaryMax.toString(),
    );
    final requirementsMainController = TextEditingController(
      text: post.requirementsMain ?? '',
    );
    final requirementsBasicController = TextEditingController(
      text: post.requirementsBasic ?? '',
    );
    final skillsController = TextEditingController(text: post.skills ?? '');
    final experienceController = TextEditingController(
      text: post.experience ?? '',
    );
    final phoneController = TextEditingController(text: post.phoneNumber ?? '');

    final selectedSalaryType = (post.salaryType ?? 'monthly').obs;
    final selectedPostType = (post.postType ?? 'employee_needed').obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppConstants.primaryGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'E\'lonni tahrirlash',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // CONTENT
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Type
                      const Text(
                        'E\'lon turi *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          value: selectedPostType.value,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.work_outline),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'employee_needed',
                              child: Text('Hodim kerak'),
                            ),
                            DropdownMenuItem(
                              value: 'job_needed',
                              child: Text('Ish kerak'),
                            ),
                            DropdownMenuItem(
                              value: 'one_time_job',
                              child: Text('Bir martalik ish'),
                            ),
                          ],
                          onChanged: (value) => selectedPostType.value = value!,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      _buildTextField(
                        controller: titleController,
                        label: 'Sarlavha *',
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 16),

                      // Location
                      _buildTextField(
                        controller: locationController,
                        label: 'Joylashuv *',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _buildTextField(
                        controller: descController,
                        label: 'Tasnif *',
                        icon: Icons.description,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Salary Type
                      const Text(
                        'Maosh turi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          value: selectedSalaryType.value,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'daily',
                              child: Text('Kunlik'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('Oylik'),
                            ),
                            DropdownMenuItem(
                              value: 'freelance',
                              child: Text('Freelance'),
                            ),
                          ],
                          onChanged: (value) =>
                              selectedSalaryType.value = value!,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Salary Range
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: salaryMinController,
                              label: 'Min maosh *',
                              icon: Icons.money,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: salaryMaxController,
                              label: 'Max maosh *',
                              icon: Icons.money,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Requirements Main
                      _buildTextField(
                        controller: requirementsMainController,
                        label: 'Asosiy talablar',
                        icon: Icons.checklist,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Requirements Basic
                      _buildTextField(
                        controller: requirementsBasicController,
                        label: 'Qo\'shimcha talablar',
                        icon: Icons.check_circle_outline,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Skills
                      _buildTextField(
                        controller: skillsController,
                        label: 'Ko\'nikmalar (vergul bilan ajrating)',
                        icon: Icons.star_outline,
                        hint: 'Flutter, Dart, API',
                      ),
                      const SizedBox(height: 16),

                      // Experience
                      _buildTextField(
                        controller: experienceController,
                        label: 'Tajriba',
                        icon: Icons.work_history,
                        hint: '2 yil',
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildTextField(
                        controller: phoneController,
                        label: 'Telefon raqam',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        hint: '+998901234567',
                      ),
                    ],
                  ),
                ),
              ),

              // FOOTER
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Bekor qilish'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty ||
                              descController.text.trim().isEmpty ||
                              locationController.text.trim().isEmpty) {
                            Get.snackbar(
                              'Xatolik',
                              'Majburiy maydonlarni to\'ldiring!',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          final success = await profileController.updatePost(
                            postId: post.id,
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            location: locationController.text.trim(),
                            salaryMin:
                                int.tryParse(salaryMinController.text) ?? 0,
                            salaryMax:
                                int.tryParse(salaryMaxController.text) ?? 0,
                            salaryType: selectedSalaryType.value,
                            postType: selectedPostType.value,
                            requirementsMain: requirementsMainController.text
                                .trim(),
                            requirementsBasic: requirementsBasicController.text
                                .trim(),
                            skills: skillsController.text.trim(),
                            experience: experienceController.text.trim(),
                            phoneNumber: phoneController.text.trim(),
                          );

                          if (success) Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Saqlash',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== DELETE CONFIRM DIALOG ==========
  void _showDeleteConfirmDialog(
    BuildContext context,
    dynamic post,
    ProfileController profileController,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text('confirm'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'confirm_delete_post'.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              // Close dialog first
              Get.back();

              // Add a small delay to ensure dialog animation completes
              await Future.delayed(const Duration(milliseconds: 300));

              final success = await profileController.deletePost(post.id);
              if (success) {
                // Close the previous screen
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletePostDialog(
    BuildContext context,
    dynamic post,
    ProfileController profileController,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('E\'lonni yakunlash'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ushbu e\'lonni muvaffaqiyatli bajarilgan deb belgilamoqchimisiz?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '✅ E\'lon tarixga o\'tadi\n✅ Profilingizda saqlanadi\n✅ Boshqalar ko\'ra olmaydi',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
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
            onPressed: () async {
              // ✅ 1. Dialog yopish
              Get.back();

              // ✅ 2. Operatsiya bajarish
              final success = await profileController.markPostAsCompleted(
                post.id,
                null,
              );

              // ✅ 3. Agar muvaffaqiyatli bo'lsa, asosiy dialogni ham yopish
              if (success) {
                await Future.delayed(
                  const Duration(milliseconds: 500),
                ); // ← Snackbar uchun kutish
                Get.back(); // My posts dialog yopiladi
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Ha, yakunlash',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SAVED POSTS DIALOG ==========
  void _showSavedPostsDialog(
    BuildContext context,
    ProfileController profileController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder(
        future: profileController.getSavedPosts(),
        builder: (context, snapshot) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bookmark,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'saved_posts'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasData && snapshot.data!.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final post = snapshot.data![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 40,
                                ),
                                title: Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(post.company),
                                trailing: IconButton(
                                  // ✅ BU YERDA O'ZGARTIRDIK
                                  icon: const Icon(
                                    Icons.restore,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Qayta faollashtirish',
                                  onPressed: () async {
                                    final success = await profileController
                                        .restorePost(post.id);
                                    if (success) {
                                      Get.back();
                                      _showCompletedPostsDialog(
                                        context,
                                        profileController,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_border,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'no_saved_posts'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'no_saved_posts_desc'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCompletedPostsDialog(
    BuildContext context,
    ProfileController profileController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder(
        future: profileController.getCompletedPosts(),
        builder: (context, snapshot) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Muvaffaqiyatli bajarilgan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200]),

                // Content
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasData && snapshot.data!.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final post = snapshot.data![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 40,
                                ),
                                title: Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(post.company),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Hozircha tarix yo\'q',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'confirm_logout'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rostdan ham tizimdan chiqmoqchimisiz?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Qayta kirish uchun login va parol kerak bo\'ladi',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  'cancel'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  try {
                    final authController = Get.find<AuthController>();
                    authController.logout();
                    Get.snackbar(
                      'success'.tr,
                      'logout_success'.tr,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      duration: const Duration(seconds: 2),
                    );
                  } catch (e) {
                    Get.snackbar(
                      'error'.tr,
                      'logout_failed'.tr,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      icon: const Icon(Icons.error, color: Colors.white),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'yes_logout'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

  // ========== SETTINGS DIALOG ==========
  void _showSettingsDialog(
    BuildContext context,
    LanguageController languageController,
  ) {
    final RxBool notificationsEnabled = true.obs;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_rounded,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'settings'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSettingItem(
                    Icons.language,
                    'language'.tr,
                    languageController.getCurrentLanguageName(),
                    onTap: () {
                      Get.back();
                      _showLanguageDialog(context, languageController);
                    },
                  ),
                  Obx(
                    () => _buildSwitchSettingItem(
                      Icons.notifications_outlined,
                      'notifications'.tr,
                      notificationsEnabled.value,
                      (value) {
                        notificationsEnabled.value = value;
                        Get.snackbar(
                          'notifications'.tr,
                          value
                              ? 'notifications_enabled'.tr
                              : 'notifications_disabled'.tr,
                          backgroundColor: value ? Colors.green : Colors.orange,
                          colorText: Colors.white,
                        );
                      },
                    ),
                  ),
                  _buildSettingItem(
                    Icons.privacy_tip_outlined,
                    'privacy'.tr,
                    '',
                    onTap: () {
                      Get.back();
                      _showPrivacyDialog(context);
                    },
                  ),
                  _buildSettingItem(
                    Icons.security_outlined,
                    'security'.tr,
                    '',
                    onTap: () {
                      Get.back();
                      _showSecurityDialog(context);
                    },
                  ),
                  _buildSettingItem(
                    Icons.info_outline,
                    'about_app'.tr,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppConstants.primaryColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w500,
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

  Widget _buildSwitchSettingItem(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  // ========== LANGUAGE DIALOG ==========
  void _showLanguageDialog(
    BuildContext context,
    LanguageController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.language, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Text('select_language'.tr),
          ],
        ),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: controller.languages.map((lang) {
              final isSelected =
                  controller.selectedLanguage.value == lang['code'];
              return InkWell(
                onTap: () {
                  controller.changeLanguage(lang['code'] as String);
                  Get.back();
                  Get.snackbar(
                    'success'.tr,
                    'language_changed'.tr,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang['flag'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lang['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppConstants.primaryColor
                                : AppConstants.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppConstants.primaryColor,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.privacy_tip, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Text('privacy'.tr),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'privacy_info'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPrivacyItem('🔒', 'data_encrypted'.tr),
              _buildPrivacyItem('👤', 'personal_data_safe'.tr),
              _buildPrivacyItem('📧', 'no_spam'.tr),
              _buildPrivacyItem('🔐', 'secure_auth'.tr),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.green),
            const SizedBox(width: 12),
            Text('security'.tr),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSecurityOption(
                Icons.lock_outline,
                'change_password'.tr,
                'set_new_password'.tr,
                () {
                  Get.back();
                  Get.snackbar(
                    'coming_soon'.tr,
                    'feature_coming_soon'.tr,
                    backgroundColor: AppConstants.primaryColor,
                    colorText: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSecurityOption(
                Icons.verified_user,
                'two_factor_auth'.tr,
                'extra_security'.tr,
                () {
                  Get.back();
                  Get.snackbar(
                    'coming_soon'.tr,
                    'feature_coming_soon'.tr,
                    backgroundColor: AppConstants.primaryColor,
                    colorText: Colors.white,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
        ],
      ),
    );
  }

  Widget _buildSecurityOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Text('about_app'.tr),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  size: 40,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'JobHub',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'creators'.tr + ':',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Rahmatillo Ganiyev',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text('• Islomhon', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    Text(
                      'release_date'.tr + ':',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '25 Oktabr 2025',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'app_description'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
        ],
      ),
    );
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'approved':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    case 'rejected':
      return Colors.red;
    case 'successfully_completed':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

IconData _getStatusIcon(String status) {
  switch (status) {
    case 'approved':
      return Icons.check_circle;
    case 'pending':
      return Icons.hourglass_empty;
    case 'rejected':
      return Icons.cancel;
    case 'successfully_completed':
      return Icons.verified;
    default:
      return Icons.help;
  }
}

String _getStatusText(String status) {
  switch (status) {
    case 'approved':
      return 'Tasdiqlangan';
    case 'pending':
      return 'Kutilmoqda';
    case 'rejected':
      return 'Rad etilgan';
    case 'successfully_completed':
      return 'Bajarilgan';
    default:
      return 'Noma\'lum';
  }
}
