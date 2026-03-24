import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/module_completion_screen.dart';

class Chapter13Screen extends StatefulWidget {
  const Chapter13Screen({super.key});

  @override
  State<Chapter13Screen> createState() => _Chapter13ScreenState();
}

class _Chapter13ScreenState extends State<Chapter13Screen> {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  String? _partnerName;
  String? _partnerImagePath;
  
  late String _dialogue;
  String _displayedDialogue = "";
  int _charIndex = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _partnerName = PersonaMR().getPartner() ?? "ELARA";
    _partnerImagePath = _partnerName == "KAEL" ? "assets/images/char_kael.png" : "assets/images/char_elara.png";
    
    _dialogue = "Ana bilgisayarı düzeltmek için havalandırma tünellerine girmeliyim, ama sen beni yukarıdan yönlendirmelisin. Hayatım senin ellerinde...";
    
    _startTypewriter();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
      AudioService().playVentEcho();
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

  @override
  void dispose() {
    _stopwatch.stop();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  void _makeFinalChoice(bool delegate) {
    if (_isTransitioning) return;

    setState(() => _isTransitioning = true);
    AudioService().playMetalClunk();

    final totalTime = _stopwatch.elapsedMilliseconds;

    PersonaMR().logDecision(
      moduleId: "MOD_3",
      chapterId: "Bölüm 13: Güven Testi",
      choiceId: delegate ? "DELEGATE_TRUST" : "SELF_RELIANCE_CONTROL",
      durationMs: totalTime,
      triggers: [delegate ? "high_trust_delegation" : "low_trust_micro_management", "module_3_final"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 13: Güven Testi",
      totalTimeMs: totalTime,
    );

    // Final Transition
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ModuleCompletionScreen(moduleTitle: "Modül 3: Yalnız Yıldızlar")),
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
          // Background - Vent / Server Room (Dynamic)
          Positioned.fill(
            child: Image.asset(
              _partnerName == "KAEL" ? "assets/images/chapter13_kael.png" : "assets/images/chapter11_elara.png", // Use C11 Elara until C13 Elara is ready
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.85),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildDialogueBox(),
                  const SizedBox(height: 30),
                  if (!_isTransitioning) _buildChoices(),
                  if (_isTransitioning) _buildModuleEndState(),
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
        Text("BÖLÜM 13: GÜVEN TESTİ [FİNAL]", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        Text("SERVER ANALİZ / SEKTÖR C", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildDialogueBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: AppTheme.neonCyan),
              const SizedBox(width: 10),
              Text("${_partnerName} BEKLEMEDE", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _displayedDialogue,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildChoices() {
    return Column(
      children: [
        _buildDecisionTile(
          "\"SANA GÜVENİYORUM. TÜNELE GİR, BEN SENİ YÖNLENDİRECEĞİM.\"",
          "Delegasyon ve Ekip Güveni",
          () => _makeFinalChoice(true),
          AppTheme.neonCyan,
        ),
        const SizedBox(height: 16),
        _buildDecisionTile(
          "\"SEN BURADA DUR. TÜNELİ BEN DAHA İYİ BİLİYORUM, BEN GİDERİM.\"",
          "Mikro-Yönetim ve Risk Kaçınma",
          () => _makeFinalChoice(false),
          Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _buildDecisionTile(String label, String reason, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.rajdhani(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(reason.toUpperCase(), style: GoogleFonts.sourceCodePro(color: color.withOpacity(0.6), fontSize: 9, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleEndState() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.neonCyan),
          const SizedBox(height: 30),
          Text(
            "MODÜL 3 ANALİZİ TAMAMLANDI",
            style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "PERSONAMR VERİLERİ BULUTA AKTARILIYOR...",
            style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
