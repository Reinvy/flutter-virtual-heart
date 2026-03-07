import 'package:flutter/material.dart';

// TODO Phase 2.1: Implement SplashScreen
// - Logo + animated heart (Lottie or flutter_animate)
// - Auto-navigate after 2s based on AppSettings state

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
