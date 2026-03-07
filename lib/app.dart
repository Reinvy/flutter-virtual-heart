import 'package:flutter/material.dart';

// TODO Phase 1.3: Replace with MaterialApp.router + go_router + ProviderScope
class VirtualHeartApp extends StatelessWidget {
  const VirtualHeartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VirtualHeart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: const Color(0xFF0D0A0E)),
      home: const Scaffold(
        backgroundColor: Color(0xFF0D0A0E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Color(0xFFE8506A), size: 64),
              SizedBox(height: 16),
              Text(
                'VirtualHeart',
                style: TextStyle(
                  color: Color(0xFFF5EEF8),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Phase 0 — Setup Complete',
                style: TextStyle(color: Color(0xFFB39DBD), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
