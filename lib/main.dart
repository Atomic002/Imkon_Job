import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:version1/Screens/admin_panel_screen.dart';
import 'package:version1/Screens/chat_screen.dart';
import 'package:version1/Screens/create_post_screen.dart';
import 'package:version1/Screens/home_screen.dart';
import 'package:version1/Screens/language_selection_screen.dart';
import 'package:version1/Screens/login_screen.dart';
import 'package:version1/Screens/post_detail_screen.dart';
import 'package:version1/Screens/profile_screen.dart';
import 'package:version1/Screens/register_screen.dart';
import 'package:version1/Screens/search_screen.dart';
import 'package:version1/Screens/splash_screen.dart';
import 'package:version1/Screens/stats_screen.dart';
import 'package:version1/translation.dart';


void main() async {
  await GetStorage.init(); // Offline storage
  runApp(JobHunterApp());
}

class JobHunterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Job Hunter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Colors.teal,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.robotoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      translations: AppTranslations(),
      locale: GetStorage().read('language') != null
          ? Locale(GetStorage().read('language').split('_')[0], GetStorage().read('language').split('_')[1])
          : Locale('uz', 'UZ'),
      fallbackLocale: Locale('uz', 'UZ'),
      home: SplashScreen(),
      getPages: AppRoutes.routes,
    );
  }
}

class AppRoutes {
  static final routes = [
    GetPage(name: '/splash', page: () => SplashScreen()),
    GetPage(name: '/language', page: () => LanguageSelectionScreen()),
    GetPage(name: '/login', page: () => LoginScreen()),
    GetPage(name: '/register', page: () => RegisterScreen()),
    GetPage(name: '/home', page: () => HomeScreen()),
    GetPage(name: '/search', page: () => SearchScreen()),
    GetPage(name: '/chat', page: () => ChatScreen()),
    GetPage(name: '/profile', page: () => ProfileScreen()),
    GetPage(name: '/create_post', page: () => CreatePostScreen()),
    GetPage(name: '/post_detail', page: () => PostDetailScreen()),
    GetPage(name: '/stats', page: () => StatsScreen()),
    GetPage(name: '/admin', page: () => AdminPanelScreen()),
  ];
}