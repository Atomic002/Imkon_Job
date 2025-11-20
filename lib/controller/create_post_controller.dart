import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_storage/get_storage.dart';
import 'package:version1/controller/auth_controller.dart';

// ==================== PHONE FORMATTER ====================
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length > 9) {
      digitsOnly = digitsOnly.substring(0, 9);
    }
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ==================== NUMBER FORMATTER ====================
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length > 18) digitsOnly = digitsOnly.substring(0, 18);
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && (digitsOnly.length - i) % 3 == 0) formatted += ' ';
      formatted += digitsOnly[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ==================== CONTROLLER ====================
class CreatePostController extends GetxController {
  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  final storage = GetStorage();

  // Observables
  final currentStep = 0.obs;
  final isLoading = false.obs;
  final isLoadingCategories = false.obs;
  final postType = Rxn<String>();
  final selectedImages = <File>[].obs;
  final categories = <Map<String, dynamic>>[].obs;
  final subCategories = <Map<String, dynamic>>[].obs;
  final selectedSubCategories = <int>[].obs;
  final savedPhoneNumbers = <String>[].obs;

  // Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final salaryMinController = TextEditingController();
  final salaryMaxController = TextEditingController();
  final requirementsMainController = TextEditingController();
  final requirementsBasicController = TextEditingController();
  final durationDaysController = TextEditingController();
  final skillsController = TextEditingController();
  final experienceController = TextEditingController();
  final phoneNumberController = TextEditingController();

  // Form data
  final formData = {
    'postType': '',
    'title': '',
    'description': '',
    'region': '',
    'district': '',
    'village': '',
    'categoryId': null,
    'subCategoryIds': <int>[],
    'salaryType': '',
    'salaryMin': 0,
    'salaryMax': 0,
    'requirementsMain': '',
    'requirementsBasic': '',
    'durationDays': null,
    'skills': '',
    'experience': '',
    'phoneNumber': null,
  }.obs;

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

  final Map<String, Map<String, List<String>>> districts = {
    'Toshkent shahri': {
      'Bektemir': ['Sergeli', 'Qoyliq', 'Salar', 'Yashnobod'],
      'Chilonzor': ['Chilonzor', 'Navbahor', 'Qatortol', 'Minor'],
      'Mirobod': ['Mirobod', 'Yakkasaroy', 'Sebzor', 'Paxtakor'],
      'Mirzo Ulug\'bek': ['Ulug\'bek', 'Qorasu', 'Salar', 'Shayxontohur'],
      'Olmazor': ['Olmazor', 'Zarqaynar', 'Bodomzor', 'Temir yo\'l'],
      'Sergeli': ['Sergeli', 'Qibray', 'Halqabad', 'Yangiobod'],
      'Shayhontohur': ['Shayhontohur', 'Chorsu', 'Eski shahar', 'Ipak yo\'li'],
      'Uchtepa': ['Uchtepa', 'Sabirabad', 'Qorasaroy', 'Minor'],
      'Yashnobod': ['Yashnobod', 'Parkent yo\'li', 'Choshtepa', 'Qoraqamish'],
      'Yakkasaroy': ['Yakkasaroy', 'Uzbekiston', 'Amir Temur', 'Minor'],
      'Yunusobod': ['Yunusobod', 'TTZ', 'Chilonzor', 'Minor'],
    },
    'Toshkent viloyati': {
      'Angren': ['Angren shahri', 'Shakar', 'Akhangaron', 'Dustlik'],
      'Bekobod': ['Bekobod shahri', 'Keles', 'Dustlik', 'Chinor'],
    },
  };

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    _loadSavedPhoneNumbers();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    salaryMinController.dispose();
    salaryMaxController.dispose();
    requirementsMainController.dispose();
    requirementsBasicController.dispose();
    durationDaysController.dispose();
    skillsController.dispose();
    experienceController.dispose();
    phoneNumberController.dispose();
    super.onClose();
  }

  Future<void> _loadSavedPhoneNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numbers = prefs.getStringList('saved_phone_numbers') ?? [];
      savedPhoneNumbers.value = numbers;
      if (numbers.isNotEmpty) {
        final lastNumber = numbers.first;
        final digits = lastNumber.replaceAll('+998', '').replaceAll(' ', '');
        phoneNumberController.text = _formatPhoneDisplay(digits);
      }
    } catch (e) {
      print('Telefon raqamlarni yuklashda xato: $e');
    }
  }

  Future<void> _savePhoneNumber(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> numbers = savedPhoneNumbers.toList();
      numbers.remove(phoneNumber);
      numbers.insert(0, phoneNumber);
      if (numbers.length > 5) {
        numbers = numbers.sublist(0, 5);
      }
      await prefs.setStringList('saved_phone_numbers', numbers);
      savedPhoneNumbers.value = numbers;
    } catch (e) {
      print('Telefon raqamni saqlashda xato: $e');
    }
  }

  String _formatPhoneDisplay(String digits) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 5)
      return '${digits.substring(0, 2)} ${digits.substring(2)}';
    if (digits.length <= 7)
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
  }

  Future<void> loadCategories() async {
    isLoadingCategories.value = true;
    try {
      final response = await supabase
          .from('categories')
          .select('id, name')
          .order('name');
      categories.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_categories'.tr,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> loadSubCategories(dynamic categoryId) async {
    try {
      final response = await supabase
          .from('sub_categories')
          .select('id, name')
          .eq('category_id', categoryId)
          .order('name');
      subCategories.value = List<Map<String, dynamic>>.from(response);
      selectedSubCategories.clear();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_subcategories'.tr,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void toggleSubCategory(int subCatId) {
    if (selectedSubCategories.contains(subCatId)) {
      selectedSubCategories.remove(subCatId);
    } else {
      selectedSubCategories.add(subCatId);
    }
    formData['subCategoryIds'] = selectedSubCategories.toList();
    formData.refresh();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= 3) {
      Get.snackbar(
        'warning'.tr,
        'max_3_images'.tr,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
      );
      return;
    }
    final pickedFiles = await _imagePicker.pickMultiImage();
    for (var file in pickedFiles) {
      if (selectedImages.length < 3) selectedImages.add(File(file.path));
    }
  }

  void removeImage(int index) => selectedImages.removeAt(index);

  void setPostType(String type) {
    postType.value = type;
    formData['postType'] = type;
    Future.delayed(const Duration(milliseconds: 300), nextStep);
  }

  void nextStep() => currentStep.value++;
  void previousStep() => currentStep.value--;

  bool validateStep1() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'warning'.tr,
        'title_required'.tr,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
      );
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'warning'.tr,
        'description_required'.tr,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
      );
      return false;
    }
    if (formData['categoryId'] == null) {
      Get.snackbar(
        'warning'.tr,
        'category_required'.tr,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
      );
      return false;
    }
    if (subCategories.isNotEmpty && selectedSubCategories.isEmpty) {
      Get.snackbar(
        'warning'.tr,
        'select_at_least_one_subcategory'.tr,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
      );
      return false;
    }
    return true;
  }

  bool validateStep2() {
    if ((formData['region'] as String?)?.isEmpty ?? true) {
      Get.snackbar(
        'warning'.tr,
        'region_required'.tr,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
      );
      return false;
    }
    if ((formData['district'] as String?)?.isEmpty ?? true) {
      Get.snackbar(
        'warning'.tr,
        'district_required'.tr,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange.shade900,
      );
      return false;
    }
    return true;
  }

  bool validateStep3() {
    if (formData['postType'] == 'employee_needed') {
      if ((formData['salaryType'] as String?)?.isEmpty ?? true) {
        Get.snackbar(
          'warning'.tr,
          'salary_type_required'.tr,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange.shade900,
        );
        return false;
      }
      if (requirementsMainController.text.trim().isEmpty) {
        Get.snackbar(
          'warning'.tr,
          'requirements_required'.tr,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange.shade900,
        );
        return false;
      }
      if (formData['salaryType'] == 'freelance' &&
          durationDaysController.text.trim().isEmpty) {
        Get.snackbar(
          'warning'.tr,
          'duration_required'.tr,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange.shade900,
        );
        return false;
      }
    } else if (formData['postType'] == 'job_needed') {
      if (skillsController.text.trim().isEmpty) {
        Get.snackbar(
          'warning'.tr,
          'skills_required'.tr,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange.shade900,
        );
        return false;
      }
      if (experienceController.text.trim().isEmpty) {
        Get.snackbar(
          'warning'.tr,
          'experience_required'.tr,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange.shade900,
        );
        return false;
      }
    } else if (formData['postType'] == 'one_time_job') {
      if (durationDaysController.text.trim().isEmpty) {
        Get.snackbar(
          'warning'.tr,
          'duration_required'.tr,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange.shade900,
        );
        return false;
      }
    } else if (formData['postType'] == 'service_offering') {
      if (skillsController.text.trim().isEmpty) {
        Get.snackbar(
          'warning'.tr,
          'skills_required'.tr,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange.shade900,
        );
        return false;
      }
      if (experienceController.text.trim().isEmpty) {
        Get.snackbar(
          'warning'.tr,
          'experience_required'.tr,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange.shade900,
        );
        return false;
      }
    }
    return true;
  }

  /// ✅ YANGI: UserId olish - Supabase Auth bilan
  /// ✅ FAQAT UserId olish - HECH QANDAY TEKSHIRUVSIZ
  /// ✅ FAQAT STORAGE'DAN UserId olish
  String? _getUserId() {
    // Method 1: Storage (ENG MUHIM!)
    final storageUserId = storage.read('userId');
    if (storageUserId != null) return storageUserId.toString();

    // Method 2: AuthController
    try {
      final authController = Get.find<AuthController>();
      return authController.getCurrentUserId();
    } catch (e) {
      return null;
    }
  }

  Future<void> submitPost() async {
    final userId = _getUserId();

    if (userId == null || userId.isEmpty) {
      Get.snackbar('Xatolik', 'Tizimga kiring');
      Get.offAllNamed('/login');
      return;
    }

    // TELEFON RAQAM
    String? phoneNumber;
    final rawPhone = phoneNumberController.text.trim();
    if (rawPhone.isNotEmpty) {
      final digitsOnly = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length == 9) {
        phoneNumber = '+998$digitsOnly';
        await _savePhoneNumber(phoneNumber);
      }
    }

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
                Text(
                  'uploading_post'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      String fullLocation = formData['region'] as String;
      if ((formData['district'] as String?)?.isNotEmpty ?? false)
        fullLocation += ', ${formData['district']}';
      if ((formData['village'] as String?)?.isNotEmpty ?? false)
        fullLocation += ', ${formData['village']}';

      int salaryMin =
          int.tryParse(
            salaryMinController.text.replaceAll(RegExp(r'\s'), ''),
          ) ??
          0;
      int salaryMax =
          int.tryParse(
            salaryMaxController.text.replaceAll(RegExp(r'\s'), ''),
          ) ??
          0;

      // ✅ FAQAT 1 TA POST YARATISH
      final insertData = {
        'user_id': userId,
        'post_type': formData['postType'],
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category_id': formData['categoryId'],
        // ❌ 'sub_category_id' yo'q artiq!
        'location': fullLocation,
        'salary_type': formData['salaryType'],
        'salary_min': salaryMin,
        'salary_max': salaryMax,
        'requirements_main': requirementsMainController.text.trim().isEmpty
            ? null
            : requirementsMainController.text.trim(),
        'requirements_basic': requirementsBasicController.text.trim().isEmpty
            ? null
            : requirementsBasicController.text.trim(),
        'duration_days': durationDaysController.text.trim().isEmpty
            ? null
            : int.tryParse(durationDaysController.text),
        'skills': skillsController.text.trim().isEmpty
            ? null
            : skillsController.text.trim(),
        'experience': experienceController.text.trim().isEmpty
            ? null
            : experienceController.text.trim(),
        'phone_number': phoneNumber,
        'status': 'pending',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final postResponse = await supabase
          .from('posts')
          .insert(insertData)
          .select();

      if (postResponse.isNotEmpty) {
        final postId = postResponse[0]['id'];

        // ✅ SUB-KATEGORIYALARNI ALOHIDA JADVALGA QO'SHISH
        if (selectedSubCategories.isNotEmpty) {
          final subCategoryInserts = selectedSubCategories.map((subCatId) {
            return {
              'post_id': postId,
              'sub_category_id': subCatId,
              'created_at': DateTime.now().toIso8601String(),
            };
          }).toList();

          await supabase.from('post_subcategories').insert(subCategoryInserts);
        }

        // Rasmlar
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

        Get.back();
        await _showSuccessDialog();
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'error'.tr,
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _showSuccessDialog() async {
    await Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.all(24),
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
                Text(
                  'success'.tr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'post_submitted_success'.tr,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.offAllNamed('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'home'.tr,
                      style: const TextStyle(
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
}
