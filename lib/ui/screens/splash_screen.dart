import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/config/app_copy.dart';
import 'package:banana_escape/services/app_services.dart';
import 'package:banana_escape/ui/screens/main_menu_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = await AppServices.bootstrap();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MainMenuScreen(services: services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.skyTop, AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: AppColors.bananaYellow,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  size: 70,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                AppCopy.gameTitle,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Peel out before the blender catches up.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.softInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
