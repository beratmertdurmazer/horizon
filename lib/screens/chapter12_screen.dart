import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'chapter13_screen.dart';

class Chapter12Screen extends StatefulWidget {
  const Chapter12Screen({super.key});

  @override
  State<Chapter12Screen> createState() => _Chapter12ScreenState();
}

class _Chapter12ScreenState extends State<Chapter12Screen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  bool _isTransitioning = false;
  String? _partnerName;
  String? _partnerImagePath;
  
  late String _dialogue;
  String _displayedDialogue = "";
  int _charIndex = 0;
  Timer? _typewriterTimer;

  late AnimationController _fireController;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _partnerName = PersonaMR().getPartner() ?? "ELARA";
    _partnerImagePath = _partnerName == "KAEL" ? "assets/images/char_kael.png" : "assets/images/char_elara.png";
    
    _dialogue = "Özür dilerim... Sadece yardım etmek istemiştim. Yanlış kabloyu kestik, değil mi?";
    
    _fireController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    
    _startTypewriter();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
      AudioService().playFireCrackle();
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_charIndex < _dialogue.length) {
        if (mounted) {
          setState(() {
            _displayedDialogue += _dialogue[_charIndex];
            _charIndex++;
          });
          if (_charIndex % 2 == 0) AudioService().playTypingBeep();
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
    _fireController.dispose();
    super.dispose();
  }

  void _handleChoice(bool punitive) {
    if (_isTransitioning) return;

    setState(() => _isTransitioning = true);
    AudioService().playMetalClunk();

    final totalTime = _stopwatch.elapsedMilliseconds;

    PersonaMR().logDecision(
      moduleId: "MOD_3",
      chapterId: "Bölüm 12: Partnerin Hatası",
      choiceId: punitive ? "PUNISH_FOOD_RATION" : "FORGIVE_AND_COOPERATE",
      durationMs: totalTime,
      triggers: [punitive ? "authority_over_ethics" : "ethics_over_authority", "conflict_resolution"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 12: Partnerin Hatası",
      totalTimeMs: totalTime,
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Chapter13Screen()),
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
          // Background - Fire Room (Dynamic)
          Positioned.fill(
            child: Image.asset(
              _partnerName == "KAEL" ? "assets/images/chapter12_kael.png" : "assets/images/chapter12_elara.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.8),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          // Fire Flicker Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fireController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.04 * _fireController.value),
                        blurRadius: 50,
                        spreadRadius: 20,
                      )
                    ],
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withOpacity(0.12 * _fireController.value),
                        Colors.transparent,
                      ],
                      center: Alignment.bottomRight,
                      radius: 1.2,
                    ),
                  ),
                );
              },
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
                  _buildPartnerGuiltWindow(),
                  const SizedBox(height: 30),
                  if (!_isTransitioning) _buildChoices(),
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
        Text("BÖLÜM 12: PARTNERİN HATASI", style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        Text("BAKIM ODASI - SU TANKLARI", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildPartnerGuiltWindow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Portrait
          Container(
            height: 90,
            width: 70,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(_partnerImagePath!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.redAccent.withOpacity(0.4), BlendMode.color),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ÜZGÜN VE PİŞMAN", style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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

  Widget _buildChoices() {
    return Column(
      children: [
        _buildChoiceCard(
          "CEZALANDIR VE UYAR",
          "Bir günlük yemek kumanyasına el koy. (Otorite)",
          () => _handleChoice(true),
          Colors.redAccent,
          Icons.gavel,
        ),
        const SizedBox(height: 16),
        _buildChoiceCard(
          "AFFET VE BERABER SÖNDÜR",
          "Hata insana mahsustur. (Diyalog)",
          () => _handleChoice(false),
          AppTheme.neonCyan,
          Icons.fire_hydrant_alt,
        ),
      ],
    );
  }

  Widget _buildChoiceCard(String title, String subtitle, VoidCallback onTap, Color color, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.rajdhani(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.sourceCodePro(color: color.withOpacity(0.7), fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionState() {
    return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
  }
}
