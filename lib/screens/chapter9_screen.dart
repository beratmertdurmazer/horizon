import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/widgets/dev_nav.dart';
import 'package:horizon_protocol/screens/module_transition_screen.dart';
import 'package:horizon_protocol/screens/chapter10_screen.dart';

class Chapter9Screen extends StatefulWidget {
  const Chapter9Screen({super.key});

  @override
  State<Chapter9Screen> createState() => _Chapter9ScreenState();
}

class _Chapter9ScreenState extends State<Chapter9Screen> with TickerProviderStateMixin {
  late Stopwatch _decisionStopwatch;
  bool _isFinished = false;
  
  final List<Map<String, dynamic>> _answers = [
    {"text": "Segmentleri daha iyi araştırabilirdim", "type": "INTERNAL_CRITIQUE"},
    {"text": "Sinyaller karşısında biraz dikkatim dağılmış olabilir", "type": "INTERNAL_HONEST"},
    {"text": "Kendimi bir anda çok fazla işin içinde buldum", "type": "INTERNAL_RESOURCE"},
    {"text": "Sistem beni zamanında uyarmadı", "type": "EXTERNAL_SYSTEM"},
    {"text": "Tanımadığım bir ortamda çalışıyorum", "type": "EXTERNAL_CONTEXT"},
    {"text": "Zaten yapacak bir şey yoktu", "type": "EXTERNAL_FATALISM"},
    {"text": "Daha dikkatli olmayı öğrendim", "type": "INTERNAL_GROWTH"},
  ];

  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _decisionStopwatch = Stopwatch()..start();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    PersonaMR().startChapterTimer("Bölüm 9: Enkazın Ardından");
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playMelancholicAmbient();
    });
  }

  void _handleChoice(Map<String, dynamic> answer) {
    if (_isFinished) return;
    PersonaMR().recordInteraction("Bölüm 9: Enkazın Ardından", "REFLECTION_CHOICE", metadata: {"text": answer["text"], "type": answer["type"]});
    setState(() => _isFinished = true);
    
    _decisionStopwatch.stop();
    AudioService().playTypingBeep();
    AudioService().stopAll();

    final totalTime = _decisionStopwatch.elapsedMilliseconds;

    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 9: Enkazın Ardından",
      choiceId: "WORD_CLOUD_COMPLETE",
      durationMs: totalTime,
      triggers: ["self_reflection"],
    );

    PersonaMR().logChapterMetrics(
      chapterId: "Bölüm 9: Enkazın Ardından",
      totalTimeMs: totalTime,
      additionalData: {
        "responseDelay": totalTime, // Time until they picked their reflection
      },
    );

    PersonaMR().logDecision(
      moduleId: "MOD_2",
      chapterId: "Bölüm 9: Enkazın Ardından",
      choiceId: answer["type"],
      durationMs: _decisionStopwatch.elapsedMilliseconds,
      triggers: ["scapegoating_analysis", "post_failure_reflection"],
    );

    _showTransition();
  }

  void _showTransition() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics_outlined, color: AppTheme.neonCyan, size: 50),
              const SizedBox(height: 20),
              Text("ANALİZ KAYDEDİLDİ", style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(
                "Verdiğin cevaplar algoritma tarafından işlendi. Hata analizi tamamlandı.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModuleTransitionScreen(
                        moduleTitle: "MODÜL 3",
                        moduleSubtitle: "YALNIZ YILDIZLAR",
                        objective: "Kolektif zeka, takım uyumu ve yetki devri yetkinliklerinin ölçümü.",
                        icon: Icons.people_outline,
                        nextScreen: const Chapter10Screen(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan.withOpacity(0.1), side: const BorderSide(color: AppTheme.neonCyan)),
                child: Text("MODÜL 3'E HAZIRLAN", style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
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
              "assets/images/chapter9_background.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.7),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Narrative Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildQuestion(),
                  const Spacer(),
                  _buildCevapBulutu(),
                  const Spacer(),
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
      children: [
        Text("MODÜL 2: SESSİZ ÇIĞLIK", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3)),
        Text("BÖLÜM 9: ENKAZIN ARDINDAN", style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuestion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.android, color: Colors.white38, size: 16),
              const SizedBox(width: 8),
              Text("A.I.D.A SİSTEM MESAJI", style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "\"Laboratuvar modülü artık yok. Emeklerinin yarısı uzay boşluğuna gitti. Neden başaramadık? Vereceğin cevaplar hata analizimiz için kritik.\"",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white, height: 1.6, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildCevapBulutu() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: _answers.map((answer) => _buildTag(answer)).toList(),
    );
  }

  Widget _buildTag(Map<String, dynamic> answer) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = math.sin(_floatController.value * 2 * math.pi + answer.hashCode) * 5;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: InkWell(
        onTap: () => _handleChoice(answer),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            answer["text"],
            style: GoogleFonts.rajdhani(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
