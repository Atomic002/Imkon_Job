import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'uz_UZ': {
      // App
      'app_name': 'Job Hunter',
      'welcome': 'Xush kelibsiz!',

      // Onboarding
      'onboarding_title_1': 'Ish topish oson!',
      'onboarding_desc_1':
          'Minglab ish e\'lonlari orasidan o\'zingizga mos bo\'lgan ishni toping. Ko\'chalarda sarson bo\'lishga hojat yo\'q!',
      'onboarding_title_2': 'To\'g\'ridan-to\'g\'ri muloqot',
      'onboarding_desc_2':
          'Ish beruvchilar bilan chat orqali bevosita gaplashing. Tez va qulay!',
      'onboarding_title_3': 'Bepul va ishonchli',
      'onboarding_desc_3':
          'Barcha xizmatlar mutlaqo bepul! Xavfsiz va ishonchli platformada ish toping!',
      'skip': 'O\'tkazib yuborish',
      'next': 'Keyingisi',
      'get_started': 'Boshlash',

      // Language
      'select_language': 'Tilni tanlang',

      // Auth
      'login': 'Kirish',
      'register': 'Ro\'yxatdan o\'tish',
      'logout': 'Chiqish',
      'username': 'Username',
      'password': 'Parol',
      'forgot_password': 'Parolni unutdingizmi?',
      'dont_have_account': 'Akkauntingiz yo\'qmi?',
      'already_have_account': 'Akkauntingiz bormi?',
      'login_now': 'Kirish',
      'register_now': 'Ro\'yxatdan o\'ting',

      // Register Steps
      'step': 'Bosqich',
      'personal_info': 'Shaxsiy ma\'lumotlar',
      'personal_info_desc': 'Ism va familyangizni kiriting',
      'contact_info': 'Aloqa ma\'lumotlari',
      'contact_info_desc': 'Telefon raqam va emailingiz',
      'account_info': 'Akkount yaratish',
      'account_info_desc': 'Username va parol o\'ylab toping',
      'account_type': 'Akkount turi',
      'account_type_desc': 'Siz kim sifatida ro\'yxatdan o\'tyapsiz?',

      // Form Fields
      'first_name': 'Ism',
      'last_name': 'Familya',
      'phone': 'Telefon raqam',
      'email': 'Email',
      'bio': 'Bio (ixtiyoriy)',
      'enter_first_name': 'Ismingiz',
      'enter_last_name': 'Familyangiz',
      'enter_phone': '+998 90 123 45 67',
      'enter_email': 'example@mail.com',
      'enter_username': 'Noyob username tanlang',
      'enter_password': 'Kuchli parol kiriting',
      'enter_bio': 'O\'zingiz haqingizda qisqacha',

      // Account Types
      'individual': 'Shaxs',
      'individual_desc': 'Ish qidiruvchi yoki freelancer',
      'company': 'Kompaniya',
      'company_desc': 'Xodim qidiruvchi tashkilot',

      // Buttons
      'back': 'Orqaga',
      'continue': 'Davom etish',
      'confirm': 'Tasdiqlash',
      'save': 'Saqlash',
      'cancel': 'Bekor qilish',
      'submit': 'Yuborish',

      // OTP
      'phone_verification': 'Telefon tasdiqlash',
      'otp_desc': 'Telefon raqamingizga yuborilgan\n6 raqamli kodni kiriting',
      'code_not_received': 'Kod kelmadimi?',
      'resend_code': 'Qayta yuborish',
      'verify': 'Tasdiqlash',

      // Home
      'home': 'Bosh',
      'search': 'Qidiruv',
      'add_post': 'Post qo\'shish',
      'messages': 'Chat',
      'profile': 'Profil',
      'all_categories': 'Barchasi',
      'it': 'IT',
      'construction': 'Qurilish',
      'education': 'Ta\'lim',
      'service': 'Xizmat',
      'transport': 'Transport',

      // Post
      'views': 'Ko\'rishlar',
      'likes': 'Yoqtirishlar',
      'share': 'Ulashish',
      'chat_button': 'Chat',
      'apply': 'Ariza yuborish',

      // Messages
      'success': 'Muvaffaqiyatli!',
      'error': 'Xatolik!',
      'account_created': 'Akkauntingiz yaratildi',
      'code_sent': 'Telefon raqamingizga yangi kod yuborildi',
    },
    'uz_UZ_CYRILLIC': {
      // App
      'app_name': 'Job Hunter',
      'welcome': 'Хуш келибсиз!',

      // Onboarding
      'onboarding_title_1': 'Иш топиш осон!',
      'onboarding_desc_1':
          'Минглаб иш эълонлари орасидан ўзингизга мос бўлган ишни топинг. Кўчаларда арсон бўлишга ҳожат йўқ!',
      'onboarding_title_2': 'Тўғридан-тўғри мулоқот',
      'onboarding_desc_2':
          'Иш берувчилар билан chat орқали бевосита гаплашинг. Тез ва қулай!',
      'onboarding_title_3': 'Бепул ва ишончли',
      'onboarding_desc_3':
          'Барча хизматлар мутлақо бепул! Хавфсиз ва ишончли платформада иш топинг!',
      'skip': 'Ўтказиб юбориш',
      'next': 'Кейингиси',
      'get_started': 'Бошлаш',

      // Language
      'select_language': 'Тилни танланг',

      // Auth
      'login': 'Кириш',
      'register': 'Рўйхатдан ўтиш',
      'logout': 'Чиқиш',
      'username': 'Username',
      'password': 'Парол',
      'forgot_password': 'Паролни унутдингизми?',
      'dont_have_account': 'Аккаунтингиз йўқми?',
      'already_have_account': 'Аккаунтингиз борми?',
      'login_now': 'Кириш',
      'register_now': 'Рўйхатдан ўтинг',

      // Register Steps
      'step': 'Босқич',
      'personal_info': 'Шахсий маълумотлар',
      'personal_info_desc': 'Исм ва фамиляңизни киритинг',
      'contact_info': 'Алоқа маълумотлари',
      'contact_info_desc': 'Телефон рақам ва emailингиз',
      'account_info': 'Аккаунт яратиш',
      'account_info_desc': 'Username ва парол ўйлаб топинг',
      'account_type': 'Аккаунт тури',
      'account_type_desc': 'Сиз ким сифатида рўйхатдан ўтяпсиз?',

      // Form Fields
      'first_name': 'Исм',
      'last_name': 'Фамиля',
      'phone': 'Телефон рақам',
      'email': 'Email',
      'bio': 'Bio (ихтиёрий)',
      'enter_first_name': 'Исмингиз',
      'enter_last_name': 'Фамиляңиз',
      'enter_phone': '+998 90 123 45 67',
      'enter_email': 'example@mail.com',
      'enter_username': 'Нойоб username танланг',
      'enter_password': 'Кучли парол киритинг',
      'enter_bio': 'Ўзингиз ҳақингизда қисқача',

      // Account Types
      'individual': 'Шахс',
      'individual_desc': 'Иш қидирувчи ёки freelancer',
      'company': 'Компания',
      'company_desc': 'Ходим қидирувчи ташкилот',

      // Buttons
      'back': 'Орқага',
      'continue': 'Давом етиш',
      'confirm': 'Тасдиқлаш',
      'save': 'Сақлаш',
      'cancel': 'Бекор қилиш',
      'submit': 'Юбориш',

      // OTP
      'phone_verification': 'Телефон тасдиқлаш',
      'otp_desc': 'Телефон рақамингизга юборилган\n6 рақамли кодни киритинг',
      'code_not_received': 'Код келмадими?',
      'resend_code': 'Қайта юбориш',
      'verify': 'Тасдиқлаш',

      // Home
      'home': 'Бош',
      'search': 'Қидирув',
      'add_post': 'Post қўшиш',
      'messages': 'Chat',
      'profile': 'Профил',
      'all_categories': 'Барчаси',
      'it': 'IT',
      'construction': 'Қурилиш',
      'education': 'Таълим',
      'service': 'Хизмат',
      'transport': 'Транспорт',

      // Post
      'views': 'Кўришлар',
      'likes': 'Йоқтиришлар',
      'share': 'Улашиш',
      'chat_button': 'Chat',
      'apply': 'Ариза юбориш',

      // Messages
      'success': 'Муваффақиятли!',
      'error': 'Хатолик!',
      'account_created': 'Аккаунтингиз яратилди',
      'code_sent': 'Телефон рақамингизга янги код юборилди',
    },
    'ru_RU': {
      // App
      'app_name': 'Job Hunter',
      'welcome': 'Добро пожаловать!',

      // Onboarding
      'onboarding_title_1': 'Найти работу легко!',
      'onboarding_desc_1':
          'Найдите подходящую работу среди тысяч вакансий. Не нужно бродить по улицам!',
      'onboarding_title_2': 'Прямое общение',
      'onboarding_desc_2':
          'Общайтесь с работодателями напрямую через чат. Быстро и удобно!',
      'onboarding_title_3': 'Бесплатно и надежно',
      'onboarding_desc_3':
          'Все услуги абсолютно бесплатны! Найдите работу на безопасной и надежной платформе!',
      'skip': 'Пропустить',
      'next': 'Далее',
      'get_started': 'Начать',

      // Language
      'select_language': 'Выберите язык',

      // Auth
      'login': 'Войти',
      'register': 'Регистрация',
      'logout': 'Выйти',
      'username': 'Имя пользователя',
      'password': 'Пароль',
      'forgot_password': 'Забыли пароль?',
      'dont_have_account': 'Нет аккаунта?',
      'already_have_account': 'Есть аккаунт?',
      'login_now': 'Войти',
      'register_now': 'Зарегистрироваться',

      // Register Steps
      'step': 'Шаг',
      'personal_info': 'Личные данные',
      'personal_info_desc': 'Введите имя и фамилию',
      'contact_info': 'Контактные данные',
      'contact_info_desc': 'Телефон и email',
      'account_info': 'Создание аккаунта',
      'account_info_desc': 'Придумайте username и пароль',
      'account_type': 'Тип аккаунта',
      'account_type_desc': 'Кем вы регистрируетесь?',

      // Form Fields
      'first_name': 'Имя',
      'last_name': 'Фамилия',
      'phone': 'Телефон',
      'email': 'Email',
      'bio': 'О себе (необязательно)',
      'enter_first_name': 'Ваше имя',
      'enter_last_name': 'Ваша фамилия',
      'enter_phone': '+998 90 123 45 67',
      'enter_email': 'example@mail.com',
      'enter_username': 'Выберите уникальный username',
      'enter_password': 'Введите надежный пароль',
      'enter_bio': 'Расскажите о себе кратко',

      // Account Types
      'individual': 'Частное лицо',
      'individual_desc': 'Ищу работу или фрилансер',
      'company': 'Компания',
      'company_desc': 'Ищу сотрудников',

      // Buttons
      'back': 'Назад',
      'continue': 'Продолжить',
      'confirm': 'Подтвердить',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'submit': 'Отправить',

      // OTP
      'phone_verification': 'Подтверждение телефона',
      'otp_desc': 'Введите 6-значный код,\nотправленный на ваш номер',
      'code_not_received': 'Не пришел код?',
      'resend_code': 'Отправить заново',
      'verify': 'Подтвердить',

      // Home
      'home': 'Главная',
      'search': 'Поиск',
      'add_post': 'Добавить',
      'messages': 'Чат',
      'profile': 'Профиль',
      'all_categories': 'Все',
      'it': 'IT',
      'construction': 'Строительство',
      'education': 'Образование',
      'service': 'Услуги',
      'transport': 'Транспорт',

      // Post
      'views': 'Просмотры',
      'likes': 'Нравится',
      'share': 'Поделиться',
      'chat_button': 'Чат',
      'apply': 'Откликнуться',

      // Messages
      'success': 'Успешно!',
      'error': 'Ошибка!',
      'account_created': 'Ваш аккаунт создан',
      'code_sent': 'Новый код отправлен на ваш номер',
    },
    'en_US': {
      // App
      'app_name': 'Job Hunter',
      'welcome': 'Welcome!',

      // Onboarding
      'onboarding_title_1': 'Find Jobs Easily!',
      'onboarding_desc_1':
          'Find the perfect job among thousands of listings. No need to wander the streets!',
      'onboarding_title_2': 'Direct Communication',
      'onboarding_desc_2': 'Chat directly with employers. Fast and convenient!',
      'onboarding_title_3': 'Free and Reliable',
      'onboarding_desc_3':
          'All services are completely free! Find jobs on a safe and reliable platform!',
      'skip': 'Skip',
      'next': 'Next',
      'get_started': 'Get Started',

      // Language
      'select_language': 'Select Language',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'username': 'Username',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': 'Don\'t have an account?',
      'already_have_account': 'Already have an account?',
      'login_now': 'Login',
      'register_now': 'Register Now',

      // Register Steps
      'step': 'Step',
      'personal_info': 'Personal Information',
      'personal_info_desc': 'Enter your name and surname',
      'contact_info': 'Contact Information',
      'contact_info_desc': 'Your phone and email',
      'account_info': 'Create Account',
      'account_info_desc': 'Choose username and password',
      'account_type': 'Account Type',
      'account_type_desc': 'Who are you registering as?',

      // Form Fields
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'phone': 'Phone',
      'email': 'Email',
      'bio': 'Bio (optional)',
      'enter_first_name': 'Your first name',
      'enter_last_name': 'Your last name',
      'enter_phone': '+998 90 123 45 67',
      'enter_email': 'example@mail.com',
      'enter_username': 'Choose a unique username',
      'enter_password': 'Enter a strong password',
      'enter_bio': 'Tell us about yourself',

      // Account Types
      'individual': 'Individual',
      'individual_desc': 'Job seeker or freelancer',
      'company': 'Company',
      'company_desc': 'Looking for employees',

      // Buttons
      'back': 'Back',
      'continue': 'Continue',
      'confirm': 'Confirm',
      'save': 'Save',
      'cancel': 'Cancel',
      'submit': 'Submit',

      // OTP
      'phone_verification': 'Phone Verification',
      'otp_desc': 'Enter the 6-digit code\nsent to your phone',
      'code_not_received': 'Didn\'t receive code?',
      'resend_code': 'Resend',
      'verify': 'Verify',

      // Home
      'home': 'Home',
      'search': 'Search',
      'add_post': 'Add Post',
      'messages': 'Chat',
      'profile': 'Profile',
      'all_categories': 'All',
      'it': 'IT',
      'construction': 'Construction',
      'education': 'Education',
      'service': 'Service',
      'transport': 'Transport',

      // Post
      'views': 'Views',
      'likes': 'Likes',
      'share': 'Share',
      'chat_button': 'Chat',
      'apply': 'Apply',

      // Messages
      'success': 'Success!',
      'error': 'Error!',
      'account_created': 'Your account has been created',
      'code_sent': 'New code sent to your phone',
    },
  };
}
