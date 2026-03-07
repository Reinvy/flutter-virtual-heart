import 'package:flutter/material.dart';

// TODO Phase 2.3: Implement OnboardingScreen
// - 3-page swipeable PageView
// - "Mulai" button on last page → PersonaSetupScreen
// - Save isOnboardingDone = true to AppSettings

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Onboarding — Phase 2.3')));
  }
}
