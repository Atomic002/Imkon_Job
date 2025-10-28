// lib/config/routes.dart
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:version1/Screens/auth/login_screen.dart';
import 'package:version1/Screens/auth/otp_screen.dart';
import 'package:version1/Screens/auth/register_screen.dart';
import 'package:version1/Screens/home/all_user_screen.dart';
import 'package:version1/Screens/home/chat_screen.dart';
import 'package:version1/Screens/home/home_screen.dart';
import 'package:version1/Screens/home/notification_screen.dart';
import 'package:version1/Screens/home/create_post_screen.dart';
import 'package:version1/Screens/home/profile_screen.dart';
import 'package:version1/Screens/home/search_screen.dart';

import 'package:version1/Screens/home/user_profile_screen.dart';
import 'package:version1/Screens/onboarding/onboarding_screen.dart';
import 'package:version1/Screens/splash/splash_screen.dart';
import 'package:version1/detail/chat_detail.dart';

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
  static const String createPost = '/create_post';
  static const String notifications = '/notifications';

  // ✅ YANGI ROUTELAR
  static const String allUsers = '/all_users';
  static const String chatDetail = '/chat_detail';
  static const String otherProfile = '/other_profile';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: otp, page: () => const OTPScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: search, page: () => const SearchScreen()),
    GetPage(name: chat, page: () => const ChatScreen()),
    GetPage(name: profile, page: () => const ProfileScreen()),
    GetPage(name: createPost, page: () => const CreatePostScreen()),
    GetPage(name: notifications, page: () => const NotificationsScreen()),

    // ✅ YANGI PAGES
    GetPage(name: allUsers, page: () => const AllUsersScreen()),
    GetPage(name: chatDetail, page: () => const ChatDetailScreen()),
    GetPage(
      name: otherProfile,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return OtherUserProfilePage(userId: args['userId']);
      },
    ),
  ];
}
