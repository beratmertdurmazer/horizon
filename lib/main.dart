import 'package:flutter/material.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/screens/splash_screen.dart';
import 'package:horizon_protocol/widgets/terminal_overlay.dart';

void main() {
  runApp(const HorizonProtocolApp());
}

class HorizonProtocolApp extends StatelessWidget {
  const HorizonProtocolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horizon Protocol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      builder: (context, child) {
        return TerminalOverlay(child: child!);
      },
    );
  }
}
