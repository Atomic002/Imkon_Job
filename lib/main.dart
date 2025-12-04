import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/Screens/splash/splash_screen.dart';
import 'package:flutter_application_2/Services/connective_service.dart';
import 'package:flutter_application_2/config/routes.dart';
import 'package:flutter_application_2/config/themes.dart';
import 'package:flutter_application_2/translations/app_translations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🚀 ===== APP INITIALIZATION START =====');

    // 1️⃣ GetStorage init
    await GetStorage.init();
    print('✅ GetStorage initialized');

    // 2️⃣ Supabase init
    await Supabase.initialize(
      url: 'https://lebttvzssavbjkoumebf.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlYnR0dnpzc2F2Ymprb3VtZWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0OTQyNzgsImV4cCI6MjA3NjA3MDI3OH0.psRAzz881AtKLZyjBTZycTJ4fpwte2g3di0loZoQOc8',
    );
    print('✅ Supabase initialized');

    // 3️⃣ Device orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 4️⃣ Status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // 5️⃣ ConnectivityService init (ASYNC)
    await Get.putAsync<ConnectivityService>(
      () async => await ConnectivityService().init(),
      permanent: true,
    );
    print('✅ ConnectivityService initialized');

    print('✅ ===== APP INITIALIZATION COMPLETE =====');

    runApp(const JobHunterApp());
  } catch (e, stackTrace) {
    print('❌ ===== INITIALIZATION ERROR =====');
    print('Error: $e');
    print('StackTrace: $stackTrace');

    // Xato bo'lsa ham ilovani ishga tushirish (Fallback UI)
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ilovani ishga tushirishda xatolik',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        SystemNavigator.pop(); // Ilovadan chiqish
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Yopish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JobHunterApp extends StatelessWidget {
  const JobHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Imkon Job',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      translations: AppTranslations(),
      locale: const Locale('uz', 'UZ'),
      fallbackLocale: const Locale('uz', 'UZ'),
      getPages: AppRoutes.routes,
      home: const SplashScreen(),

      // ✅ Debug uchun
      enableLog: true,
      logWriterCallback: (String text, {bool isError = false}) {
        if (isError) {
          print('❌ GetX Error: $text');
        } else {
          print('ℹ️ GetX: $text');
        }
      },

      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
