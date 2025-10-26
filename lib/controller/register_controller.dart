import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  var currentStep = 0.obs;
  final pageController = PageController();

  // ✅ ERROR MESSAGES (har bir qadam uchun)
  var step1Error = ''.obs;
  var step2Error = ''.obs;
  var step3Error = ''.obs;
  var step4Error = ''.obs;

  // ✅ ACCOUNT TYPE
  var userType = ''.obs;

  // ✅ PERSONAL INFO
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyNameController = TextEditingController();

  // ✅ CONTACT INFO
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();

  // ✅ LOCATION INFO - Dropdown uchun
  var selectedRegion = ''.obs;
  var selectedDistrict = ''.obs;
  var selectedVillage = ''.obs;
  final addressController = TextEditingController();

  // ✅ Dropdown ma'lumotlari
  var availableDistricts = <String>[].obs;
  var availableVillages = <String>[].obs;

  // ✅ PROFILE PHOTO
  var profilePhotoPath = ''.obs;
  File? profilePhotoFile;

  var isPasswordHidden = true.obs;
  var isLoading = false.obs;

  // ✅ Telefon formatter
  final phoneFormatter = PhoneInputFormatter();

  // ==================== VILOYATLAR VA TUMANLAR ====================
  final Map<String, Map<String, List<String>>> regions = {
    'Toshkent shahri': {
      'Bektemir': ['Sergeli', 'Qoyliq', 'Salar', 'Yashnobod'],
      'Chilonzor': ['Chilonzor', 'Navbahor', 'Qatortol', 'Minor'],
      'Mirobod': ['Mirobod', 'Yakkasaroy', 'Sebzor', 'Paxtakor'],
      'Mirzo Ulugʻbek': ['Ulugʻbek', 'Qorasu', 'Salar', 'Shayxontohur'],
      'Olmazor': ['Olmazor', 'Zarqaynar', 'Bodomzor', 'Temir yoʻl'],
      'Sergeli': ['Sergeli', 'Qibray', 'Halqabad', 'Yangiobod'],
      'Shayhontohur': ['Shayhontohur', 'Chorsu', 'Eski shahar', 'Ipak yoʻli'],
      'Uchtepa': ['Uchtepa', 'Sabirabad', 'Qorasaroy', 'Minor'],
      'Yashnobod': ['Yashnobod', 'Parkent yoʻli', 'Choshtepa', 'Qoraqamish'],
      'Yakkasaroy': ['Yakkasaroy', 'Uzbekiston', 'Amir Temur', 'Minor'],
      'Yunusobod': ['Yunusobod', 'TTZ', 'Chilonzor', 'Minor'],
    },
    'Toshkent viloyati': {
      'Angren': ['Angren shahri', 'Shakar', 'Akhangaron', 'Dustlik'],
      'Bekobod': ['Bekobod shahri', 'Keles', 'Dustlik', 'Chinor'],
      'Boʻka': ['Boʻka', 'Xonobod', 'Guliston', 'Chinobod'],
      'Boʻstonliq': ['Boʻstonliq', 'Gazalkent', 'Humsan', 'Parkent'],
      'Chinoz': ['Chinoz', 'Toytepa', 'Qibray', 'Yangibozor'],
      'Ohangaron': [
        'Ohangaron shahri',
        'Quyi Ohangaron',
        'Yangiobod',
        'Teshiktosh',
      ],
      'Oqqoʻrgʻon': ['Oqqoʻrgʻon', 'Keles', 'Chinobod', 'Navbahor'],
      'Parkent': ['Parkent', 'Teshiktosh', 'Shodi', 'Guliston'],
      'Piskent': ['Piskent', 'Ulugʻbek', 'Toyloq', 'Chinobod'],
      'Qibray': ['Qibray', 'Quyi tepa', 'Halqabad', 'Sergeli'],
      'Quyi Chirchiq': ['Quyi Chirchiq', 'Tuyabogʻiz', 'Dustlik', 'Keles'],
      'Oʻrta Chirchiq': ['Toytepa', 'Arnasoy', 'Yangiqoʻrgʻon', 'Chinor'],
      'Yuqori Chirchiq': [
        'Yuqori Chirchiq',
        'Bustonliq',
        'Burchmulla',
        'Parkent',
      ],
      'Zangiota': ['Zangiota', 'Qoraqamish', 'Yangibozor', 'Navbahor'],
    },
    'Andijon': {
      'Andijon shahri': ['Markaz', 'Bogʻishamol', 'Yangi shahar', 'Paxtaobod'],
      'Andijon tumani': [
        'Andijon qishlogʻi',
        'Asaka',
        'Xoʻjaobod',
        'Oltinkoʻl',
      ],
      'Asaka': ['Asaka shahri', 'Paxtakor', 'Guliston', 'Navbahor'],
      'Baliqchi': ['Baliqchi', 'Navbahor', 'Qoʻrgʻontepa', 'Dustlik'],
      'Boʻz': ['Boʻz', 'Vodil', 'Xalqobod', 'Paxtakor'],
      'Buloqboshi': ['Buloqboshi', 'Chinobod', 'Guliston', 'Navbahor'],
      'Izboskan': ['Izboskan', 'Navbahor', 'Paxtaobod', 'Chinor'],
      'Jalolquduq': ['Jalolquduq', 'Quva', 'Oqtepa', 'Guliston'],
      'Xoʻjaobod': ['Xoʻjaobod shahri', 'Oltinkoʻl', 'Paxtaobod', 'Dustlik'],
      'Marhamat': ['Marhamat', 'Navbahor', 'Bulungʻur', 'Chinobod'],
      'Oltinkoʻl': ['Oltinkoʻl', 'Qoʻrgʻontepa', 'Guliston', 'Navbahor'],
      'Paxtaobod': ['Paxtaobod shahri', 'Dustlik', 'Yangiobod', 'Chinor'],
      'Qoʻrgʻontepa': ['Qoʻrgʻontepa shahri', 'Vodil', 'Novkent', 'Paxtakor'],
      'Shahrixon': ['Shahrixon', 'Oqtepa', 'Beshkoʻprik', 'Guliston'],
      'Ulugʻnor': ['Ulugʻnor', 'Navbahor', 'Chinobod', 'Paxtakor'],
    },
    'Buxoro': {
      'Buxoro shahri': ['Markaz', 'Kogon', 'Eski shahar', 'Yangi shahar'],
      'Buxoro tumani': ['Gazli', 'Romitan', 'Vobkent', 'Shofirkon'],
      'Olot': ['Olot', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Gʻijduvon': ['Gʻijduvon', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Jondor': ['Jondor', 'Qorakoʻl', 'Navbahor', 'Chinor'],
      'Kogon': ['Kogon shahri', 'Vobkent', 'Romitan', 'Shofirkon'],
      'Peshku': ['Peshku', 'Yangibozor', 'Guliston', 'Navbahor'],
      'Qorakoʻl': ['Qorakoʻl', 'Jondor', 'Yangiobod', 'Chinobod'],
      'Qorovulbozor': ['Qorovulbozor', 'Navbahor', 'Paxtakor', 'Dustlik'],
      'Romitan': ['Romitan', 'Kogon', 'Vobkent', 'Yangibozor'],
      'Shofirkon': ['Shofirkon', 'Romitan', 'Kogon', 'Navbahor'],
      'Vobkent': ['Vobkent', 'Kogon', 'Romitan', 'Guliston'],
    },
    'Fargʻona': {
      'Fargʻona shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Fargʻona tumani': ['Vodil', 'Yozyovon', 'Qoʻshtepa', 'Rishton'],
      'Beshariq': ['Beshariq', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Bogʻdod': ['Bogʻdod', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Buvayda': ['Buvayda', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Dangʻara': ['Dangʻara', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Furqat': ['Furqat', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Margʻilon': [
        'Margʻilon shahri',
        'Ipakchi',
        'Yangi Margʻilon',
        'Qoʻqon yoʻli',
      ],
      'Oltiariq': ['Oltiariq', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Quva': ['Quva', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Qoʻqon': ['Qoʻqon shahri', 'Markaz', 'Yangi shahar', 'Minor'],
      'Qoʻshtepa': ['Qoʻshtepa', 'Vodil', 'Yangibozor', 'Navbahor'],
      'Rishton': ['Rishton', 'Chinobod', 'Paxtakor', 'Guliston'],
      'Soʻx': ['Soʻx', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Toshloq': ['Toshloq', 'Guliston', 'Paxtakor', 'Dustlik'],
      'Oʻzbekiston': ['Oʻzbekiston', 'Navbahor', 'Chinobod', 'Yangibozor'],
      'Yozyovon': ['Yozyovon', 'Vodil', 'Qoʻshtepa', 'Navbahor'],
    },
    'Jizzax': {
      'Jizzax shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Arnasoy': ['Arnasoy', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Baxmal': ['Baxmal', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Doʻstlik': ['Doʻstlik', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Forish': ['Forish', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Gʻallaorol': ['Gʻallaorol', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Mirzachoʻl': ['Mirzachoʻl', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Paxtakor': ['Paxtakor', 'Guliston', 'Navbahor', 'Dustlik'],
      'Yangiobod': ['Yangiobod', 'Chinobod', 'Paxtakor', 'Yangibozor'],
      'Zafarobod': ['Zafarobod', 'Navbahor', 'Guliston', 'Dustlik'],
      'Zomin': ['Zomin', 'Yangibozor', 'Chinobod', 'Paxtakor'],
      'Zarbdor': ['Zarbdor', 'Navbahor', 'Guliston', 'Yangibozor'],
    },
    'Xorazm': {
      'Urganch shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Bogʻot': ['Bogʻot', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Gurlan': ['Gurlan', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Xonqa': ['Xonqa', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Xazorasp': ['Xazorasp', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Xiva': ['Xiva shahri', 'Ichon qalʻa', 'Dishan qalʻa', 'Yangi shahar'],
      'Qoʻshkoʻpir': ['Qoʻshkoʻpir', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Shovot': ['Shovot', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Urganch': ['Urganch tumani', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Yangiariq': ['Yangiariq', 'Chinobod', 'Yangibozor', 'Navbahor'],
      'Yangibozor': ['Yangibozor', 'Paxtakor', 'Guliston', 'Dustlik'],
    },
    'Namangan': {
      'Namangan shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Chortoq': ['Chortoq', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Chust': ['Chust', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Kosonsoy': ['Kosonsoy', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Mingbuloq': ['Mingbuloq', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Namangan': ['Namangan tumani', 'Vodil', 'Paxtakor', 'Guliston'],
      'Norin': ['Norin', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Pop': ['Pop', 'Chinobod', 'Paxtakor', 'Guliston'],
      'Toʻraqoʻrgʻon': ['Toʻraqoʻrgʻon', 'Navbahor', 'Yangibozor', 'Dustlik'],
      'Uchqoʻrgʻon': ['Uchqoʻrgʻon', 'Guliston', 'Paxtakor', 'Chinobod'],
      'Uychi': ['Uychi', 'Navbahor', 'Yangibozor', 'Paxtakor'],
      'Yangiqoʻrgʻon': ['Yangiqoʻrgʻon', 'Chinobod', 'Guliston', 'Dustlik'],
    },
    'Navoiy': {
      'Navoiy shahri': ['Markaz', 'Yangi shahar', 'Karmana', 'Minor'],
      'Konimex': ['Konimex', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Karmana': ['Karmana', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Navbahor': ['Navbahor', 'Guliston', 'Paxtakor', 'Chinobod'],
      'Nurota': ['Nurota', 'Yangibozor', 'Navbahor', 'Paxtakor'],
      'Qiziltepa': ['Qiziltepa', 'Chinobod', 'Guliston', 'Dustlik'],
      'Tomdi': ['Tomdi', 'Navbahor', 'Yangibozor', 'Paxtakor'],
      'Uchquduq': ['Uchquduq', 'Guliston', 'Chinobod', 'Navbahor'],
      'Xatirchi': ['Xatirchi', 'Paxtakor', 'Yangibozor', 'Dustlik'],
      'Zarafshon': ['Zarafshon shahri', 'Navbahor', 'Guliston', 'Minor'],
    },
    'Qashqadaryo': {
      'Qarshi shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Chiroqchi': ['Chiroqchi', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Dehqonobod': ['Dehqonobod', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Gʻuzor': ['Gʻuzor', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Kasbi': ['Kasbi', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Kitob': ['Kitob', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Koson': ['Koson', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Mirishkor': ['Mirishkor', 'Guliston', 'Paxtakor', 'Navbahor'],
      'Muborak': ['Muborak', 'Chinobod', 'Yangibozor', 'Dustlik'],
      'Nishon': ['Nishon', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Qarshi': ['Qarshi tumani', 'Vodil', 'Chinobod', 'Yangibozor'],
      'Qamashi': ['Qamashi', 'Guliston', 'Navbahor', 'Paxtakor'],
      'Shahrisabz': ['Shahrisabz shahri', 'Markaz', 'Yangi shahar', 'Minor'],
      'Yakkabogʻ': ['Yakkabogʻ', 'Navbahor', 'Chinobod', 'Guliston'],
    },
    'Qoraqalpogʻiston': {
      'Nukus shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Amudaryo': ['Amudaryo', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Beruniy': ['Beruniy', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Kegeyli': ['Kegeyli', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Qonlikoʻl': ['Qonlikoʻl', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Qoraoʻzak': ['Qoraoʻzak', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Moʻynoq': ['Moʻynoq', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Nukus': ['Nukus tumani', 'Guliston', 'Paxtakor', 'Navbahor'],
      'Taxtakoʻpir': ['Taxtakoʻpir', 'Chinobod', 'Yangibozor', 'Dustlik'],
      'Toʻrtkoʻl': ['Toʻrtkoʻl', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Xoʻjayli': ['Xoʻjayli', 'Guliston', 'Chinobod', 'Yangibozor'],
      'Chimboy': ['Chimboy', 'Navbahor', 'Paxtakor', 'Dustlik'],
      'Shumanay': ['Shumanay', 'Chinobod', 'Guliston', 'Navbahor'],
      'Ellikqalʻa': ['Ellikqalʻa', 'Paxtakor', 'Yangibozor', 'Dustlik'],
    },
    'Samarqand': {
      'Samarqand shahri': ['Markaz', 'Registon', 'Yangi shahar', 'Minor'],
      'Bulungʻur': ['Bulungʻur', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Jomboy': ['Jomboy', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Ishtixon': ['Ishtixon', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Kattaqoʻrgʻon': [
        'Kattaqoʻrgʻon shahri',
        'Markaz',
        'Yangibozor',
        'Minor',
      ],
      'Narpay': ['Narpay', 'Chinobod', 'Paxtakor', 'Guliston'],
      'Nurobod': ['Nurobod', 'Navbahor', 'Yangibozor', 'Dustlik'],
      'Oqdaryo': ['Oqdaryo', 'Guliston', 'Chinobod', 'Paxtakor'],
      'Paxtachi': ['Paxtachi', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Payariq': ['Payariq', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Pastdargʻom': ['Pastdargʻom', 'Navbahor', 'Chinobod', 'Yangibozor'],
      'Qoʻshrabot': ['Qoʻshrabot', 'Guliston', 'Paxtakor', 'Navbahor'],
      'Samarqand': ['Samarqand tumani', 'Vodil', 'Chinobod', 'Yangibozor'],
      'Toyloq': ['Toyloq', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Urgut': ['Urgut', 'Navbahor', 'Yangibozor', 'Chinobod'],
    },
    'Sirdaryo': {
      'Guliston shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Boyovut': ['Boyovut', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Guliston': ['Guliston tumani', 'Vodil', 'Chinobod', 'Yangibozor'],
      'Mirzaobod': ['Mirzaobod', 'Navbahor', 'Paxtakor', 'Dustlik'],
      'Oqoltin': ['Oqoltin', 'Guliston', 'Yangibozor', 'Chinobod'],
      'Sardoba': ['Sardoba', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Sayxunobod': ['Sayxunobod', 'Chinobod', 'Yangibozor', 'Dustlik'],
      'Sirdaryo': ['Sirdaryo', 'Paxtakor', 'Guliston', 'Navbahor'],
      'Xovos': ['Xovos', 'Yangibozor', 'Chinobod', 'Paxtakor'],
    },
    'Surxondaryo': {
      'Termiz shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Angor': ['Angor', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Boysun': ['Boysun', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Denov': ['Denov', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Jarqoʻrgʻon': ['Jarqoʻrgʻon', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Qiziriq': ['Qiziriq', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Qumqoʻrgʻon': ['Qumqoʻrgʻon', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Muzrabot': ['Muzrabot', 'Guliston', 'Paxtakor', 'Navbahor'],
      'Oltinsoy': ['Oltinsoy', 'Chinobod', 'Yangibozor', 'Dustlik'],
      'Sariosiyo': ['Sariosiyo', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Sherobod': ['Sherobod', 'Guliston', 'Chinobod', 'Yangibozor'],
      'Shoʻrchi': ['Shoʻrchi', 'Paxtakor', 'Navbahor', 'Dustlik'],
      'Termiz': ['Termiz tumani', 'Vodil', 'Yangibozor', 'Chinobod'],
      'Uzun': ['Uzun', 'Navbahor', 'Guliston', 'Paxtakor'],
    },
  };

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void selectUserType(String type) {
    userType.value = type;
    step1Error.value = ''; // Xatolikni tozalash
  }

  // ✅ Viloyat tanlash
  void selectRegion(String region) {
    selectedRegion.value = region;
    selectedDistrict.value = '';
    selectedVillage.value = '';

    if (regions.containsKey(region)) {
      availableDistricts.value = regions[region]!.keys.toList();
      availableVillages.clear();
    }
    step4Error.value = ''; // Xatolikni tozalash
  }

  // ✅ Tuman tanlash
  void selectDistrict(String district) {
    selectedDistrict.value = district;
    selectedVillage.value = '';

    if (regions[selectedRegion.value] != null) {
      availableVillages.value = regions[selectedRegion.value]![district] ?? [];
    }
    step4Error.value = ''; // Xatolikni tozalash
  }

  // ✅ Mahalla tanlash
  void selectVillage(String village) {
    selectedVillage.value = village;
    step4Error.value = ''; // Xatolikni tozalash
  }

  void nextStep() {
    if (currentStep.value < 4) {
      currentStep.value++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ✅ PROFILE PHOTO FUNCTIONS
  Future<void> pickProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        profilePhotoFile = File(image.path);
        profilePhotoPath.value = image.path;
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Rasm tanlanmadi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        profilePhotoFile = File(image.path);
        profilePhotoPath.value = image.path;
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Rasm olinmadi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> chooseFromGallery() async {
    await pickProfilePhoto();
  }

  // ✅ UPLOAD PHOTO TO SUPABASE STORAGE
  Future<String?> uploadProfilePhoto(String userId) async {
    if (profilePhotoFile == null) return null;

    try {
      final fileExt = profilePhotoFile!.path.split('.').last;
      final fileName = '$userId.$fileExt';
      final filePath = '$userId.$fileExt';

      // Agar oldingi rasm bo'lsa, o'chirish
      try {
        await supabase.storage.from('user-pictures').remove([filePath]);
      } catch (e) {
        // Agar fayl yo'q bo'lsa, xato bermaydi
      }

      // Yangi rasmni yuklash
      await supabase.storage
          .from('user-pictures')
          .upload(
            filePath,
            profilePhotoFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = supabase.storage
          .from('user-pictures')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('❌ Photo upload error: $e');

      // Xato bo'lsa ham davom etamiz, chunki rasm ixtiyoriy
      Get.snackbar(
        'Ogohlantirish',
        'Rasm yuklashda muammo, lekin ro\'yxatdan o\'tish davom etadi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return null;
    }
  }

  // ✅ REGISTER USER
  Future<void> registerUser() async {
    // Faqat raqamlarni olamiz
    final phoneDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phone = '+998$phoneDigits'; // +998 qo'shamiz

    final password = passwordController.text.trim();
    final username = usernameController.text.trim();
    final bio = bioController.text.trim();
    final type = userType.value;

    // ✅ EMAIL VALIDATION - faqat @gmail.com yoki bo'sh
    String email = emailController.text.trim();
    if (email.isNotEmpty && !email.endsWith('@gmail.com')) {
      Get.snackbar(
        'Xato',
        'Faqat @gmail.com emaillar qabul qilinadi yoki emailni bo\'sh qoldiring',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Agar email bo'sh bo'lsa, fake email yaratamiz
    if (email.isEmpty) {
      email = '${username}_${DateTime.now().millisecondsSinceEpoch}@jobhub.uz';
    }

    // ✅ FINAL VALIDATION
    if (phoneDigits.length != 9) {
      Get.snackbar(
        'Xato',
        'Telefon raqam 9 ta raqamdan iborat bo\'lishi kerak',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (password.length < 6 ||
        username.length < 3 ||
        bio.isEmpty ||
        type.isEmpty) {
      Get.snackbar(
        'Xato',
        'Iltimos, barcha majburiy maydonlarni to\'g\'ri to\'ldiring',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // 1️⃣ Username bandligini tekshirish
      final existingUsername = await supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        Get.snackbar(
          'Xato',
          'Bu username allaqachon ishlatilgan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 2️⃣ Telefon raqam bandligini tekshirish
      final existingPhone = await supabase
          .from('users')
          .select()
          .eq('phone_number', phone)
          .maybeSingle();

      if (existingPhone != null) {
        Get.snackbar(
          'Xato',
          'Bu telefon raqam allaqachon ro\'yxatdan o\'tgan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 3️⃣ Supabase Auth orqali ro'yxatdan o'tish
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        Get.snackbar(
          'Xato',
          'Ro\'yxatdan o\'tishda muammo yuz berdi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 4️⃣ Profile photo upload (agar tanlangan bo'lsa)
      String? photoUrl;
      if (profilePhotoFile != null) {
        photoUrl = await uploadProfilePhoto(user.id);
      }

      // 5️⃣ Full location string yaratish
      final fullLocation =
          '${selectedRegion.value}, ${selectedDistrict.value}, ${selectedVillage.value}, ${addressController.text.trim()}';

      // 6️⃣ Ism/Kompaniya nomini aniqlash
      String firstName = '';
      String lastName = '';
      if (type == 'company') {
        firstName = companyNameController.text.trim();
        lastName = '';
      } else {
        firstName = firstNameController.text.trim();
        lastName = lastNameController.text.trim();
      }

      // 7️⃣ "users" jadvaliga qo'shish
      await supabase.from('users').insert({
        'id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'phone_number': phone,
        'bio': bio,
        'profile_photo_url': photoUrl,
        'location': fullLocation,
        'user_type': type == 'individual' ? 'job_seeker' : 'employer',
        'is_email_verified': false,
        'is_active': true,
        'rating': 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      Get.snackbar(
        'Muvaffaqiyatli',
        'Ro\'yxatdan o\'tish yakunlandi! Login qiling.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // ✅ Login sahifasiga o'tish
      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/login');
      clearForm();
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        Get.snackbar(
          'Xato',
          'Bu email allaqachon ro\'yxatdan o\'tgan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Auth Xatosi',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } on PostgrestException catch (e) {
      Get.snackbar(
        'Database Xatosi',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Xato',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    companyNameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    usernameController.clear();
    bioController.clear();
    addressController.clear();
    userType.value = '';
    selectedRegion.value = '';
    selectedDistrict.value = '';
    selectedVillage.value = '';
    profilePhotoPath.value = '';
    profilePhotoFile = null;
    currentStep.value = 0;
    availableDistricts.clear();
    availableVillages.clear();
    step1Error.value = '';
    step2Error.value = '';
    step3Error.value = '';
    step4Error.value = '';
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    companyNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    bioController.dispose();
    addressController.dispose();
    pageController.dispose();
    super.onClose();
  }
}

// ✅ TELEFON FORMATTER CLASS
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Faqat raqamlarni qoldirish
    String digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    // Maksimal 9 ta raqam
    if (digitsOnly.length > 9) {
      digitsOnly = digitsOnly.substring(0, 9);
    }

    // Format: XX XXX XX XX
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
