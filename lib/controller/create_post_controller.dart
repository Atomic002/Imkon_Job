import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== PHONE FORMATTER ====================
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length > 9) digitsOnly = digitsOnly.substring(0, 9);

    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 5 || i == 7) formatted += ' ';
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

  // Observable variables
  final currentStep = 0.obs;
  final isLoading = false.obs;
  final isLoadingCategories = false.obs;
  final postType = Rxn<String>();
  final selectedImages = <File>[].obs;
  final categories = <Map<String, dynamic>>[].obs;
  final subCategories = <Map<String, dynamic>>[].obs;

  // ✅✅✅ CRITICAL: Sub-category selection fields
  final selectedSubCategoryId = Rxn<int>();
  final selectedSubCategoryName = RxString(''); // ✅ RxString o'rniga

  final savedPhoneNumbers = <String>[].obs;

  // Text controllers
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
    'categoryName': '',
    'subCategoryId': null,
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

  // Regions and districts data
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
  };

  @override
  void onInit() {
    super.onInit();
    print('🚀 CreatePostController initialized');
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

  // ==================== PHONE NUMBER METHODS ====================
  Future<void> _loadSavedPhoneNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numbers = prefs.getStringList('saved_phone_numbers') ?? [];
      savedPhoneNumbers.value = numbers;
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
      if (numbers.length > 5) numbers = numbers.sublist(0, 5);
      await prefs.setStringList('saved_phone_numbers', numbers);
      savedPhoneNumbers.value = numbers;
    } catch (e) {
      print('Telefon raqamni saqlashda xato: $e');
    }
  }

  // ==================== CATEGORY METHODS ====================
  Future<void> loadCategories() async {
    isLoadingCategories.value = true;
    try {
      print('📥 Loading categories...');
      final response = await supabase
          .from('categories')
          .select('id, name')
          .order('name');

      categories.value = List<Map<String, dynamic>>.from(response);
      print('✅ Loaded ${categories.length} categories');
    } catch (e) {
      print('❌ Category load error: $e');
      _showError('Kategoriyalarni yuklashda xatolik: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> loadSubCategories(dynamic categoryId) async {
    try {
      print('📥 Loading subcategories for category: $categoryId');
      final response = await supabase
          .from('sub_categories')
          .select('id, name')
          .eq('category_id', categoryId)
          .order('name');

      subCategories.value = List<Map<String, dynamic>>.from(response);
      print('✅ Loaded ${subCategories.length} subcategories');

      // ✅ Reset selection when category changes
      selectedSubCategoryId.value = null;
      selectedSubCategoryName.value = '';
      formData['subCategoryId'] = null;
    } catch (e) {
      print('❌ Subcategory load error: $e');
      _showError('Sub-kategoriyalarni yuklashda xatolik');
    }
  }

  // ✅✅✅ CRITICAL: Sub-category selection method
  void selectSubCategory(int id, String name) {
    print('📌 Selecting subcategory: ID=$id, Name=$name');

    selectedSubCategoryId.value = id;
    selectedSubCategoryName.value = name;
    formData['subCategoryId'] = id;

    print('✅ Subcategory selected successfully');
    print('   - ID: ${selectedSubCategoryId.value}');
    print('   - Name: ${selectedSubCategoryName.value}');
  }

  // ==================== IMAGE METHODS ====================
  Future<void> pickImages() async {
    if (selectedImages.length >= 3) {
      _showWarning('Maksimal 3 ta rasm qo\'shishingiz mumkin');
      return;
    }
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      for (var file in pickedFiles) {
        if (selectedImages.length < 3) {
          selectedImages.add(File(file.path));
        }
      }
    } catch (e) {
      print('Rasm tanlashda xato: $e');
    }
  }

  void removeImage(int index) => selectedImages.removeAt(index);

  // ==================== NAVIGATION METHODS ====================
  void setPostType(String type) {
    postType.value = type;
    formData['postType'] = type;
    Future.delayed(const Duration(milliseconds: 300), nextStep);
  }

  void nextStep() => currentStep.value++;
  void previousStep() => currentStep.value--;

  // ==================== VALIDATION METHODS ====================
  bool validateStep1() {
    if (titleController.text.trim().isEmpty) {
      _showWarning('Sarlavha kiriting');
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      _showWarning('Ta\'rif kiriting');
      return false;
    }
    if (formData['categoryId'] == null) {
      _showWarning('Kategoriya tanlang');
      return false;
    }
    if (subCategories.isNotEmpty && selectedSubCategoryId.value == null) {
      _showWarning('Sub-kategoriya tanlang');
      return false;
    }
    return true;
  }

  bool validateStep2() {
    if ((formData['region'] as String?)?.isEmpty ?? true) {
      _showWarning('Viloyat tanlang');
      return false;
    }
    if ((formData['district'] as String?)?.isEmpty ?? true) {
      _showWarning('Tuman tanlang');
      return false;
    }
    return true;
  }

  bool validateStep3() {
    final postTypeValue = formData['postType'];

    if (postTypeValue == 'employee_needed') {
      if ((formData['salaryType'] as String?)?.isEmpty ?? true) {
        _showWarning('Ish haqi turini tanlang');
        return false;
      }
      if (requirementsMainController.text.trim().isEmpty) {
        _showWarning('Asosiy talablarni kiriting');
        return false;
      }
      if (formData['salaryType'] == 'freelance' &&
          durationDaysController.text.trim().isEmpty) {
        _showWarning('Ish muddatini kiriting');
        return false;
      }
    } else if (postTypeValue == 'job_needed') {
      if (skillsController.text.trim().isEmpty) {
        _showWarning('Ko\'nikmalaringizni kiriting');
        return false;
      }
      if (experienceController.text.trim().isEmpty) {
        _showWarning('Tajribangizni kiriting');
        return false;
      }
    } else if (postTypeValue == 'one_time_job') {
      if (durationDaysController.text.trim().isEmpty) {
        _showWarning('Ish muddatini kiriting');
        return false;
      }
    } else if (postTypeValue == 'service_offering') {
      if (skillsController.text.trim().isEmpty) {
        _showWarning('Ko\'nikmalaringizni kiriting');
        return false;
      }
      if (experienceController.text.trim().isEmpty) {
        _showWarning('Tajribangizni kiriting');
        return false;
      }
    }
    return true;
  }

  // ==================== SUBMIT METHOD ====================
  Future<void> submitPost() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      _showError('Iltimos, avval tizimga kiring!');
      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/login');
      return;
    }

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
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
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

      print('📤 Creating post:');
      print('   - Category ID: ${formData['categoryId']}');
      print('   - Subcategory ID: ${selectedSubCategoryId.value}');
      print('   - Subcategory Name: ${selectedSubCategoryName.value}');

      final postResponse = await supabase.from('posts').insert({
        'user_id': userId,
        'post_type': formData['postType'],
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category_id': formData['categoryId'],
        'sub_category_id': selectedSubCategoryId.value,
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
      }).select();

      if (postResponse.isNotEmpty) {
        final postId = postResponse[0]['id'];
        print('✅ Post created successfully: $postId');

        // Upload images if any
        if (selectedImages.isNotEmpty) {
          print('📷 Uploading ${selectedImages.length} images...');
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
          print('✅ Images uploaded successfully');
        }

        Get.back(); // Close loading dialog
        await _showSuccessDialog();
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      print('❌ Submit error: $e');
      _showError('Xatolik: $e');
    }
  }

  // ==================== UI FEEDBACK METHODS ====================
  void _showError(String message) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      'Xatolik',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  void _showWarning(String message) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      'Diqqat',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
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
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Muvaffaqiyatli!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'E\'loningiz muvaffaqiyatli yaratildi',
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Bosh sahifa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
