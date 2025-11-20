import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Screens/splash/splash_screen.dart';
import 'package:version1/config/routes.dart';
import 'package:version1/config/themes.dart';
import 'package:version1/translations/app_translations.dart';
import 'package:version1/controller/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  // Supabase init
  await Supabase.initialize(
    url: 'https://lebttvzssavbjkoumebf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlYnR0dnpzc2F2Ymprb3VtZWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0OTQyNzgsImV4cCI6MjA3NjA3MDI3OH0.psRAzz881AtKLZyjBTZycTJ4fpwte2g3di0loZoQOc8', // 👉 o‘zingning anon key'ingni yoz
  );

  // Device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const JobHunterApp());
}

class JobHunterApp extends StatelessWidget {
  const JobHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthController init (permanent - closing ham bo'lmaydi)
    Get.put<AuthController>(AuthController(), permanent: true);

    return GetMaterialApp(
      title: 'Imkon Job',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      translations: AppTranslations(),
      locale: const Locale('uz', 'UZ'),
      fallbackLocale: const Locale('uz', 'UZ'),
      getPages: AppRoutes.routes,

      // Home screen
      home: const SplashScreen(),

      // ✅ REMOVED GetNavigatorObserver (causes error)
      // navigatorObservers: [GetNavigatorObserver()],

      // Navigation settings
      enableLog: false, // Debug logs
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// ==================== OPTIONAL: Custom Navigator Observer ====================

class CustomNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    print('📍 Pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    print('📍 Popped: ${route.settings.name}');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    print('📍 Removed: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    print(
      '📍 Replaced: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}',
    );
  }
}

// Agar custom observer kerak bo'lsa, main.dart MaterialApp (yoki GetMaterialApp) ga:
// navigatorObservers: [CustomNavigatorObserver()]
