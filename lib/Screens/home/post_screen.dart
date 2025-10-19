import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  int currentStep = 0;
  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  String? userType;
  List<File> selectedImages = [];
  bool isLoading = false;

  // Categories va subcategories API dan
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subCategories = [];
  bool isLoadingCategories = false;

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
  };

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
    'Andijon': [
      'Andijon shahri',
      'Xo\'jaobod',
      'Asaka',
      'Baliqchi',
      'Bo\'z',
      'Buloqboshi',
      'Izboskan',
      'Jalaquduq',
      'Marhamat',
      'Oltinko\'l',
      'Paxtaobod',
      'Qo\'rg\'ontepa',
      'Shahrixon',
      'Ulug\'nor',
    ],
    'Buxoro': [
      'Buxoro shahri',
      'Olot',
      'Buxoro',
      'G\'ijduvon',
      'Jondor',
      'Kogon',
      'Qorako\'l',
      'Qorovulbozor',
      'Peshku',
      'Romitan',
      'Shofirkon',
      'Vobkent',
    ],
    'Farg\'ona': [
      'Farg\'ona shahri',
      'Marg\'ilon shahri',
      'Quvasoy shahri',
      'Beshariq',
      'Bog\'dod',
      'Buvayda',
      'Dang\'ara',
      'Farg\'ona',
      'Furqat',
      'O\'zbekiston',
      'Qo\'qon',
      'Qo\'shtepa',
      'Quva',
      'Rishton',
      'So\'x',
      'Toshloq',
      'Uchko\'prik',
      'Yozyovon',
    ],
    'Jizzax': [
      'Jizzax shahri',
      'Arnasoy',
      'Baxmal',
      'Do\'stlik',
      'Forish',
      'G\'allaorol',
      'Sharof Rashidov',
      'Mirzacho\'l',
      'Paxtakor',
      'Yangiobod',
      'Zomin',
      'Zafarobod',
    ],
    'Xorazm': [
      'Urganch shahri',
      'Xiva shahri',
      'Bog\'ot',
      'Gurlan',
      'Xonqa',
      'Xazorasp',
      'Qo\'shko\'pir',
      'Shovot',
      'Urganch',
      'Yangiariq',
      'Yangibozor',
    ],
    'Namangan': [
      'Namangan shahri',
      'Chortoq',
      'Chust',
      'Kosonsoy',
      'Mingbuloq',
      'Namangan',
      'Norin',
      'Pop',
      'To\'raqo\'rg\'on',
      'Uchqo\'rg\'on',
      'Uychi',
      'Yangiqo\'rg\'on',
    ],
    'Navoiy': [
      'Navoiy shahri',
      'Zarafshon shahri',
      'Karmana',
      'Konimex',
      'Navbahor',
      'Nurota',
      'Tomdi',
      'Uchquduq',
      'Xatirchi',
    ],
    'Qashqadaryo': [
      'Qarshi shahri',
      'Chiroqchi',
      'Dehqonobod',
      'G\'uzor',
      'Qamashi',
      'Qarshi',
      'Kasbi',
      'Kitob',
      'Koson',
      'Mirishkor',
      'Muborak',
      'Nishon',
      'Shahrisabz',
      'Yakkabog\'',
    ],
    'Qoraqalpog\'iston Respublikasi': [
      'Nukus shahri',
      'Amudaryo',
      'Beruniy',
      'Chimboy',
      'Ellikqal\'a',
      'Kegeyli',
      'Mo\'ynoq',
      'Nukus',
      'Qonliko\'l',
      'Qo\'ng\'irot',
      'Shumanay',
      'Taxtako\'pir',
      'To\'rtko\'l',
      'Xo\'jayli',
    ],
    'Samarqand': [
      'Samarqand shahri',
      'Oqdaryo',
      'Bulung\'ur',
      'Ishtixon',
      'Jomboy',
      'Kattaqo\'rg\'on',
      'Narpay',
      'Nurobod',
      'Oqdaryo',
      'Pastdarg\'om',
      'Paxtachi',
      'Payariq',
      'Qo\'shrabot',
      'Samarqand',
      'Toyloq',
      'Urgut',
    ],
    'Sirdaryo': [
      'Guliston shahri',
      'Oqoltin',
      'Boyovut',
      'Guliston',
      'Mirzaobod',
      'Sardoba',
      'Sayxunobod',
      'Sirdaryo',
      'Xovos',
    ],
    'Surxondaryo': [
      'Termiz shahri',
      'Angor',
      'Boysun',
      'Denov',
      'Jarqo\'rg\'on',
      'Qiziriq',
      'Qo\'mqo\'rg\'on',
      'Muzrabot',
      'Oltinsoy',
      'Sariosiyo',
      'Sherobod',
      'Sho\'rchi',
      'Termiz',
      'Uzun',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Kategoriyalarni API dan yuklash
  Future<void> _loadCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final response = await supabase
          .from('categories')
          .select('id, name, icon_url')
          .order('name');

      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
        isLoadingCategories = false;
      });
    } catch (e) {
      print('Kategoriyalarni yuklashda xato: $e');
      setState(() => isLoadingCategories = false);
      Get.snackbar('Xato', 'Kategoriyalarni yuklab bo\'lmadi');
    }
  }

  // Sub-kategoriyalarni yuklash
  Future<void> _loadSubCategories(int categoryId) async {
    try {
      final response = await supabase
          .from('sub_categories')
          .select('id, name')
          .eq('category_id', categoryId)
          .order('name');

      setState(() {
        subCategories = List<Map<String, dynamic>>.from(response);
        formData['subCategoryId'] = null; // Reset sub-category
      });
    } catch (e) {
      print('Sub-kategoriyalarni yuklashda xato: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E\'lon Yaratish'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => setState(() => currentStep--),
              )
            : null,
      ),
      body: currentStep == 0
          ? _buildStep0UserType()
          : currentStep == 1
          ? _buildStep1BasicInfo()
          : currentStep == 2
          ? _buildStep2Location()
          : currentStep == 3
          ? _buildStep3Salary()
          : _buildStep4Images(),
    );
  }

  // ==================== STEP 0: USER TYPE ====================
  Widget _buildStep0UserType() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Siz kimsiniz?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildUserTypeCard(
            icon: Icons.person_search_rounded,
            title: 'Ish Qidiruvchi',
            subtitle: 'Men ish izlayapman',
            value: 'job_seeker',
            isSelected: userType == 'job_seeker',
            onTap: () {
              setState(() {
                userType = 'job_seeker';
                formData['userType'] = 'job_seeker';
              });
            },
          ),
          const SizedBox(height: 16),
          _buildUserTypeCard(
            icon: Icons.business_rounded,
            title: 'Ish Beruvchi',
            subtitle: 'Men ishchi qabul qilyapman',
            value: 'employer',
            isSelected: userType == 'employer',
            onTap: () {
              setState(() {
                userType = 'employer';
                formData['userType'] = 'employer';
              });
            },
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: userType == null
                  ? null
                  : () => setState(() => currentStep = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Keyingi',
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
    );
  }

  Widget _buildUserTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== STEP 1: BASIC INFO ====================
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(1, 5),
          const SizedBox(height: 24),
          const Text(
            'Asosiy Ma\'lumot',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: userType == 'job_seeker'
                ? 'Sizning F.I.O'
                : 'E\'lon Sarlavhasi',
            hint: userType == 'job_seeker'
                ? 'Aziz Aliyev'
                : 'Senior Flutter Developer kerak',
            onChanged: (value) => formData['title'] = value,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Tasnifi',
            hint: 'Ish tasnifi haqida ...',
            maxLines: 4,
            onChanged: (value) => formData['description'] = value,
          ),
          const SizedBox(height: 16),
          _buildLabel('Kategoriya'),
          const SizedBox(height: 12),
          if (isLoadingCategories)
            const Center(child: CircularProgressIndicator())
          else
            _buildCategorySelector(),
          const SizedBox(height: 16),
          // Sub-kategoriya
          if (formData['categoryId'] != null && subCategories.isNotEmpty) ...[
            _buildLabel('Sub-kategoriya'),
            const SizedBox(height: 12),
            _buildSubCategorySelector(),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 40),
          _buildNextButton(() {
            if ((formData['title']?.toString() ?? '').isEmpty) {
              Get.snackbar('Xato', 'Sarlavha yoki nomni kiriting');
              return;
            }
            if (formData['categoryId'] == null) {
              Get.snackbar('Xato', 'Kategoriyani tanlang');
              return;
            }
            setState(() => currentStep = 2);
          }),
        ],
      ),
    );
  }

  // ==================== STEP 2: LOCATION ====================
  Widget _buildStep2Location() {
    final regionList = regions['Uzbekiston'] ?? [];
    final districtList = (formData['region'] as String?)?.isNotEmpty == true
        ? districts[formData['region']] ?? []
        : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(2, 5),
          const SizedBox(height: 24),
          const Text(
            'Manzil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildLabel('Davlat'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: formData['country'] as String,
              isExpanded: true,
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: 'Uzbekiston',
                  child: Text('Uzbekiston'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  formData['country'] = value ?? 'Uzbekiston';
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('Viloyat'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: (formData['region'] as String?)?.isEmpty == true
                  ? null
                  : formData['region'] as String?,
              isExpanded: true,
              underline: Container(),
              hint: const Text('Viloyatni tanlang'),
              items: regionList
                  .map(
                    (region) =>
                        DropdownMenuItem(value: region, child: Text(region)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  formData['region'] = value ?? '';
                  formData['district'] = '';
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          if (districtList.isNotEmpty) ...[
            _buildLabel('Tuman'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: (formData['district'] as String?)?.isEmpty == true
                    ? null
                    : formData['district'] as String?,
                isExpanded: true,
                underline: Container(),
                hint: const Text('Tumanni tanlang'),
                items: districtList
                    .map<DropdownMenuItem<String>>(
                      (district) => DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => formData['district'] = value ?? '');
                },
              ),
            ),
          ],
          const SizedBox(height: 40),
          _buildNextButton(() {
            if ((formData['region'] as String?)?.isEmpty ?? true) {
              Get.snackbar('Xato', 'Viloyatni tanlang');
              return;
            }
            setState(() => currentStep = 3);
          }),
        ],
      ),
    );
  }

  // ==================== STEP 3: SALARY ====================
  Widget _buildStep3Salary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(3, 5),
          const SizedBox(height: 24),
          Text(
            userType == 'employer' ? 'Maosh va Talablar' : 'Kutayotgan Maosh',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (userType == 'employer') ...[
            _buildTextField(
              label: 'Oylik To\'lov (Minimum) UZS',
              hint: '1000000',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                formData['salaryMin'] = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Oylik To\'lov (Maksimum) UZS',
              hint: '3000000',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                formData['salaryMax'] = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Asosiy Talablar',
              hint: '3+ yil tajriba, Flutter, Dart ...',
              maxLines: 3,
              onChanged: (value) => formData['requirementsMain'] = value,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Qo\'shimcha Talablar',
              hint: 'Ingliz tili, Git, REST API ...',
              maxLines: 3,
              onChanged: (value) => formData['requirementsBasic'] = value,
            ),
          ] else ...[
            _buildTextField(
              label: 'Kutayotgan Oylik (UZS)',
              hint: '2000000',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                formData['salaryMin'] = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Tajribangiz',
              hint: '5 yil Flutter development ...',
              maxLines: 3,
              onChanged: (value) => formData['requirementsMain'] = value,
            ),
          ],
          const SizedBox(height: 40),
          _buildNextButton(() {
            setState(() => currentStep = 4);
          }),
        ],
      ),
    );
  }

  // ==================== STEP 4: IMAGES ====================
  Widget _buildStep4Images() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(4, 5),
          const SizedBox(height: 24),
          const Text(
            'Rasmlarni Qo\'shing',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Post uchun rasmlarni qo\'shish (ixtiyoriy)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rasm qo\'shish uchun bosing',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(Maksimal 5 ta rasm)',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (selectedImages.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Tanlangan rasmlar:'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
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
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Tekshirish Uchun Yuborish',
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
    );
  }

  // ==================== HELPER METHODS ====================
  Future<void> _pickImages() async {
    if (selectedImages.length >= 5) {
      Get.snackbar('Xato', 'Maksimal 5 ta rasm qo\'shish mumkin');
      return;
    }

    final pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        for (var file in pickedFiles) {
          if (selectedImages.length < 5) {
            selectedImages.add(File(file.path));
          }
        }
      });
    }
  }

  Future<void> _submitPost() async {
    setState(() => isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.snackbar('Xato', 'Login qiling');
        setState(() => isLoading = false);
        return;
      }

      final postResponse = await supabase.from('posts').insert({
        'user_id': userId,
        'title': formData['title'],
        'description': formData['description'],
        'category_id': formData['categoryId'],
        'sub_category_id': formData['subCategoryId'],
        'location': '${formData['region']}, ${formData['district']}',
        'salary_min': formData['salaryMin'],
        'salary_max': formData['salaryMax'],
        'requirements_main': formData['requirementsMain'],
        'requirements_basic': formData['requirementsBasic'],
        'status': 'pending',
        'is_active': true,
      }).select();

      if (postResponse != null && postResponse.isNotEmpty) {
        final postId = postResponse[0]['id'];

        // Rasmlarni yuklash
        if (selectedImages.isNotEmpty) {
          for (var image in selectedImages) {
            final fileName =
                'post_$postId/${DateTime.now().millisecondsSinceEpoch}.jpg';
            await supabase.storage.from('post-images').upload(fileName, image);

            final imageUrl = supabase.storage
                .from('post-images')
                .getPublicUrl(fileName);

            await supabase.from('post_images').insert({
              'post_id': postId,
              'image_url': imageUrl,
            });
          }
        }

        // Muvaffaqiyatli xabar
        Get.snackbar(
          'Muvaffaqiyatli!',
          'E\'loningiz tekshirish uchun yuborildi',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );

        // Dialog bilan ma'lumot berish
        await Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.access_time, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('Tekshiruvda'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E\'loningiz muvaffaqiyatli yuborildi!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '📋 Keyingi qadamlar:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1️⃣ Moderatorlarimiz e\'loningizni ko\'rib chiqadi',
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '2️⃣ Tasdiqlangandan so\'ng ommaga ko\'rinadi',
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '3️⃣ Bu jarayon 24 soatgacha davom etishi mumkin',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bildirishnomalar orqali natijani bilib olasiz.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Dialog yopish
                  Get.offNamed('/home'); // Home ga o'tish
                },
                child: const Text(
                  'Tushunarli',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      print('Xato: $e');
      Get.snackbar(
        'Xato',
        'E\'lon yaratishda xatolik yuz berdi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ==================== WIDGETS ====================
  Widget _buildStepIndicator(int current, int total) {
    return Row(
      children: [
        for (int i = 1; i <= total; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i <= current ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = formData['categoryId'] == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  formData['categoryId'] = cat['id'];
                  formData['subCategoryId'] = null;
                  subCategories = [];
                });
                _loadSubCategories(cat['id']);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                ),
                child: Row(
                  children: [
                    if (cat['icon_url'] != null && cat['icon_url'].isNotEmpty)
                      Text(
                        cat['icon_url'],
                        style: const TextStyle(fontSize: 16),
                      )
                    else
                      const Icon(Icons.category, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      cat['name'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: subCategories.map((subCat) {
          final isSelected = formData['subCategoryId'] == subCat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  formData['subCategoryId'] = subCat['id'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                ),
                child: Text(
                  subCat['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNextButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Keyingi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
