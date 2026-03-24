import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'chapter12_screen.dart';
import 'package:horizon_protocol/screens/chapter_breather_screen.dart';

class Chapter11Screen extends StatefulWidget {
  const Chapter11Screen({super.key});

  @override
  State<Chapter11Screen> createState() => _Chapter11ScreenState();
}

class _Chapter11ScreenState extends State<Chapter11Screen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  String? _partnerName;
  String? _partnerImagePath;
  
  late String _dialogue;
  String _displayedDialogue = "";
  int _charIndex = 0;
  Timer? _typewriterTimer;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _partnerName = PersonaMR().getPartner() ?? "ELARA";
    _partnerImagePath = _partnerName == "KAEL" ? "assets/images/char_kael.png" : "assets/images/char_elara.png";
    
    _dialogue = "İtiraz ediyorum, Operatör. Bu yol bizi öldürür, oksijen problemini çözdüğüne emin değilim. Başka bir yöntem izleyebiliriz...";
    
    _startTypewriter();
    _startTensePulse();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_charIndex < _dialogue.length) {
        if (mounted) {
          setState(() {
            _displayedDialogue += _dialogue[_charIndex];
            _charIndex++;
          });
          if (_charIndex % 3 == 0) AudioService().playTypingBeep();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _startTensePulse() {
    _pulseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isTransitioning || !mounted) {
        timer.cancel();
        return;
      }
      AudioService().playTensePulse();
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _typewriterTimer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _makeChoice(bool collaborative) {
    if (_isTransitioning) return;

    setState(() => _isTransitioning = true);
    AudioService().playMetalClunk();

    final totalTime = _stopwatch.elapsedMilliseconds;
    final bool authority = !collaborative; // Map 'collaborative' to 'authority' for choiceId and triggers

    PersonaMR().logDecision(
      moduleId: "MOD_3",
      chapterId: "Bölüm 11: İlk Tartışma",
      choiceId: authority ? "AUTHORITY_OVER_ETHICS" : "ETHICS_OVER_AUTHORITY",
      durationMs: totalTime,
      triggers: [authority ? "authoritarian" : "cooperative", "conflict_resolution"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 11: İlk Tartışma",
      totalTimeMs: totalTime,
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChapterBreatherScreen(
            completedChapterTitle: "Bölüm 11: İlk Tartışma",
            nextChapterHint: "Liderlik yaklaşımın kaydedildi. Yangın alarmı.",
            nextScreen: Chapter12Screen(),
          )),
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
          // Background - Sector D Corridor (Dynamic)
          Positioned.fill(
            child: Image.asset(
              _partnerName == "KAEL" ? "assets/images/chapter11_kael.png" : "assets/images/chapter11_elara.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.85),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildPartnerCard(),
                  const SizedBox(height: 30),
                  if (!_isTransitioning) _buildChoiceButtons(),
                  if (_isTransitioning) _buildTransitionState(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          const DevNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("BÖLÜM 11: İLK TARTIŞMA", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        Text("SEKTÖR D - BAKIM TÜNELİ GİRİŞİ", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildPartnerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner Portrait
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(_partnerImagePath!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(AppTheme.neonCyan.withOpacity(0.2), BlendMode.color),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${_partnerName == "KAEL" ? "DR. KAEL" : "ELARA"} KONUŞUYOR:", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Text(
                  _displayedDialogue,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButtons() {
    return Column(
      children: [
        _buildActionButton(
          "\"NEDEN BÖYLE DÜŞÜNÜYORSUN? TEKRAR KONTROL EDELİM.\"",
          () => _makeChoice(true),
          AppTheme.neonCyan,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          "\"OKSİJEN SORUNU YOK. YETKİLİ BENİM, DEDİĞİMİ YAP!\"",
          () => _makeChoice(false),
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(color: color, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTransitionState() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.neonCyan),
          const SizedBox(height: 20),
          Text("STRATEJİ KAYDEDİLİYOR...", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
