import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:version1/Screens/auth/login_screen.dart';
import 'package:version1/Screens/auth/otp_screen.dart';
import 'package:version1/Screens/auth/register_screen.dart';
import 'package:version1/Screens/home/chat_screen.dart';
import 'package:version1/Screens/home/home_screen.dart';
import 'package:version1/Screens/home/notification_screen.dart';
import 'package:version1/Screens/home/create_post_screen.dart';
import 'package:version1/Screens/home/profile_screen.dart';
import 'package:version1/Screens/home/search_screen.dart';
import 'package:version1/Screens/language/language_screen.dart';
import 'package:version1/Screens/onboarding/onboarding_screen.dart';
import 'package:version1/Screens/splash/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String language = '/language';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String search = '/search';
  static const String chat = '/chat';
  static const String profile = '/profile';

  // ✅ QO'SHISH KERAK BO'LGAN ROUTES:
  static const String createPost = '/create_post';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: language, page: () => const LanguageScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: otp, page: () => const OTPScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: search, page: () => const SearchScreen()),
    GetPage(name: chat, page: () => const ChatScreen()),
    GetPage(name: profile, page: () => const ProfileScreen()),

    // ✅ QO'SHISH KERAK BO'LGAN PAGES:
    GetPage(name: createPost, page: () => const CreatePostScreen()),

    GetPage(name: '/notifications', page: () => const NotificationsScreen()),
  ];
}
