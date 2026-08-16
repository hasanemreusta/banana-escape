import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/ui/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class BananaEscapeApp extends StatelessWidget {
  const BananaEscapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bananaYellow,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.bananaYellow,
        secondary: AppColors.leafGreen,
        surface: AppColors.panel,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'sans-serif',
    );

    return MaterialApp(
      title: 'Banana Escape',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.ink,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.panel,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
