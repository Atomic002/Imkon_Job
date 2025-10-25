import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
