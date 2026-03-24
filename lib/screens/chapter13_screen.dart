import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';

class Chapter13Screen extends StatelessWidget {
  const Chapter13Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("BÖLÜM 13", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text("GÜVEN TESTİ", style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: AppTheme.neonCyan),
                const SizedBox(height: 20),
                Text("MODÜL FİNALİNE HAZIRLANILIYOR...", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ),
          const DevNav(),
        ],
      ),
    );
  }
}
