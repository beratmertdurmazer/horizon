import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'chapter5_screen.dart';

enum EnergyArea { labs, quarters, greenhouse }

class Chapter4Screen extends StatefulWidget {
  const Chapter4Screen({super.key});

  @override
  State<Chapter4Screen> createState() => _Chapter4ScreenState();
}

class _Chapter4ScreenState extends State<Chapter4Screen> with SingleTickerProviderStateMixin {
  late Stopwatch _decisionStopwatch;
  EnergyArea? _selectedArea;
  bool _isTransitioning = false;
  bool _showBlackout = false;
  late AnimationController _flickerController;
  final String _narrative = "\"Enerji kritik,\" diyor A.I.D.A. \"İstasyonun kalbinde ışıkları açık tutmak için diğer bölmeleri karanlığa gömmelisin. Laboratuvarlar mı, mürettebat yatakhanesi mi, yoksa sera mı?\"";
  String _displayedNarrative = "";
  int _charIndex = 0;
  Timer? _typewriterTimer;
  Timer? _glitchTimer;
  Timer? _hiddenCountdownTimer;
  int _hiddenSecondsRemaining = 120;
  String _glitchedEnergyText = "ENERJİ KRİTİK (%12)";

  @override
  void initState() {
    super.initState();
    _decisionStopwatch = Stopwatch()..start();
    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _startTypewriter();
    _startGlitchEffects();
    _startHiddenTimer();
    
    // Start ambient hum
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_charIndex < _narrative.length) {
        if (mounted) {
          setState(() {
            _displayedNarrative += _narrative[_charIndex];
            _charIndex++;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _startGlitchEffects() {
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (math.Random().nextDouble() > 0.8) {
          _glitchedEnergyText = _applyGlitch("ENERJİ KRİTİK (%12)");
        } else {
          _glitchedEnergyText = "ENERJİ KRİTİK (%12)";
        }
      });
    });
  }

  void _startHiddenTimer() {
    _hiddenCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTransitioning || !mounted) {
        timer.cancel();
        return;
      }
      _hiddenSecondsRemaining--;
      if (_hiddenSecondsRemaining <= 0) {
        timer.cancel();
        _makeDecision(EnergyArea.values[math.Random().nextInt(3)], auto: true);
      }
    });
  }

  String _applyGlitch(String input) {
    const chars = "!@#\$%^&*()_+-=[]{}|;:,.<>?";
    List<String> result = input.split('');
    int glitchCount = math.Random().nextInt(3) + 1;
    for (int i = 0; i < glitchCount; i++) {
      int pos = math.Random().nextInt(result.length);
      result[pos] = chars[math.Random().nextInt(chars.length)];
    }
    return result.join('');
  }

  @override
  void dispose() {
    _decisionStopwatch.stop();
    _flickerController.dispose();
    _typewriterTimer?.cancel();
    _glitchTimer?.cancel();
    _hiddenCountdownTimer?.cancel();
    AudioService().stopAll();
    super.dispose();
  }

  void _makeDecision(EnergyArea area, {bool auto = false}) {
    if (_isTransitioning) return;
    
    setState(() {
      _selectedArea = area;
      _isTransitioning = true;
      _showBlackout = true;
    });

    // decision sounds
    AudioService().playMetalClunk();
    AudioService().playPowerSurge();

    // Screen Glitch effect (0.5s blackout)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showBlackout = false);
    });

    String choiceId = "";
    switch (area) {
      case EnergyArea.labs: choiceId = "SACRIFICE_LABS_RD"; break;
      case EnergyArea.quarters: choiceId = "SACRIFICE_QUARTERS_HAPPINESS"; break;
      case EnergyArea.greenhouse: choiceId = "SACRIFICE_GREENHOUSE_ENV"; break;
    }

    PersonaMR().logDecision(
      moduleId: "MOD_1",
      chapterId: "Bölüm 4: Karanlık Koridorlar",
      choiceId: auto ? "${choiceId}_AUTO" : choiceId,
      durationMs: _decisionStopwatch.elapsedMilliseconds,
      triggers: ["energy_crisis", auto ? "timer_expired" : "manual_choice"],
    );

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Chapter5Screen()),
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
          // Background - Darker on transitions
          Positioned.fill(
            child: Image.asset(
              "assets/images/chapter4_background.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(_isTransitioning ? 0.95 : 0.9),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          // Emergency flickering overlay
          AnimatedBuilder(
            animation: _flickerController,
            builder: (context, child) {
              double intensity = 0;
              if (_hiddenSecondsRemaining <= 10) {
                // Sadece son 10 saniyede yanıp sönmeyi aktifleştir
                intensity = _flickerController.value * (1.1 - (_hiddenSecondsRemaining / 10));
              }
              
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.red.withOpacity(0.15 * intensity.clamp(0, 1)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox.expand(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      if (!_isTransitioning) ...[
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildNarrativeWindow(),
                        const SizedBox(height: 40),
                        _buildChoiceCard(EnergyArea.labs, "LABORATUVARLAR", "AR-GE & İNOVASYON", Icons.biotech, AppTheme.neonCyan),
                        const SizedBox(height: 16),
                        _buildChoiceCard(EnergyArea.quarters, "MÜRETTEBAT YATAKHANESİ", "ÇALIŞAN REFAHI & MUTLULUK", Icons.hotel, Colors.orange),
                        const SizedBox(height: 16),
                        _buildChoiceCard(EnergyArea.greenhouse, "SERA DOME", "EKOLOJİK DENGE & DUYARLILIK", Icons.eco, Colors.green),
                      ] else ...[
                        _buildTransitionState(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Visual (Screen Glitch/Blackout)
          if (_showBlackout) Positioned.fill(child: Container(color: Colors.black)),

          const DevNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("BÖLÜM 4: KARANLIK KORİDORLAR", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            Text(_glitchedEnergyText, style: GoogleFonts.sourceCodePro(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        _buildEnergyPulse(),
      ],
    );
  }

  Widget _buildEnergyPulse() {
    return AnimatedBuilder(
      animation: _flickerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withOpacity(0.3 + (_flickerController.value * 0.4))),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.bolt, color: Colors.red.withOpacity(0.5 + (_flickerController.value * 0.5)), size: 20),
        );
      },
    );
  }

  Widget _buildNarrativeWindow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_displayedNarrative, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.6)),
    );
  }

  Widget _buildChoiceCard(EnergyArea area, String title, String subtitle, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _makeDecision(area),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    String message = "";
    switch (_selectedArea) {
      case EnergyArea.labs: message = "LABORATUVAR GÜCÜ KESİLİYOR... VERİLER DONDURULDU."; break;
      case EnergyArea.quarters: message = "YATAKHANE GÜCÜ KESİLİYOR... YAŞAM DESTEĞİ MİNİMAL."; break;
      case EnergyArea.greenhouse: message = "SERA GÜCÜ KESİLİYOR... EKOSİSTEM ÇÖKÜYOR."; break;
      default: break;
    }

    return Column(
      children: [
        const SizedBox(height: 50),
        const CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
        const SizedBox(height: 30),
        Text(message, textAlign: TextAlign.center, style: GoogleFonts.sourceCodePro(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
