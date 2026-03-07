import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/text_styles.dart';
import 'core/theme/app_theme.dart';

// TODO Phase 1.3: Replace with MaterialApp.router + go_router + ProviderScope
class VirtualHeartApp extends StatelessWidget {
  const VirtualHeartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VirtualHeart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: AppColors.heartRed, size: 64),
              const SizedBox(height: 16),
              Text('VirtualHeart', style: AppTextStyles.appName()),
              const SizedBox(height: 8),
              Text('Phase 1.1 — Theme Ready', style: AppTextStyles.moodIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
