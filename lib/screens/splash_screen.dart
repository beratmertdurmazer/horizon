import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/screens/user_entry_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _loadingText = "BİLİNCİN GERİ YÜKLENİYOR...";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    
    // Simüle edilen yükleme metinleri
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _loadingText = "CRYO-SIVISI TAHLİYE EDİLİYOR...");
    });

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserEntryScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppTheme.spaceBackground,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Logo veya Simge
                  Container(
                    width: 80,
                    height: 80,
                    decoration: AppTheme.neonBoxDecoration,
                    child: const Icon(
                      Icons.blur_on,
                      color: AppTheme.neonCyan,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "HORIZON PROTOCOL",
                    style: AppTheme.darkTheme.textTheme.displayLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "EVENTIDE STATION / SECTOR 7",
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      letterSpacing: 4.0,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
            // Progress Indicator
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.spaceCard,
                color: AppTheme.neonCyan,
                minHeight: 2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _loadingText,
              style: GoogleFonts.rajdhani(
                color: AppTheme.textSecondary,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
