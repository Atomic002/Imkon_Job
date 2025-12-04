import 'package:flutter/widgets.dart';
import 'package:flutter_application_2/Screens/auth/login_screen.dart';
import 'package:flutter_application_2/Screens/auth/otp_screen.dart';
import 'package:flutter_application_2/Screens/auth/register_screen.dart';
import 'package:flutter_application_2/Screens/home/all_user_screen.dart';
import 'package:flutter_application_2/Screens/home/chat_screen.dart';
import 'package:flutter_application_2/Screens/home/create_post_screen.dart';
import 'package:flutter_application_2/Screens/home/filter_screen.dart';
import 'package:flutter_application_2/Screens/home/home_screen.dart';
import 'package:flutter_application_2/Screens/home/map_picker_screen.dart';
import 'package:flutter_application_2/Screens/home/notification_screen.dart';
import 'package:flutter_application_2/Screens/home/profile_screen.dart';
import 'package:flutter_application_2/Screens/home/user_profile_screen.dart';
import 'package:flutter_application_2/Screens/onboarding/onboarding_screen.dart';
import 'package:flutter_application_2/Screens/splash/splash_screen.dart';
import 'package:flutter_application_2/controller/chat_controller.dart';
import 'package:flutter_application_2/controller/home_controller.dart';
import 'package:flutter_application_2/detail/chat_detail.dart';
import 'package:get/get.dart';

/// ✅ App Routes - Barcha route'lar va binding'lar
class AppRoutes {
  // ==================== ROUTE NAMES ====================
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String search = '/search';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String createPost = '/create_post';
  static const String notifications = '/notifications';
  static const String mapPicker = '/map_picker';

  // Additional routes
  static const String allUsers = '/all_users';
  static const String chatDetail = '/chat_detail';
  static const String otherProfile = '/other_profile';

  // ==================== ROUTE PAGES ====================
  static List<GetPage> routes = [
    // ✅ 1. SPLASH SCREEN (Initial route)
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 2. ONBOARDING
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 3. AUTH SCREENS
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: otp,
      page: () => const OTPScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 4. HOME SCREEN (with bindings - MUHIM!)
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: BindingsBuilder(() {
        // ✅ Lazy loading - faqat kerak bo'lganda yuklanadi
        Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
        Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 5. SEARCH/FILTER SCREEN
    GetPage(
      name: search,
      page: () => const FilterScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 6. CHAT SCREEN
    GetPage(
      name: chat,
      page: () => const ChatScreen(),
      binding: BindingsBuilder(() {
        // ✅ Chat controller'ni qayta yuklash (agar yo'q bo'lsa)
        if (!Get.isRegistered<ChatController>()) {
          Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 7. CHAT DETAIL SCREEN
    GetPage(
      name: chatDetail,
      page: () => const ChatDetailScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 8. PROFILE SCREEN
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 9. OTHER USER PROFILE (with arguments)
    GetPage(
      name: otherProfile,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String? ?? '';

        if (userId.isEmpty) {
          // ✅ userId bo'lmasa, profile'ga qaytarish
          Future.microtask(() => Get.offAllNamed(profile));
          return const SizedBox.shrink();
        }

        return OtherUserProfilePage(userId: userId);
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 10. CREATE POST SCREEN
    GetPage(
      name: createPost,
      page: () => const CreatePostScreen(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 400),
    ),

    // ✅ 11. NOTIFICATIONS SCREEN
    GetPage(
      name: notifications,
      page: () => const NotificationsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 12. ALL USERS SCREEN
    GetPage(
      name: allUsers,
      page: () => const AllUsersScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ✅ 13. MAP PICKER SCREEN
    GetPage(
      name: mapPicker,
      page: () => const MapPickerScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];

  // ==================== HELPER METHODS ====================

  /// ✅ Navigation helper - argument bilan
  static Future<T?>? toNamed<T>(
    String routeName, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    return Get.toNamed<T>(
      routeName,
      arguments: arguments,
      parameters: parameters,
    );
  }

  /// ✅ Replace navigation
  static Future<T?>? offNamed<T>(
    String routeName, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    return Get.offNamed<T>(
      routeName,
      arguments: arguments,
      parameters: parameters,
    );
  }

  /// ✅ Replace all navigation (logout scenario)
  static Future<T?>? offAllNamed<T>(
    String routeName, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    return Get.offAllNamed<T>(
      routeName,
      arguments: arguments,
      parameters: parameters,
    );
  }

  /// ✅ Check if route exists
  static bool routeExists(String routeName) {
    return routes.any((route) => route.name == routeName);
  }

  /// ✅ Get current route name
  static String get currentRoute => Get.currentRoute;

  /// ✅ Check if on specific route
  static bool isOnRoute(String routeName) => Get.currentRoute == routeName;
}

/// ✅ ROUTE MIDDLEWARE (Optional - future use)
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // TODO: Add auth check logic here if needed
    return null;
  }
}
