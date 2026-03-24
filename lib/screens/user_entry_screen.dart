import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/screens/intro_screen.dart';

class UserEntryScreen extends StatefulWidget {
  const UserEntryScreen({super.key});

  @override
  State<UserEntryScreen> createState() => _UserEntryScreenState();
}

class _UserEntryScreenState extends State<UserEntryScreen> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  
  late AnimationController _glitchController;
  late AnimationController _fadeController;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..repeat(reverse: true);
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeController.forward();
    
    AudioService().playPowerOn();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _glitchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startSession() {
    if (_nameController.text.trim().isEmpty || _positionController.text.trim().isEmpty) {
      AudioService().playStaticBurst();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.withOpacity(0.8),
          content: Text("BİLGİ EKSİK: KİMLİK TANIMLANAMADI", style: GoogleFonts.sourceCodePro(color: Colors.white)),
        ),
      );
      return;
    }

    setState(() => _isInitializing = true);
    AudioService().playTypingBeep();

    // Initialize session with PersonaMR
    PersonaMR().initSession(_nameController.text.trim(), _positionController.text.trim());

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background - Scanlines and Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _TerminalPainter()),
            ),
          ),

          FadeTransition(
            opacity: _fadeController,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO / PROTOCOL HEADER
                    _buildHeader(),
                    const SizedBox(height: 60),

                    // FORM CONTAINER
                    _buildForm(),
                    const SizedBox(height: 50),

                    // START BUTTON
                    _buildStartButton(),
                  ],
                ),
              ),
            ),
          ),

          if (_isInitializing) _buildLoaderOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glitchController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_glitchController.value * 2, 0),
              child: Text(
                "HORIZON PROTOCOL",
                style: GoogleFonts.rajdhani(
                  color: AppTheme.neonCyan,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(color: AppTheme.neonCyan.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          "PERSONA ASSESSMENT MODULE V3.1",
          style: GoogleFonts.sourceCodePro(
            color: Colors.white24,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 200,
          height: 1,
          color: AppTheme.neonCyan.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "KİMLİK DOĞRULAMA",
            style: GoogleFonts.rajdhani(
              color: AppTheme.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 30),
          
          // Name Field
          _buildLabel("AD SOYAD / IDENTIFIER"),
          TextField(
            controller: _nameController,
            style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 16),
            cursorColor: AppTheme.neonCyan,
            decoration: InputDecoration(
              isDense: true,
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
              hintText: "ÖRN: OPERATÖR_7X",
              hintStyle: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 14),
            ),
          ),
          
          const SizedBox(height: 40),

          // Position Field
          _buildLabel("ÇALIŞMA POZİSYONU"),
          TextField(
            controller: _positionController,
            style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 16),
            cursorColor: AppTheme.neonCyan,
            decoration: InputDecoration(
              isDense: true,
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
              hintText: "ÖRN: İK DİREKTÖRÜ / YAZILIM EKİP LİDERİ",
              hintStyle: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 9, letterSpacing: 1),
      ),
    );
  }

  Widget _buildStartButton() {
    return InkWell(
      onTap: _startSession,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.neonCyan),
          color: AppTheme.neonCyan.withOpacity(0.05),
        ),
        child: Text(
          "PROTOKOLÜ BAŞLAT",
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildLoaderOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.neonCyan, strokeWidth: 1),
              const SizedBox(height: 30),
              Text(
                "VERİ ANALİZİ HAZIRLANIYOR...",
                style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 12),
              ),
              Text(
                "PERSONAMR SİSTEMİ ÇEVRİMİÇİ",
                style: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint..strokeWidth = 0.5);
    }
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint..strokeWidth = 0.2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
