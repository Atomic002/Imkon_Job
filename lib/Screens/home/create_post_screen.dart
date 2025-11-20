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

  final currentStep = 0.obs;
  final isLoading = false.obs;
  final isLoadingCategories = false.obs;
  final postType = Rxn<String>();
  final selectedImages = <File>[].obs;
  final categories = <Map<String, dynamic>>[].obs;
  final subCategories = <Map<String, dynamic>>[].obs;
  final selectedSubCategories = <int>[].obs;
  final savedPhoneNumbers = <String>[].obs;

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

  final formData = {
    'postType': '',
    'title': '',
    'description': '',
    'region': '',
    'district': '',
    'village': '',
    'categoryId': null,
    'categoryName': '',
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
      'Bo\'ka': ['Bo\'ka', 'Xonobod', 'Guliston', 'Chinobod'],
      'Bo\'stonliq': ['Bo\'stonliq', 'Gazalkent', 'Humsan', 'Parkent'],
      'Chinoz': ['Chinoz', 'Toytepa', 'Qibray', 'Yangibozor'],
      'Ohangaron': [
        'Ohangaron shahri',
        'Quyi Ohangaron',
        'Yangiobod',
        'Teshiktosh',
      ],
      'Oqqo\'rg\'on': ['Oqqo\'rg\'on', 'Keles', 'Chinobod', 'Navbahor'],
      'Parkent': ['Parkent', 'Teshiktosh', 'Shodi', 'Guliston'],
      'Piskent': ['Piskent', 'Ulug\'bek', 'Toyloq', 'Chinobod'],
      'Qibray': ['Qibray', 'Quyi tepa', 'Halqabad', 'Sergeli'],
      'Quyi Chirchiq': ['Quyi Chirchiq', 'Tuyabog\'iz', 'Dustlik', 'Keles'],
      'O\'rta Chirchiq': ['Toytepa', 'Arnasoy', 'Yangiqo\'rg\'on', 'Chinor'],
      'Yuqori Chirchiq': [
        'Yuqori Chirchiq',
        'Bustonliq',
        'Burchmulla',
        'Parkent',
      ],
      'Zangiota': ['Zangiota', 'Qoraqamish', 'Yangibozor', 'Navbahor'],
    },
    'Andijon': {
      'Andijon shahri': ['Markaz', 'Bog\'ishamol', 'Yangi shahar', 'Paxtaobod'],
      'Andijon tumani': [
        'Andijon qishlog\'i',
        'Asaka',
        'Xo\'jaobod',
        'Oltinko\'l',
      ],
      'Asaka': ['Asaka shahri', 'Paxtakor', 'Guliston', 'Navbahor'],
      'Baliqchi': ['Baliqchi', 'Navbahor', 'Qo\'rg\'ontepa', 'Dustlik'],
      'Bo\'z': ['Bo\'z', 'Vodil', 'Xalqobod', 'Paxtakor'],
      'Buloqboshi': ['Buloqboshi', 'Chinobod', 'Guliston', 'Navbahor'],
      'Izboskan': ['Izboskan', 'Navbahor', 'Paxtaobod', 'Chinor'],
      'Jalolquduq': ['Jalolquduq', 'Quva', 'Oqtepa', 'Guliston'],
      'Xo\'jaobod': ['Xo\'jaobod shahri', 'Oltinko\'l', 'Paxtaobod', 'Dustlik'],
      'Marhamat': ['Marhamat', 'Navbahor', 'Bulung\'ur', 'Chinobod'],
      'Oltinko\'l': ['Oltinko\'l', 'Qo\'rg\'ontepa', 'Guliston', 'Navbahor'],
      'Paxtaobod': ['Paxtaobod shahri', 'Dustlik', 'Yangiobod', 'Chinor'],
      'Qo\'rg\'ontepa': [
        'Qo\'rg\'ontepa shahri',
        'Vodil',
        'Novkent',
        'Paxtakor',
      ],
      'Shahrixon': ['Shahrixon', 'Oqtepa', 'Beshko\'prik', 'Guliston'],
      'Ulug\'nor': ['Ulug\'nor', 'Navbahor', 'Chinobod', 'Paxtakor'],
    },
    'Buxoro': {
      'Buxoro shahri': ['Markaz', 'Kogon', 'Eski shahar', 'Yangi shahar'],
      'Buxoro tumani': ['Gazli', 'Romitan', 'Vobkent', 'Shofirkon'],
      'Olot': ['Olot', 'Navbahor', 'Guliston', 'Paxtakor'],
      'G\'ijduvon': ['G\'ijduvon', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Jondor': ['Jondor', 'Qorako\'l', 'Navbahor', 'Chinor'],
      'Kogon': ['Kogon shahri', 'Vobkent', 'Romitan', 'Shofirkon'],
      'Peshku': ['Peshku', 'Yangibozor', 'Guliston', 'Navbahor'],
      'Qorako\'l': ['Qorako\'l', 'Jondor', 'Yangiobod', 'Chinobod'],
      'Qorovulbozor': ['Qorovulbozor', 'Navbahor', 'Paxtakor', 'Dustlik'],
      'Romitan': ['Romitan', 'Kogon', 'Vobkent', 'Yangibozor'],
      'Shofirkon': ['Shofirkon', 'Romitan', 'Kogon', 'Navbahor'],
      'Vobkent': ['Vobkent', 'Kogon', 'Romitan', 'Guliston'],
    },
    'Farg\'ona': {
      'Farg\'ona shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Farg\'ona tumani': ['Vodil', 'Yozyovon', 'Qo\'shtepa', 'Rishton'],
      'Beshariq': ['Beshariq', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Bog\'dod': ['Bog\'dod', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Buvayda': ['Buvayda', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Dang\'ara': ['Dang\'ara', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Farg\'ona': ['Vodil', 'Yozyovon', 'Qo\'shtepa', 'Rishton'],
      'Furqat': ['Furqat', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Marg\'ilon': [
        'Marg\'ilon shahri',
        'Ipakchi',
        'Yangi Marg\'ilon',
        'Qo\'qon yo\'li',
      ],
      'Oltiariq': ['Oltiariq', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Quva': ['Quva', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Qo\'qon': ['Qo\'qon shahri', 'Markaz', 'Yangi shahar', 'Minor'],
      'Qo\'shtepa': ['Qo\'shtepa', 'Vodil', 'Yangibozor', 'Navbahor'],
      'Rishton': ['Rishton', 'Chinobod', 'Paxtakor', 'Guliston'],
      'So\'x': ['So\'x', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Toshloq': ['Toshloq', 'Guliston', 'Paxtakor', 'Dustlik'],
      'O\'zbekiston': ['O\'zbekiston', 'Navbahor', 'Chinobod', 'Yangibozor'],
      'Yozyovon': ['Yozyovon', 'Vodil', 'Qo\'shtepa', 'Navbahor'],
    },
    'Jizzax': {
      'Jizzax shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Arnasoy': ['Arnasoy', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Baxmal': ['Baxmal', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Do\'stlik': ['Do\'stlik', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Forish': ['Forish', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'G\'allaorol': ['G\'allaorol', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Mirzacho\'l': ['Mirzacho\'l', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Paxtakor': ['Paxtakor', 'Guliston', 'Navbahor', 'Dustlik'],
      'Yangiobod': ['Yangiobod', 'Chinobod', 'Paxtakor', 'Yangibozor'],
      'Zafarobod': ['Zafarobod', 'Navbahor', 'Guliston', 'Dustlik'],
      'Zomin': ['Zomin', 'Yangibozor', 'Chinobod', 'Paxtakor'],
      'Zarbdor': ['Zarbdor', 'Navbahor', 'Guliston', 'Yangibozor'],
    },
    'Xorazm': {
      'Urganch shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Bog\'ot': ['Bog\'ot', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Gurlan': ['Gurlan', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Xonqa': ['Xonqa', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Xazorasp': ['Xazorasp', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Xiva': ['Xiva shahri', 'Ichon qal\'a', 'Dishan qal\'a', 'Yangi shahar'],
      'Qo\'shko\'pir': ['Qo\'shko\'pir', 'Navbahor', 'Paxtakor', 'Guliston'],
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
      'To\'raqo\'rg\'on': [
        'To\'raqo\'rg\'on',
        'Navbahor',
        'Yangibozor',
        'Dustlik',
      ],
      'Uchqo\'rg\'on': ['Uchqo\'rg\'on', 'Guliston', 'Paxtakor', 'Chinobod'],
      'Uychi': ['Uychi', 'Navbahor', 'Yangibozor', 'Paxtakor'],
      'Yangiqo\'rg\'on': ['Yangiqo\'rg\'on', 'Chinobod', 'Guliston', 'Dustlik'],
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
      'G\'uzor': ['G\'uzor', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Kasbi': ['Kasbi', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Kitob': ['Kitob', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Koson': ['Koson', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Mirishkor': ['Mirishkor', 'Guliston', 'Paxtakor', 'Navbahor'],
      'Muborak': ['Muborak', 'Chinobod', 'Yangibozor', 'Dustlik'],
      'Nishon': ['Nishon', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Qarshi': ['Qarshi tumani', 'Vodil', 'Chinobod', 'Yangibozor'],
      'Qamashi': ['Qamashi', 'Guliston', 'Navbahor', 'Paxtakor'],
      'Shahrisabz': ['Shahrisabz shahri', 'Markaz', 'Yangi shahar', 'Minor'],
      'Yakkabog\'': ['Yakkabog\'', 'Navbahor', 'Chinobod', 'Guliston'],
    },
    'Qoraqalpog\'iston Respublikasi': {
      'Nukus shahri': ['Markaz', 'Yangi shahar', 'Eski shahar', 'Minor'],
      'Amudaryo': ['Amudaryo', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Beruniy': ['Beruniy', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Kegeyli': ['Kegeyli', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Qonliko\'l': ['Qonliko\'l', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Qorao\'zak': ['Qorao\'zak', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Mo\'ynoq': ['Mo\'ynoq', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Nukus': ['Nukus tumani', 'Guliston', 'Paxtakor', 'Navbahor'],
      'Taxtako\'pir': ['Taxtako\'pir', 'Chinobod', 'Yangibozor', 'Dustlik'],
      'To\'rtko\'l': ['To\'rtko\'l', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Xo\'jayli': ['Xo\'jayli', 'Guliston', 'Chinobod', 'Yangibozor'],
      'Chimboy': ['Chimboy', 'Navbahor', 'Paxtakor', 'Dustlik'],
      'Shumanay': ['Shumanay', 'Chinobod', 'Guliston', 'Navbahor'],
      'Ellikqal\'a': ['Ellikqal\'a', 'Paxtakor', 'Yangibozor', 'Dustlik'],
    },
    'Samarqand': {
      'Samarqand shahri': ['Markaz', 'Registon', 'Yangi shahar', 'Minor'],
      'Bulung\'ur': ['Bulung\'ur', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Jomboy': ['Jomboy', 'Yangibozor', 'Chinobod', 'Dustlik'],
      'Ishtixon': ['Ishtixon', 'Navbahor', 'Guliston', 'Paxtakor'],
      'Kattaqo\'rg\'on': [
        'Kattaqo\'rg\'on shahri',
        'Markaz',
        'Yangibozor',
        'Minor',
      ],
      'Narpay': ['Narpay', 'Chinobod', 'Paxtakor', 'Guliston'],
      'Nurobod': ['Nurobod', 'Navbahor', 'Yangibozor', 'Dustlik'],
      'Oqdaryo': ['Oqdaryo', 'Guliston', 'Chinobod', 'Paxtakor'],
      'Paxtachi': ['Paxtachi', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Payariq': ['Payariq', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Pastdarg\'om': ['Pastdarg\'om', 'Navbahor', 'Chinobod', 'Yangibozor'],
      'Qo\'shrabot': ['Qo\'shrabot', 'Guliston', 'Paxtakor', 'Navbahor'],
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
      'Jarqo\'rg\'on': ['Jarqo\'rg\'on', 'Yangibozor', 'Chinobod', 'Navbahor'],
      'Qiziriq': ['Qiziriq', 'Paxtakor', 'Guliston', 'Dustlik'],
      'Qumqo\'rg\'on': ['Qumqo\'rg\'on', 'Navbahor', 'Yangibozor', 'Chinobod'],
      'Muzrabot': ['Muzrabot', 'Guliston', 'Paxtakor', 'Navbahor'],
      'Oltinsoy': ['Oltinsoy', 'Chinobod', 'Yangibozor', 'Dustlik'],
      'Sariosiyo': ['Sariosiyo', 'Navbahor', 'Paxtakor', 'Guliston'],
      'Sherobod': ['Sherobod', 'Guliston', 'Chinobod', 'Yangibozor'],
      'Sho\'rchi': ['Sho\'rchi', 'Paxtakor', 'Navbahor', 'Dustlik'],
      'Termiz': ['Termiz tumani', 'Vodil', 'Yangibozor', 'Chinobod'],
      'Uzun': ['Uzun', 'Navbahor', 'Guliston', 'Paxtakor'],
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

  Future<void> submitPost() async {
    // ✅ AVVAL FOYDALANUVCHINI TEKSHIRISH
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      Get.snackbar(
        'Xatolik',
        'Iltimos, avval tizimga kiring!',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      );
      // Tizimga kirish sahifasiga yo'naltirish
      Get.offAllNamed('/login'); // yoki sizning login route'ingiz
      return;
    }

    // TELEFON RAQAMNI VALIDATSIYA VA FORMATLASH
    String? phoneNumber;
    final rawPhone = phoneNumberController.text.trim();
    if (rawPhone.isNotEmpty) {
      final digitsOnly = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length == 9) {
        phoneNumber = '+998$digitsOnly';
        await _savePhoneNumber(phoneNumber);
      } else {
        Get.snackbar(
          'error'.tr,
          'Telefon raqam noto\'g\'ri formatda. 9 ta raqam kiriting.',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red.shade900,
        );
        return;
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
      // ✅ userId allaqachon tekshirilgan

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

      final firstSubCatId = selectedSubCategories.isNotEmpty
          ? selectedSubCategories.first
          : null;

      final postResponse = await supabase.from('posts').insert({
        'user_id': userId,
        'post_type': formData['postType'],
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category_id': formData['categoryId'],
        'sub_category_id': firstSubCatId,
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

        if (selectedSubCategories.length > 1) {
          for (int i = 1; i < selectedSubCategories.length; i++) {
            await supabase.from('posts').insert({
              'user_id': userId,
              'post_type': formData['postType'],
              'title': titleController.text.trim(),
              'description': descriptionController.text.trim(),
              'category_id': formData['categoryId'],
              'sub_category_id': selectedSubCategories[i],
              'location': fullLocation,
              'salary_type': formData['salaryType'],
              'salary_min': salaryMin,
              'salary_max': salaryMax,
              'requirements_main':
                  requirementsMainController.text.trim().isEmpty
                  ? null
                  : requirementsMainController.text.trim(),
              'requirements_basic':
                  requirementsBasicController.text.trim().isEmpty
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
            });
          }
        }

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

      // ✅ XATOLIKNI ANIQROQ KO'RSATISH
      String errorMessage = e.toString();
      if (errorMessage.contains('foreign key')) {
        errorMessage = 'Tizimda xatolik. Iltimos, qaytadan tizimga kiring.';
        Get.offAllNamed('/login');
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
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

// ==================== VIEW ====================
class CreatePostScreen extends GetView<CreatePostController> {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(CreatePostController());
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'create_post'.tr,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
            return _Step0PostType(controller: controller);
          case 1:
            return _Step1BasicInfo(controller: controller);
          case 2:
            return _Step2Location(controller: controller);
          case 3:
            return _Step3Details(controller: controller);
          case 4:
            return _Step4ImagesAndPhone(controller: controller);
          default:
            return const SizedBox();
        }
      }),
    );
  }
}

// ==================== STEP 0 ====================
class _Step0PostType extends StatelessWidget {
  final CreatePostController controller;
  const _Step0PostType({required this.controller});

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
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.work_outline,
                    size: 64,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'select_post_type'.tr,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'what_is_your_purpose'.tr,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Obx(
                  () => _PostTypeCard(
                    icon: Icons.person_add_alt_1,
                    title: 'employee_needed'.tr,
                    subtitle: 'looking_for_permanent_employee'.tr,
                    value: 'employee_needed',
                    isSelected: controller.postType.value == 'employee_needed',
                    color: Colors.blue,
                    onTap: () => controller.setPostType('employee_needed'),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => _PostTypeCard(
                    icon: Icons.work_outline,
                    title: 'job_needed'.tr,
                    subtitle: 'looking_for_job_myself'.tr,
                    value: 'job_needed',
                    isSelected: controller.postType.value == 'job_needed',
                    color: Colors.green,
                    onTap: () => controller.setPostType('job_needed'),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => _PostTypeCard(
                    icon: Icons.handyman_outlined,
                    title: 'one_time_job'.tr,
                    subtitle: 'short_term_project_specialist'.tr,
                    value: 'one_time_job',
                    isSelected: controller.postType.value == 'one_time_job',
                    color: Colors.orange,
                    onTap: () => controller.setPostType('one_time_job'),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => _PostTypeCard(
                    icon: Icons.room_service_outlined,
                    title: 'service_offering'.tr,
                    subtitle: 'looking_to_provide_service'.tr,
                    value: 'service_offering',
                    isSelected: controller.postType.value == 'service_offering',
                    color: Colors.purple,
                    onTap: () => controller.setPostType('service_offering'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostTypeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, value;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PostTypeCard({
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
          _StepIndicator(current: 1, total: 4),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.info_outline,
            title: 'basic_info'.tr,
            subtitle: 'enter_general_information'.tr,
          ),
          const SizedBox(height: 24),
          _ModernTextField(
            controller: controller.titleController,
            label: 'title'.tr,
            hint: 'title_hint'.tr,
            icon: Icons.title,
            onChanged: (value) => controller.formData['title'] = value,
          ),
          const SizedBox(height: 20),
          _ModernTextField(
            controller: controller.descriptionController,
            label: 'description'.tr,
            hint: 'description_hint'.tr,
            icon: Icons.description,
            maxLines: 5,
            onChanged: (value) => controller.formData['description'] = value,
          ),
          const SizedBox(height: 24),
          _CategorySelectorButton(controller: controller),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.formData['categoryId'] != null &&
                controller.subCategories.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SubCategorySelectorButton(controller: controller),
                  const SizedBox(height: 20),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'next'.tr,
            onPressed: () {
              if (controller.validateStep1()) controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}

// ==================== CATEGORY SELECTOR BUTTON ====================
class _CategorySelectorButton extends StatelessWidget {
  final CreatePostController controller;
  const _CategorySelectorButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedCategoryName =
          controller.formData['categoryName'] as String;
      return GestureDetector(
        onTap: () => _showCategoryBottomSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedCategoryName.isEmpty
                  ? Colors.grey[300]!
                  : Colors.blue,
              width: selectedCategoryName.isEmpty ? 1 : 2,
            ),
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
              Icon(
                Icons.category,
                color: selectedCategoryName.isEmpty
                    ? Colors.grey[600]
                    : Colors.blue,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'category'.tr + ' *',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCategoryName.isEmpty
                          ? 'select_category'.tr
                          : selectedCategoryName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedCategoryName.isEmpty
                            ? Colors.grey[400]
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      );
    });
  }

  void _showCategoryBottomSheet(BuildContext context) {
    final searchController = TextEditingController();
    // ❌ BU QATOR NOTO'G'RI:
    // final filteredCategories = controller.categories.obs;

    // ✅ TO'G'RI:
    final filteredCategories = <Map<String, dynamic>>[].obs;
    filteredCategories.value = controller.categories.toList();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'select_category'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'search_category'.tr,
                      prefixIcon: const Icon(Icons.search),
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
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      // ✅ QIDIRUV FUNKSIYASI
                      if (value.isEmpty) {
                        filteredCategories.value = controller.categories
                            .toList();
                      } else {
                        filteredCategories.value = controller.categories
                            .where(
                              (category) => category['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(value.toLowerCase()),
                            )
                            .toList();
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCategories.length, // ✅ TO'G'RI
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index]; // ✅ TO'G'RI
                    final isSelected =
                        controller.formData['categoryId'] == category['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () async {
                          controller.formData['categoryId'] = category['id'];
                          controller.formData['categoryName'] =
                              category['name'];
                          controller.subCategories.clear();
                          controller.selectedSubCategories.clear();
                          await controller.loadSubCategories(category['id']);
                          controller.formData.refresh();
                          Get.back();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.category,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category['name'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }
}

// ==================== SUB-CATEGORY SELECTOR BUTTON ====================
class _SubCategorySelectorButton extends StatelessWidget {
  final CreatePostController controller;
  const _SubCategorySelectorButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedCount = controller.selectedSubCategories.length;
      return GestureDetector(
        onTap: () => _showSubCategoryBottomSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedCount == 0 ? Colors.grey[300]! : Colors.blue,
              width: selectedCount == 0 ? 1 : 2,
            ),
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
              Icon(
                Icons.subdirectory_arrow_right,
                color: selectedCount == 0 ? Colors.grey[600] : Colors.blue,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'subcategory'.tr + ' *',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCount == 0
                          ? 'select_subcategories'.tr
                          : '$selectedCount ${'selected'.tr}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedCount == 0
                            ? Colors.grey[400]
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$selectedCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      );
    });
  }

  void _showSubCategoryBottomSheet(BuildContext context) {
    final searchController = TextEditingController();
    // ✅ TO'G'RI:
    final filteredSubCategories = <Map<String, dynamic>>[].obs;
    filteredSubCategories.value = controller.subCategories.toList();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'select_subcategories'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('done'.tr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'search_subcategory'.tr,
                      prefixIcon: const Icon(Icons.search),
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
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        filteredSubCategories.value = controller.subCategories
                            .toList();
                      } else {
                        filteredSubCategories.value = controller.subCategories
                            .where(
                              (subCat) => subCat['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(value.toLowerCase()),
                            )
                            .toList();
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSubCategories.length,
                  itemBuilder: (context, index) {
                    final subCategory = filteredSubCategories[index];
                    final isSelected = controller.selectedSubCategories
                        .contains(subCategory['id']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          controller.toggleSubCategory(subCategory['id']);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  subCategory['name'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }
}

// ==================== STEP 2: LOCATION (unchanged) ====================
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
          _StepIndicator(current: 2, total: 4),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.location_on_outlined,
            title: 'location'.tr,
            subtitle: 'specify_job_location'.tr,
          ),
          const SizedBox(height: 24),
          Obx(() {
            final regionList = controller.regions['Uzbekiston'] ?? [];
            final currentRegion = controller.formData['region'] as String?;
            return _ModernDropdown(
              label: '${'region'.tr} *',
              value: (currentRegion?.isEmpty ?? true) ? null : currentRegion,
              hint: 'select_region'.tr,
              icon: Icons.location_city,
              items: regionList,
              onChanged: (value) {
                controller.formData['region'] = value ?? '';
                controller.formData['district'] = '';
                controller.formData['village'] = '';
                controller.formData.refresh();
              },
            );
          }),
          const SizedBox(height: 20),
          Obx(() {
            final currentRegion = controller.formData['region'] as String?;
            final currentDistrict = controller.formData['district'] as String?;
            final districtMap = (currentRegion?.isNotEmpty ?? false)
                ? controller.districts[currentRegion] ?? {}
                : <String, List<String>>{};
            final districtList = districtMap.keys.toList();
            if (districtList.isEmpty) return const SizedBox.shrink();
            return _ModernDropdown(
              label: '${'district'.tr} *',
              value: (currentDistrict?.isEmpty ?? true)
                  ? null
                  : currentDistrict,
              hint: 'select_district'.tr,
              icon: Icons.place,
              items: districtList,
              onChanged: (value) {
                controller.formData['district'] = value ?? '';
                controller.formData['village'] = '';
                controller.formData.refresh();
              },
            );
          }),
          const SizedBox(height: 20),
          Obx(() {
            final currentRegion = controller.formData['region'] as String?;
            final currentDistrict = controller.formData['district'] as String?;
            final currentVillage = controller.formData['village'] as String?;
            final districtMap = (currentRegion?.isNotEmpty ?? false)
                ? controller.districts[currentRegion] ?? {}
                : <String, List<String>>{};
            final villageList = (currentDistrict?.isNotEmpty ?? false)
                ? districtMap[currentDistrict] ?? []
                : <String>[];
            if (villageList.isEmpty) return const SizedBox.shrink();
            return _ModernDropdown(
              label: 'village_optional'.tr,
              value: (currentVillage?.isEmpty ?? true) ? null : currentVillage,
              hint: 'select_village'.tr,
              icon: Icons.home_outlined,
              items: villageList,
              onChanged: (value) {
                controller.formData['village'] = value ?? '';
                controller.formData.refresh();
              },
            );
          }),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'next'.tr,
            onPressed: () {
              if (controller.validateStep2()) controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 3: DETAILS ====================
class _Step3Details extends StatelessWidget {
  final CreatePostController controller;
  const _Step3Details({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final postType = controller.postType.value;
      if (postType == 'employee_needed') {
        return _EmployeeNeededForm(controller: controller);
      } else if (postType == 'job_needed') {
        return _JobNeededForm(controller: controller);
      } else if (postType == 'one_time_job') {
        return _OneTimeJobForm(controller: controller);
      } else if (postType == 'service_offering') {
        return _ServiceOfferingForm(controller: controller);
      }
      return const SizedBox();
    });
  }
}

// Forms remain the same as in document 3...
// (Employee, Job, OneTime, Service forms - copying from document 3)

class _EmployeeNeededForm extends StatelessWidget {
  final CreatePostController controller;
  const _EmployeeNeededForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 3, total: 4),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.work_history_outlined,
            title: 'job_details'.tr,
            subtitle: 'employee_needed_details'.tr,
          ),
          const SizedBox(height: 24),
          _Label('${'salary_type'.tr} *', Icons.account_balance_wallet),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SalaryTypeChip(
                  label: 'daily'.tr,
                  value: 'daily',
                  isSelected: controller.formData['salaryType'] == 'daily',
                  onTap: () {
                    controller.formData['salaryType'] = 'daily';
                    controller.formData.refresh();
                  },
                ),
                _SalaryTypeChip(
                  label: 'monthly'.tr,
                  value: 'monthly',
                  isSelected: controller.formData['salaryType'] == 'monthly',
                  onTap: () {
                    controller.formData['salaryType'] = 'monthly';
                    controller.formData.refresh();
                  },
                ),
                _SalaryTypeChip(
                  label: 'freelance'.tr,
                  value: 'freelance',
                  isSelected: controller.formData['salaryType'] == 'freelance',
                  onTap: () {
                    controller.formData['salaryType'] = 'freelance';
                    controller.formData.refresh();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ModernTextField(
                  controller: controller.salaryMinController,
                  label: 'salary_min'.tr,
                  hint: '1 000 000',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffix: 'UZS',
                  onChanged: (value) {
                    controller.formData['salaryMin'] =
                        int.tryParse(value.replaceAll(RegExp(r'\s'), '')) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernTextField(
                  controller: controller.salaryMaxController,
                  label: 'salary_max'.tr,
                  hint: '3 000 000',
                  icon: Icons.trending_up,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffix: 'UZS',
                  onChanged: (value) {
                    controller.formData['salaryMax'] =
                        int.tryParse(value.replaceAll(RegExp(r'\s'), '')) ?? 0;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.formData['salaryType'] == 'freelance') {
              return Column(
                children: [
                  _ModernTextField(
                    controller: controller.durationDaysController,
                    label: '${'duration_days'.tr} *',
                    hint: '30',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      controller.formData['durationDays'] = int.tryParse(value);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          _ModernTextField(
            controller: controller.requirementsMainController,
            label: '${'main_requirements'.tr} *',
            hint: 'main_requirements_hint'.tr,
            icon: Icons.checklist,
            maxLines: 4,
            onChanged: (value) =>
                controller.formData['requirementsMain'] = value,
          ),
          const SizedBox(height: 20),
          _ModernTextField(
            controller: controller.requirementsBasicController,
            label: 'additional_requirements_optional'.tr,
            hint: 'additional_requirements_hint'.tr,
            icon: Icons.add_circle_outline,
            maxLines: 3,
            onChanged: (value) =>
                controller.formData['requirementsBasic'] = value,
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'next'.tr,
            onPressed: () {
              if (controller.validateStep3()) controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}

class _JobNeededForm extends StatelessWidget {
  final CreatePostController controller;
  const _JobNeededForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 3, total: 4),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.person_search_outlined,
            title: 'your_profile'.tr,
            subtitle: 'job_needed_details'.tr,
          ),
          const SizedBox(height: 24),
          _ModernTextField(
            controller: controller.skillsController,
            label: '${'skills'.tr} *',
            hint: 'skills_hint'.tr,
            icon: Icons.star_outline,
            maxLines: 4,
            onChanged: (value) => controller.formData['skills'] = value,
          ),
          const SizedBox(height: 20),
          _ModernTextField(
            controller: controller.experienceController,
            label: '${'experience'.tr} *',
            hint: 'experience_hint'.tr,
            icon: Icons.work_history_outlined,
            maxLines: 4,
            onChanged: (value) => controller.formData['experience'] = value,
          ),
          const SizedBox(height: 24),
          _Label('expected_salary'.tr, Icons.account_balance_wallet),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModernTextField(
                  controller: controller.salaryMinController,
                  label: 'salary_min'.tr,
                  hint: '1 000 000',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffix: 'UZS',
                  onChanged: (value) {
                    controller.formData['salaryMin'] =
                        int.tryParse(value.replaceAll(RegExp(r'\s'), '')) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernTextField(
                  controller: controller.salaryMaxController,
                  label: 'salary_max'.tr,
                  hint: '3 000 000',
                  icon: Icons.trending_up,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffix: 'UZS',
                  onChanged: (value) {
                    controller.formData['salaryMax'] =
                        int.tryParse(value.replaceAll(RegExp(r'\s'), '')) ?? 0;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'next'.tr,
            onPressed: () {
              if (controller.validateStep3()) controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}

class _OneTimeJobForm extends StatelessWidget {
  final CreatePostController controller;
  const _OneTimeJobForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 3, total: 4),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.build_circle_outlined,
            title: 'project_details'.tr,
            subtitle: 'one_time_job_details'.tr,
          ),
          const SizedBox(height: 24),
          _ModernTextField(
            controller: controller.durationDaysController,
            label: '${'duration_days'.tr} *',
            hint: '30',
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              controller.formData['durationDays'] = int.tryParse(value);
            },
          ),
          const SizedBox(height: 20),
          _Label('project_budget'.tr, Icons.account_balance_wallet),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModernTextField(
                  controller: controller.salaryMinController,
                  label: 'budget_min'.tr,
                  hint: '1 000 000',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffix: 'UZS',
                  onChanged: (value) {
                    controller.formData['salaryMin'] =
                        int.tryParse(value.replaceAll(RegExp(r'\s'), '')) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernTextField(
                  controller: controller.salaryMaxController,
                  label: 'budget_max'.tr,
                  hint: '5 000 000',
                  icon: Icons.trending_up,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffix: 'UZS',
                  onChanged: (value) {
                    controller.formData['salaryMax'] =
                        int.tryParse(value.replaceAll(RegExp(r'\s'), '')) ?? 0;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ModernTextField(
            controller: controller.requirementsMainController,
            label: 'project_requirements'.tr,
            hint: 'project_requirements_hint'.tr,
            icon: Icons.assignment_outlined,
            maxLines: 5,
            onChanged: (value) =>
                controller.formData['requirementsMain'] = value,
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'next'.tr,
            onPressed: () {
              if (controller.validateStep3()) controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceOfferingForm extends StatelessWidget {
  final CreatePostController controller;
  const _ServiceOfferingForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 3, total: 4),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.handshake_outlined,
            title: 'service_details'.tr,
            subtitle: 'service_offering_details'.tr,
          ),
          const SizedBox(height: 24),
          _ModernTextField(
            controller: controller.skillsController,
            label: '${'skills'.tr} *',
            hint: 'skills_hint'.tr,
            icon: Icons.star_outline,
            maxLines: 4,
            onChanged: (value) => controller.formData['skills'] = value,
          ),
          const SizedBox(height: 20),
          _ModernTextField(
            controller: controller.experienceController,
            label: '${'experience'.tr} *',
            hint: 'experience_hint'.tr,
            icon: Icons.verified_outlined,
            maxLines: 4,
            onChanged: (value) => controller.formData['experience'] = value,
          ),
          const SizedBox(height: 24),
          _Label('expected_salary'.tr, Icons.account_balance_wallet),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModernTextField(
                  controller: controller.salaryMinController,
                  label: 'salary_min'.tr,
                  hint: '1 000 000',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffix: 'UZS',
                  onChanged: (value) {
                    controller.formData['salaryMin'] =
                        int.tryParse(value.replaceAll(RegExp(r'\s'), '')) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernTextField(
                  controller: controller.salaryMaxController,
                  label: 'salary_max'.tr,
                  hint: '3 000 000',
                  icon: Icons.trending_up,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffix: 'UZS',
                  onChanged: (value) {
                    controller.formData['salaryMax'] =
                        int.tryParse(value.replaceAll(RegExp(r'\s'), '')) ?? 0;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'next'.tr,
            onPressed: () {
              if (controller.validateStep3()) controller.nextStep();
            },
          ),
        ],
      ),
    );
  }
}

// ==================== STEP 4: IMAGES AND PHONE ====================
class _Step4ImagesAndPhone extends StatelessWidget {
  final CreatePostController controller;
  const _Step4ImagesAndPhone({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 4, total: 4),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.add_photo_alternate_outlined,
            title: 'final_step'.tr,
            subtitle: 'add_images_and_contact'.tr,
          ),
          const SizedBox(height: 24),

          // IMAGES SECTION
          GestureDetector(
            onTap: controller.pickImages,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100.withOpacity(0.3),
                  ],
                ),
                border: Border.all(color: Colors.blue.shade200, width: 2),
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
                    'tap_to_add_image'.tr,
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'max_3_images'.tr,
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${'selected_images'.tr}: ${controller.selectedImages.length}/3',
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

          const SizedBox(height: 32),

          // PHONE NUMBER SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: Colors.green.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bog\'lanish uchun telefon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ixtiyoriy - faqat kerak bo\'lsa qo\'shing',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _PhoneNumberField(controller: controller),

          const SizedBox(height: 40),
          _PrimaryButton(
            text: 'create_post'.tr,
            icon: Icons.send_rounded,
            onPressed: controller.submitPost,
          ),
        ],
      ),
    );
  }
}

// ==================== PHONE NUMBER FIELD ====================
class _PhoneNumberField extends StatelessWidget {
  final CreatePostController controller;
  const _PhoneNumberField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            controller: controller.phoneNumberController,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneNumberFormatter()],
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: '90 123 45 67',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, color: Colors.grey[600], size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '+998',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.only(left: 12),
                    ),
                  ],
                ),
              ),
              suffixIcon: controller.phoneNumberController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => controller.phoneNumberController.clear(),
                    )
                  : (controller.savedPhoneNumbers.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.history, size: 20),
                            onPressed: () => _showSavedNumbers(context),
                          )
                        : null),
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
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        if (controller.savedPhoneNumbers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => _showSavedNumbers(context),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Avval ishlatilgan raqamlar',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showSavedNumbers(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Avval ishlatilgan raqamlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: controller.savedPhoneNumbers.length,
              itemBuilder: (context, index) {
                final phoneNumber = controller.savedPhoneNumbers[index];
                final displayNumber = phoneNumber.replaceAll('+998', '');
                final formattedDisplay = controller._formatPhoneDisplay(
                  displayNumber,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      controller.phoneNumberController.text = formattedDisplay;
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '+998 $formattedDisplay',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }
}

// ==================== REUSABLE WIDGETS ====================
class _StepIndicator extends StatelessWidget {
  final int current, total;
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
  final String title, subtitle;
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
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final String? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String) onChanged;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.suffix,
    this.inputFormatters,
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
            inputFormatters: inputFormatters,
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
  final String label, hint;
  final String? value;
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
                  style: const TextStyle(
                    // ==================== DROPDOWN NING DAVOMI ====================
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
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

// ==================== SALARY TYPE CHIP ====================
class _SalaryTypeChip extends StatelessWidget {
  final String label, value;
  final bool isSelected;
  final VoidCallback onTap;

  const _SalaryTypeChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
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
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ==================== PRIMARY BUTTON ====================
class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: 12),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== STEP 4: IMAGES AND PHONE (TO'LIQ) ====================

// ==================== PHONE NUMBER FIELD ====================
