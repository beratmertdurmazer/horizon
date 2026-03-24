import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/dev_nav.dart';

class Chapter9Screen extends StatelessWidget {
  const Chapter9Screen({super.key});

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
                const Icon(Icons.cloud_done_outlined, color: Colors.greenAccent, size: 80),
                const SizedBox(height: 30),
                Text(
                  "BÖLÜM 9: ENKAZIN ARDINDAN",
                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3),
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
