import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  int currentStep = 0;

  // ==================== USER TYPE ====================
  String? userType; // 'job_seeker' yoki 'employer'

  // ==================== FORM DATA ====================
  final formData = {
    'userType': '',
    'title': '',
    'description': '',
    'location': '',
    'categoryId': 1,
    'salaryMin': 0,
    'salaryMax': 0,
    'requirementsMain': '',
    'requirementsBasic': '',
    'duration': 0,
  };

  final List<Map<String, dynamic>> categories = [
    {'id': 1, 'name': 'IT', 'icon': '💻'},
    {'id': 2, 'name': 'Qurilish', 'icon': '🏗️'},
    {'id': 3, 'name': 'Ta\'lim', 'icon': '📚'},
    {'id': 4, 'name': 'Xizmat', 'icon': '🛎️'},
    {'id': 5, 'name': 'Transport', 'icon': '🚗'},
  ];

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
                onPressed: () {
                  setState(() => currentStep--);
                },
              )
            : null,
      ),
      body: currentStep == 0
          ? _buildStep0UserType()
          : currentStep == 1
          ? _buildStep1BasicInfo()
          : currentStep == 2
          ? _buildStep2SalaryRequirements()
          : _buildStep3Images(),
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
                  : () {
                      setState(() => currentStep = 1);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey[300],
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
          _buildStepIndicator(1),
          const SizedBox(height: 24),
          const Text(
            'Asosiy Ma\'lumot',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: userType == 'job_seeker'
                ? 'Sizning Nomingiz'
                : 'E\'lon Sarlavhasi',
            hint: userType == 'job_seeker'
                ? 'Masalan: Aziz Aliyev'
                : 'Masalan: Senior Flutter Developer kerak',
            onChanged: (value) {
              formData['title'] = value;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Ish Joyi',
            hint: 'Masalan: Tashkent, O\'zbekiston',
            onChanged: (value) {
              formData['location'] = value;
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('Kategoriya'),
          const SizedBox(height: 12),
          _buildCategorySelector(),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if ((formData['title']?.toString() ?? '').isEmpty ||
                    (formData['location']?.toString() ?? '').isEmpty) {
                  Get.snackbar('Xato', 'Barcha maydonlarni to\'ldiring');
                  return;
                }
                setState(() => currentStep = 2);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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

  // ==================== STEP 2: SALARY & REQUIREMENTS ====================
  Widget _buildStep2SalaryRequirements() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(2),
          const SizedBox(height: 24),
          Text(
            userType == 'employer' ? 'Maosh va Talablar' : 'Kutayotgan Maosh',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (userType == 'employer') ...[
            _buildTextField(
              label: 'Oylik To\'lovni Min (UZS)',
              hint: '1000000',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                formData['salaryMin'] = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Oylik To\'lovni Maks (UZS)',
              hint: '3000000',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                formData['salaryMax'] = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Asosiy Talablar',
              hint: 'Masalan: 3+ yil tajriba, Flutter, Dart...',
              maxLines: 3,
              onChanged: (value) {
                formData['requirementsMain'] = value;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Qo\'shimcha Talablar',
              hint: 'Masalan: Ingliz tili, Git, REST API...',
              maxLines: 3,
              onChanged: (value) {
                formData['requirementsBasic'] = value;
              },
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
              label: 'Sizning Tajribangiz',
              hint: 'Masalan: 5 yil Flutter develop...',
              maxLines: 3,
              onChanged: (value) {
                formData['requirementsMain'] = value;
              },
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() => currentStep = 3);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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

  // ==================== STEP 3: IMAGES ====================
  Widget _buildStep3Images() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(3),
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
            onTap: () {
              Get.snackbar('Xato', 'Rasmni qo\'shish hali qo\'yilmagan');
            },
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
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
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'E\'lonni Yaratish',
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

  // ==================== SUBMIT POST ====================
  void _submitPost() {
    print('User Type: ${formData['userType']}');
    print('Title: ${formData['title']}');
    print('Location: ${formData['location']}');
    print('Salary Min: ${formData['salaryMin']}');
    print('Salary Max: ${formData['salaryMax']}');
    print('Requirements: ${formData['requirementsMain']}');

    Get.snackbar(
      'Muvaffaqiyatli',
      'E\'lon yaratildi',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    Future.delayed(const Duration(seconds: 1), () {
      Get.offNamed('/home');
    });
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildStepIndicator(int step) {
    return Row(
      children: [
        for (int i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i < step ? Colors.blue : Colors.grey[300],
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
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                ),
                child: Row(
                  children: [
                    Text(cat['icon'], style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      cat['name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                        color: isSelected ? Colors.blue : null,
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
}
