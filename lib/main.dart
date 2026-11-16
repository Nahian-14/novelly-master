import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/splash_screen.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NovellyThemeData>(
      valueListenable: NovellyThemeController.instance,
      builder: (context, theme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: theme.isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: theme.paperColor,
            cardColor: theme.cardColor,
            primaryColor: theme.inkColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.deepInkColor,
              brightness: theme.isDark ? Brightness.dark : Brightness.light,
              surface: theme.cardColor,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
