import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ==================== CONTROLLER ====================
class CreatePostController extends GetxController {
  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  // Observables
  final currentStep = 0.obs;
  final isLoading = false.obs;
  final isLoadingCategories = false.obs;
  final userType = Rxn<String>();
  final selectedImages = <File>[].obs;
  final categories = <Map<String, dynamic>>[].obs;
  final subCategories = <Map<String, dynamic>>[].obs;

  // Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final salaryMinController = TextEditingController();
  final salaryMaxController = TextEditingController();
  final requirementsMainController = TextEditingController();
  final requirementsBasicController = TextEditingController();
  final applicationMessageController = TextEditingController();

  // Form data
  final formData = {
    'userType': '',
    'title': '',
    'description': '',
    'country': 'Uzbekiston',
    'region': '',
    'district': '',
    'categoryId': null,
    'subCategoryId': null,
    'salaryMin': 0,
    'salaryMax': 0,
    'requirementsMain': '',
    'requirementsBasic': '',
    'applicationMessage': '',
  }.obs;

  // O'zbekistonning barcha viloyatlari
  final Map<String, List<String>> regions = {
    'Uzbekiston': [
      'Toshkent shahri',
      'Toshkent viloyati',
      'Andijon',
      'Buxoro',
      'Farg\'ona',
      'Jizzax',
      'Xorazm',
      'Namangan',
      'Navoiy',
      'Qashqadaryo',
      'Qoraqalpog\'iston Respublikasi',
      'Samarqand',
      'Sirdaryo',
      'Surxondaryo',
    ],
  };

  // Har bir viloyatning tumanlari
  final Map<String, List<String>> districts = {
    'Toshkent shahri': [
      'Bektemir',
      'Chilonzor',
      'Mirobod',
      'Mirzo Ulug\'bek',
      'Olmazor',
      'Sergeli',
      'Shayhontohur',
      'Uchtepa',
      'Yashnobod',
      'Yakkasaroy',
      'Yunusobod',
    ],
    'Toshkent viloyati': [
      'Angren',
      'Bekobod',
      'Bo\'ka',
      'Bo\'stonliq',
      'Chinoz',
      'Ohangaron',
      'Oqqo\'rg\'on',
      'Parkent',
      'Piskent',
      'Qibray',
      'Quyi Chirchiq',
      'O\'rta Chirchiq',
      'Yuqori Chirchiq',
      'Zangiota',
    ],
  };

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    salaryMinController.dispose();
    salaryMaxController.dispose();
    requirementsMainController.dispose();
    requirementsBasicController.dispose();
    applicationMessageController.dispose();
    super.onClose();
  }

  // ==================== METHODS ====================
  Future<void> loadCategories() async {
    isLoadingCategories.value = true;
    try {
      final response = await supabase
          .from('categories')
          .select('id, name, icon_url')
          .order('name');

      categories.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Kategoriyalarni yuklashda xato: $e');
      Get.snackbar(
        'Xato',
        'Kategoriyalarni yuklab bo\'lmadi',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> loadSubCategories(dynamic categoryId) async {
    try {
      print('Sub-kategoriya yuklanyapti: $categoryId');

      final response = await supabase
          .from('sub_categories')
          .select('id, name')
          .eq('category_id', categoryId)
          .order('name');

      print('Sub-kategoriya javob: $response');

      subCategories.value = List<Map<String, dynamic>>.from(response);
      formData['subCategoryId'] = null;
      print('Sub-kategoriyalar o\'zlashtirildi: ${subCategories.length} ta');
    } catch (e) {
      print('Sub-kategoriyalarni yuklashda xato: $e');
      Get.snackbar(
        'Xato',
        'Sub-kategoriyalarni yuklab bo\'lmadi',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
    }
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= 3) {
      Get.snackbar(
        'Diqqat',
        'Maksimal 3 ta rasm qo\'shish mumkin',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
      );
      return;
    }

    final pickedFiles = await _imagePicker.pickMultiImage();

    for (var file in pickedFiles) {
      if (selectedImages.length < 3) {
        selectedImages.add(File(file.path));
      }
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  void setUserType(String type) {
    userType.value = type;
    formData['userType'] = type;
  }

  void nextStep() {
    currentStep.value++;
  }

  void previousStep() {
    currentStep.value--;
  }

  bool validateStep1() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Diqqat',
        'Iltimos, sarlavha yoki nomni kiriting',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
      );
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Diqqat',
        'Iltimos, tasnifni kiriting',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
      );
      return false;
    }
    if (formData['categoryId'] == null) {
      Get.snackbar(
        'Diqqat',
        'Iltimos, kategoriyani tanlang',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
      );
      return false;
    }
    return true;
  }

  bool validateStep2() {
    if ((formData['region'] as String?)?.isEmpty ?? true) {
      Get.snackbar(
        'Diqqat',
        'Iltimos, viloyatni tanlang',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
      );
      return false;
    }
    return true;
  }

  Future<void> submitPost() async {
    // Show loading dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'E\'lon yuklanmoqda...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          'Xato',
          'Iltimos, tizimga kiring',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red.shade900,
          icon: const Icon(Icons.error_outline, color: Colors.red),
        );
        return;
      }

      // E'lonni yaratish
      final postResponse = await supabase.from('posts').insert({
        'user_id': userId,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category_id': formData['categoryId'],
        'sub_category_id': formData['subCategoryId'],
        'location': '${formData['region']}, ${formData['district']}'.trim(),
        'salary_min': formData['salaryMin'] ?? 0,
        'salary_max': formData['salaryMax'] ?? 0,
        'requirements_main': requirementsMainController.text.trim().isEmpty
            ? null
            : requirementsMainController.text.trim(),
        'requirements_basic': requirementsBasicController.text.trim().isEmpty
            ? null
            : requirementsBasicController.text.trim(),
        'status': 'pending',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (postResponse.isNotEmpty) {
        final postId = postResponse[0]['id'];

        // Rasmlarni yuklash
        if (selectedImages.isNotEmpty) {
          for (var i = 0; i < selectedImages.length; i++) {
            final image = selectedImages[i];
            final fileName =
                'post_${postId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

            await supabase.storage
                .from('post-images')
                .upload(
                  fileName,
                  image,
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: false,
                  ),
                );

            final imageUrl = supabase.storage
                .from('post-images')
                .getPublicUrl(fileName);

            await supabase.from('post_images').insert({
              'post_id': postId,
              'image_url': imageUrl,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }

        Get.back(); // Close loading dialog

        // Success dialog
        await Get.dialog(
          WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade50, Colors.white],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Muvaffaqiyatli!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'E\'loningiz muvaffaqiyatli yuborildi',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Keyingi qadamlar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDialogStep(
                            '1',
                            'Moderatorlar e\'loningizni ko\'rib chiqadi',
                          ),
                          const SizedBox(height: 8),
                          _buildDialogStep(
                            '2',
                            'Tasdiqlangandan keyin ommaga ko\'rinadi',
                          ),
                          const SizedBox(height: 8),
                          _buildDialogStep(
                            '3',
                            'Jarayon 24 soatgacha davom etishi mumkin',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back(); // Close dialog
                          Get.offAllNamed('/home'); // Go to home
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Bosh Sahifaga',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      print('Xato: $e');
      Get.back(); // Close loading dialog

      Get.snackbar(
        'Xato',
        'E\'lon yaratishda xatolik: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error_outline, color: Colors.red),
        duration: const Duration(seconds: 4),
      );
    }
  }

  Widget _buildDialogStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  String getCategoryEmoji(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('dasturlash') ||
        name.contains('it') ||
        name.contains('coding') ||
        name.contains('developer')) {
      return '💻';
    } else if (name.contains('flutter') || name.contains('mobil')) {
      return '📱';
    } else if (name.contains('design') || name.contains('dizayn')) {
      return '🎨';
    } else if (name.contains('marketing') || name.contains('bozor')) {
      return '📊';
    } else if (name.contains('video') || name.contains('montaj')) {
      return '🎬';
    } else if (name.contains('tutor') ||
        name.contains('o\'qitish') ||
        name.contains('ta\'lim')) {
      return '👨‍🏫';
    } else if (name.contains('musiqa') || name.contains('music')) {
      return '🎵';
    } else if (name.contains('sport') || name.contains('fitness')) {
      return '⚽';
    } else if (name.contains('sog\'liq') ||
        name.contains('health') ||
        name.contains('tibbiyot')) {
      return '🏥';
    } else if (name.contains('qurilish') || name.contains('construction')) {
      return '🏗️';
    } else if (name.contains('transport') || name.contains('haydovchi')) {
      return '🚗';
    } else if (name.contains('savdo') || name.contains('sotuvchi')) {
      return '🛒';
    } else if (name.contains('moliya') || name.contains('finance')) {
      return '💰';
    } else if (name.contains('ish') || name.contains('vakansiya')) {
      return '💼';
    }

    return '📁';
  }
}

// ==================== VIEW ====================
class CreatePostScreen extends GetView<CreatePostController> {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(CreatePostController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'E\'lon Yaratish',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: Obx(
          () => controller.currentStep.value > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: controller.previousStep,
                )
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
        ),
      ),
      body: Obx(() {
        switch (controller.currentStep.value) {
          case 0:
            return _Step0UserType(controller: controller);
          case 1:
            return _Step1BasicInfo(controller: controller);
          case 2:
            return _Step2Location(controller: controller);
          case 3:
            return _Step3Salary(controller: controller);
          case 4:
            return _Step4Images(controller: controller);
          default:
            return _Step5Application(controller: controller);
        }
      }),
    );
  }
}

// ==================== STEP 0: USER TYPE ====================
class _Step0UserType extends StatelessWidget {
  final CreatePostController controller;

  const _Step0UserType({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_pin_circle,
                  size: 64,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Siz kimsiniz?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'E\'lon turini tanlang',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Obx(
                () => _UserTypeCard(
                  icon: Icons.work_outline_rounded,
                  title: 'Ish Qidiruvchi',
                  subtitle:
                      'Men ish izlayapman va o\'zimni taqdim qilmoqchiman',
                  value: 'job_seeker',
                  isSelected: controller.userType.value == 'job_seeker',
                  color: Colors.green,
                  onTap: () => controller.setUserType('job_seeker'),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => _UserTypeCard(
                  icon: Icons.business_center_rounded,
                  title: 'Ish Beruvchi',
                  subtitle:
                      'Men xodim qabul qilyapman va vakansiya e\'lon qilmoqchiman',
                  value: 'employer',
                  isSelected: controller.userType.value == 'employer',
                  color: Colors.blue,
                  onTap: () => controller.setUserType('employer'),
                ),
              ),
              const SizedBox(height: 40),
              Obx(
                () => _PrimaryButton(
                  text: 'Davom Etish',
                  onPressed: controller.userType.value == null
                      ? null
                      : controller.nextStep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? color : Colors.grey[600],
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== STEP 1: BASIC INFO ====================
class _Step1BasicInfo extends StatelessWidget {
  final CreatePostController controller;

  const _Step1BasicInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 1, total: 5),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.info_outline,
            title: 'Asosiy Ma\'lumot',
            subtitle: 'E\'lon haqida umumiy ma\'lumotlarni kiriting',
          ),
          const SizedBox(height: 24),
          Obx(
            () => _ModernTextField(
              controller: controller.titleController,
              label: controller.userType.value == 'job_seeker'
                  ? 'Sizning F.I.O'
                  : 'E\'lon Sarlavhasi',
              hint: controller.userType.value == 'job_seeker'
                  ? 'Aziz Aliyev'
                  : 'Masalan: Senior Flutter Developer kerak',
              icon: Icons.title,
              onChanged: (value) => controller.formData['title'] = value,
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => _ModernTextField(
              controller: controller.descriptionController,
              label: 'Batafsil Tasnif',
              hint: controller.userType.value == 'job_seeker'
                  ? 'O\'zingiz, tajribangiz va ko\'nikmalaringiz haqida yozing...'
                  : 'Ish vazifasi, talablar va imkoniyatlar haqida yozing...',
              icon: Icons.description,
              maxLines: 5,
              onChanged: (value) => controller.formData['description'] = value,
            ),
          ),
          const SizedBox(height: 24),
          _Label('Kategoriya', Icons.category),
          const SizedBox(height: 12),
          Obx(
            () => controller.isLoadingCategories.value
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _CategorySelector(controller: controller),
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.formData['categoryId'] != null &&
                controller.subCategories.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Sub-kategoriya', Icons.subdirectory_arrow_right),
                  const SizedBox(height: 12),
                  _SubCategorySelector(controller: controller),
                  const SizedBox(height: 20),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'Keyingi',
            onPressed: () {
              if (controller.validateStep1()) {
                controller.nextStep();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 2: LOCATION ====================
class _Step2Location extends StatelessWidget {
  final CreatePostController controller;

  const _Step2Location({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 2, total: 5),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.location_on_outlined,
            title: 'Manzil',
            subtitle: 'Ish joyingizni ko\'rsating',
          ),
          const SizedBox(height: 24),
          // Viloyat dropdown
          Obx(() {
            final regionList = controller.regions['Uzbekiston'] ?? [];
            final currentRegion = controller.formData['region'] as String?;

            return _ModernDropdown(
              label: 'Viloyat',
              value: (currentRegion?.isEmpty ?? true) ? null : currentRegion,
              hint: 'Viloyatni tanlang',
              icon: Icons.location_city,
              items: regionList,
              onChanged: (value) {
                controller.formData['region'] = value ?? '';
                controller.formData['district'] = '';
                controller.formData.refresh(); // Bu muhim!
              },
            );
          }),
          const SizedBox(height: 20),
          // Tuman dropdown
          Obx(() {
            final currentRegion = controller.formData['region'] as String?;
            final currentDistrict = controller.formData['district'] as String?;

            final districtList = (currentRegion?.isNotEmpty ?? false)
                ? controller.districts[currentRegion] ?? []
                : <String>[];

            if (districtList.isEmpty) return const SizedBox.shrink();

            return _ModernDropdown(
              label: 'Tuman',
              value: (currentDistrict?.isEmpty ?? true)
                  ? null
                  : currentDistrict,
              hint: 'Tumanni tanlang',
              icon: Icons.place,
              items: districtList,
              onChanged: (value) {
                controller.formData['district'] = value ?? '';
                controller.formData.refresh(); // Bu muhim!
              },
            );
          }),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'Keyingi',
            onPressed: () {
              if (controller.validateStep2()) {
                controller.nextStep();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 3: SALARY ====================
class _Step3Salary extends StatelessWidget {
  final CreatePostController controller;

  const _Step3Salary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 3, total: 5),
          const SizedBox(height: 32),
          Obx(
            () => _SectionHeader(
              icon: Icons.payments_outlined,
              title: controller.userType.value == 'employer'
                  ? 'Maosh va Talablar'
                  : 'Kutayotgan Maosh',
              subtitle: controller.userType.value == 'employer'
                  ? 'Maosh va talablarni belgilang'
                  : 'Kutayotgan maoshingizni kiriting',
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            if (controller.userType.value == 'employer') {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ModernTextField(
                          controller: controller.salaryMinController,
                          label: 'Minimum Maosh',
                          hint: '1000000',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          suffix: 'UZS',
                          onChanged: (value) {
                            controller.formData['salaryMin'] =
                                int.tryParse(value) ?? 0;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModernTextField(
                          controller: controller.salaryMaxController,
                          label: 'Maksimum Maosh',
                          hint: '3000000',
                          icon: Icons.trending_up,
                          keyboardType: TextInputType.number,
                          suffix: 'UZS',
                          onChanged: (value) {
                            controller.formData['salaryMax'] =
                                int.tryParse(value) ?? 0;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: controller.requirementsMainController,
                    label: 'Asosiy Talablar',
                    hint: '3+ yil tajriba, Flutter, Dart, State Management...',
                    icon: Icons.checklist,
                    maxLines: 3,
                    onChanged: (value) =>
                        controller.formData['requirementsMain'] = value,
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: controller.requirementsBasicController,
                    label: 'Qo\'shimcha Talablar',
                    hint: 'Ingliz tili, Git, REST API, Firebase...',
                    icon: Icons.add_circle_outline,
                    maxLines: 3,
                    onChanged: (value) =>
                        controller.formData['requirementsBasic'] = value,
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _ModernTextField(
                    controller: controller.salaryMinController,
                    label: 'Kutayotgan Oylik (UZS)',
                    hint: '2000000',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    suffix: 'UZS',
                    onChanged: (value) {
                      controller.formData['salaryMin'] =
                          int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 20),
                  _ModernTextField(
                    controller: controller.requirementsMainController,
                    label: 'Tajribangiz va Ko\'nikmalaringiz',
                    hint:
                        '5 yil Flutter development, Clean Architecture, BLoC...',
                    icon: Icons.psychology_outlined,
                    maxLines: 4,
                    onChanged: (value) =>
                        controller.formData['requirementsMain'] = value,
                  ),
                ],
              );
            }
          }),
          const SizedBox(height: 40),
          _PrimaryButton(text: 'Keyingi', onPressed: controller.nextStep),
        ],
      ),
    );
  }
}

// ==================== STEP 4: IMAGES ====================
class _Step4Images extends StatelessWidget {
  final CreatePostController controller;

  const _Step4Images({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 4, total: 5),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.add_photo_alternate_outlined,
            title: 'Rasmlar',
            subtitle: 'E\'loningizga rasmlar qo\'shing (ixtiyoriy)',
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: controller.pickImages,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rasm qo\'shish uchun bosing',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maksimal 3 ta rasm',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            if (controller.selectedImages.isEmpty)
              return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tanlangan rasmlar: ${controller.selectedImages.length}/3',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: controller.selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            image: DecorationImage(
                              image: FileImage(
                                controller.selectedImages[index],
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => controller.removeImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          }),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'Keyingi',
            icon: Icons.arrow_forward,
            onPressed: controller.nextStep,
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 5: APPLICATION MESSAGE ====================
class _Step5Application extends StatelessWidget {
  final CreatePostController controller;

  const _Step5Application({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 5, total: 5),
          const SizedBox(height: 32),
          Obx(
            () => _SectionHeader(
              icon: Icons.message_outlined,
              title: 'Qo\'shimcha Ma\'lumot',
              subtitle: controller.userType.value == 'job_seeker'
                  ? 'O\'zingiz haqida qo\'shimcha ma\'lumot bering'
                  : 'Nomzodlarga ish haqida qo\'shimcha ma\'lumot',
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => _ModernTextField(
              controller: controller.applicationMessageController,
              label: 'Xabar',
              hint: controller.userType.value == 'job_seeker'
                  ? 'Mening tajribam, ko\'nikmalarim va nega men ushbu lavozim uchun to\'g\'ri nomzod ekanligim haqida...'
                  : 'Kompaniya, jamoa, ish sharoitlari va imkoniyatlar haqida qo\'shimcha ma\'lumotlar...',
              icon: Icons.edit_note,
              maxLines: 8,
              onChanged: (value) =>
                  controller.formData['applicationMessage'] = value,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bu qism ixtiyoriy, lekin to\'ldirish tavsiya etiladi',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'E\'lon Yaratish',
            icon: Icons.send_rounded,
            onPressed: controller.submitPost,
          ),
        ],
      ),
    );
  }
}

// ==================== REUSABLE WIDGETS ====================
class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= total; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: i <= current
                    ? LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      )
                    : null,
                color: i <= current ? null : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Label(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final String? suffix;
  final Function(String) onChanged;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final List<String> items;
  final Function(String?) onChanged;

  const _ModernDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: Container(),
                  hint: Text(
                    hint,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  items: items
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final CreatePostController controller;

  const _CategorySelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final cat = controller.categories[index];
          final isSelected = controller.formData['categoryId'] == cat['id'];
          final emoji = controller.getCategoryEmoji(
            cat['name'] ?? 'Kategoriya',
          );

          return GestureDetector(
            onTap: () {
              controller.formData['categoryId'] = cat['id'];
              controller.formData['subCategoryId'] = null;
              controller.subCategories.clear();
              controller.loadSubCategories(cat['id']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: Border.all(
                  color: isSelected ? Colors.blue.shade700 : Colors.grey[300]!,
                  width: isSelected ? 2.5 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: TextStyle(fontSize: isSelected ? 44 : 40)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      cat['name'] ?? 'Kategoriya',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubCategorySelector extends StatelessWidget {
  final CreatePostController controller;

  const _SubCategorySelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.subCategories.map((subCat) {
              final isSelected =
                  controller.formData['subCategoryId'] == subCat['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    controller.formData['subCategoryId'] = subCat['id'];
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      subCat['name'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          disabledBackgroundColor: Colors.grey[300],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: onPressed == null ? 0 : 4,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
