import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/chapter7_screen.dart';

class Chapter6Screen extends StatefulWidget {
  const Chapter6Screen({super.key});

  @override
  State<Chapter6Screen> createState() => _Chapter6ScreenState();
}

class _Chapter6ScreenState extends State<Chapter6Screen> with TickerProviderStateMixin {
  late Stopwatch _decisionStopwatch;
  bool _alarmsMuted = false;
  bool _isTransitioning = false;
  late AnimationController _flickerController;
  late AnimationController _floatingAlarmsController;
  final List<Offset> _alarmPositions = List.generate(5, (_) => Offset(math.Random().nextDouble() * 200, math.Random().nextDouble() * 400));
  
  @override
  void initState() {
    super.initState();
    _decisionStopwatch = Stopwatch()..start();
    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..repeat(reverse: true);
    _floatingAlarmsController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playUrgentSiren();
    });
  }

  void _handleDecision(bool mute) {
    if (_isTransitioning) return;
    setState(() {
      _isTransitioning = true;
      _alarmsMuted = mute;
    });

    if (mute) {
      AudioService().stopSiren();
      AudioService().playMetalClunk();
    }

    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 6: Alarm Yorgunluğu",
      choiceId: mute ? "MUTE_ALARMS_COMFORT" : "KEEP_ALARMS_VIGILANCE",
      durationMs: _decisionStopwatch.elapsedMilliseconds,
      triggers: ["noise_stress_level_high"],
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Chapter7Screen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _decisionStopwatch.stop();
    _flickerController.dispose();
    _floatingAlarmsController.dispose();
    AudioService().stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/chapter6_background.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.8),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Flashing Red Glare
          if (!_alarmsMuted)
            AnimatedBuilder(
              animation: _flickerController,
              builder: (context, child) {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.withOpacity(_flickerController.value * 0.3), width: 10),
                    ),
                  ),
                );
              },
            ),

          // Floating Virtual Alarms (The Chaos)
          if (!_alarmsMuted) ..._buildFloatingAlarms(),

          SizedBox.expand(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildHeader(),
                    const Spacer(),
                    _buildNarrative(),
                    const SizedBox(height: 40),
                    if (!_isTransitioning) ...[
                      _buildDecisionButton(
                        "ALARMLARI SUSTUR",
                        "Sessizliği seç ve gürültüyü kes. (Gözlem kaybı riski)",
                        Icons.volume_off,
                        Colors.white70,
                        () => _handleDecision(true),
                      ),
                      const SizedBox(height: 16),
                      _buildDecisionButton(
                        "KAOSU KABUL ET",
                        "Gürültüyü veri olarak işle. (Yüksek dikkat seviyesi)",
                        Icons.sensors,
                        AppTheme.neonCyan,
                        () => _handleDecision(false),
                      ),
                    ] else ...[
                      const CircularProgressIndicator(color: Colors.red),
                      const SizedBox(height: 20),
                      Text(
                        _alarmsMuted ? "SESSİZLİK MODU AKTİF" : "VERİ AKIŞI SENKRONİZE EDİLİYOR",
                        style: GoogleFonts.sourceCodePro(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          const DevNav(),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingAlarms() {
    final size = MediaQuery.of(context).size;
    return List.generate(5, (index) {
      return AnimatedBuilder(
        animation: _floatingAlarmsController,
        builder: (context, child) {
          // Ekran genişliğine yayılan ve yüzen rastgele pozisyonlar
          final baseOffset = _alarmPositions[index];
          final x = (baseOffset.dx * (size.width - 150)) / 200 + 40 * math.sin(_floatingAlarmsController.value * 2 * math.pi + index);
          final y = (baseOffset.dy * (size.height - 100)) / 400 + 40 * math.cos(_floatingAlarmsController.value * 2 * math.pi + index);
          
          return Positioned(
            left: x.clamp(0.0, size.width - 150),
            top: y.clamp(50.0, size.height - 100),
            child: Opacity(
              opacity: 0.3 + 0.7 * _flickerController.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: Text("! CRITICAL ERROR", style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text("MODÜL 2: SESSİZ ÇIĞLIK", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3)),
        Text("BÖLÜM 6: ALARM YORGUNLUĞU", style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNarrative() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), border: Border.all(color: Colors.red.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
      child: Text(
        "\"Beynin alarmlardan uğulduyor. Her saniye bir başka arıza raporu... Bu gürültüyü kesecek misin yoksa veriye mi dönüştüreceksin?\"",
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: Colors.white, height: 1.6, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildDecisionButton(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.rajdhani(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(sub, style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
