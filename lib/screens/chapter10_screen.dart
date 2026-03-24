import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/dev_nav.dart';

class Chapter10Screen extends StatelessWidget {
  const Chapter10Screen({super.key});

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
                const Icon(Icons.people_outline, color: Colors.purpleAccent, size: 80),
                const SizedBox(height: 30),
                Text(
                  "MODÜL 3: YALNIZ YILDIZLAR",
                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3),
                ),
                Text(
                  "BÖLÜM 10: BUZDAN ÇIKAN YÜZ",
                  style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  "YAKINDA (DEVELOPMENT)...",
                  style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const DevNav(),
        ],
      ),
    );
  }
}
