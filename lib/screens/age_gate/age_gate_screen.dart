import 'package:flutter/material.dart';

// TODO Phase 2.2: Implement AgeGateScreen
// - Confirm age ≥ 18 (PRD FR-01)
// - Save isAgeVerified = true to AppSettings
// - Block access if user declines

class AgeGateScreen extends StatelessWidget {
  const AgeGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Age Gate — Phase 2.2')));
  }
}
