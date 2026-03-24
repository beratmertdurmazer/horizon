import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/audio_service.dart';

class ModuleTransitionScreen extends StatefulWidget {
  final String moduleTitle;
  final String moduleSubtitle;
  final String objective;
  final IconData icon;
  final Widget nextScreen;

  const ModuleTransitionScreen({
    super.key,
    required this.moduleTitle,
    required this.moduleSubtitle,
    required this.objective,
    required this.icon,
    required this.nextScreen,
  });

  @override
  State<ModuleTransitionScreen> createState() => _ModuleTransitionScreenState();
}

class _ModuleTransitionScreenState extends State<ModuleTransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    
    _controller.forward();
    AudioService().playPowerSurge();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(color: AppTheme.neonCyan.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                        child: Icon(widget.icon, color: AppTheme.neonCyan, size: 60),
                      ),
                      const SizedBox(height: 50),
                      Text(
                        widget.moduleTitle,
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.moduleSubtitle,
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.neonCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 60, thickness: 1, indent: 40, endIndent: 40),
                      Text(
                        "ANALİZ HEDEFİ",
                        style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10, letterSpacing: 2),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        widget.objective,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 80),
                      ElevatedButton(
                        onPressed: () {
                          AudioService().playTypingBeep();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => widget.nextScreen),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonCyan.withOpacity(0.1),
                          side: BorderSide(color: AppTheme.neonCyan),
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        ),
                        child: Text(
                          "PROTOKOLÜ BAŞLAT",
                          style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
