import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/screens/chapter3_screen.dart';

class Chapter2Screen extends StatefulWidget {
  const Chapter2Screen({super.key});

  @override
  State<Chapter2Screen> createState() => _Chapter2ScreenState();
}

enum TriageSystem { reactor, oxygen, comms, none }

class _Chapter2ScreenState extends State<Chapter2Screen> with TickerProviderStateMixin {
  double _reactorHealth = 0.6;
  double _oxygenLevel = 0.5;
  double _commsSignal = 0.4;
  TriageSystem _focusedSystem = TriageSystem.none;
  bool _isCompleted = false;
  late Stopwatch _stopwatch;
  Timer? _tickTimer;
  Timer? _heartbeatTimer;
  TriageSystem? _firstPriority;
  Map<TriageSystem, double> _timeSpent = {
    TriageSystem.reactor: 0,
    TriageSystem.oxygen: 0,
    TriageSystem.comms: 0,
  };

  late AnimationController _pulseController;
  late AnimationController _stressController;
  late AnimationController _glitchController;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _stressController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)..repeat(reverse: true);
    _glitchController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _startTicking();
    _startHeartbeat();
  }

  void _startTicking() {
    _tickTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isCompleted) return;
      setState(() {
        double decayFactor = 0.002;
        double repairFactor = 0.008;
        _reactorHealth -= decayFactor;
        _oxygenLevel -= decayFactor;
        _commsSignal -= decayFactor;
        if (_focusedSystem != TriageSystem.none) {
          _timeSpent[_focusedSystem] = (_timeSpent[_focusedSystem] ?? 0) + 50;
          switch (_focusedSystem) {
            case TriageSystem.reactor: _reactorHealth += repairFactor; break;
            case TriageSystem.oxygen: _oxygenLevel += repairFactor; break;
            case TriageSystem.comms: _commsSignal += repairFactor; break;
            default: break;
          }
        }
        _reactorHealth = _reactorHealth.clamp(0.0, 1.0);
        _oxygenLevel = _oxygenLevel.clamp(0.0, 1.0);
        _commsSignal = _commsSignal.clamp(0.0, 1.0);
        if (_reactorHealth > 0.9 && _oxygenLevel > 0.9 && _commsSignal > 0.9) _completeTriage();
        if (_reactorHealth <= 0 || _oxygenLevel <= 0 || _commsSignal <= 0) _triggerGlitch();
      });
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    double minHealth = math.min(_reactorHealth, math.min(_oxygenLevel, _commsSignal));
    int bpm = (60 + (40 * (1.0 - minHealth)) + (_stopwatch.elapsed.inSeconds * 2)).clamp(60, 180).toInt();
    _stressController.duration = Duration(milliseconds: (30000 / bpm).toInt());
    _heartbeatTimer = Timer(Duration(milliseconds: (60000 / bpm).toInt()), () {
      if (!_isCompleted) { AudioService().playHeartbeat(); _startHeartbeat(); }
    });
  }

  void _triggerGlitch() {
    if (_isGlitching) return;
    AudioService().playGlitchSound();
    setState(() => _isGlitching = true);
    _glitchController.forward(from: 0).then((_) => setState(() => _isGlitching = false));
  }

  void _setFocus(TriageSystem system) {
    if (_isCompleted) return;
    AudioService().playTypingBeep();
    _firstPriority ??= system;
    setState(() => _focusedSystem = system);
  }

  void _completeTriage() {
    if (_isCompleted) return;
    _isCompleted = true;
    _stopwatch.stop();
    _tickTimer?.cancel();
    _heartbeatTimer?.cancel();
    PersonaMR().logDecision(moduleId: "MOD_1", chapterId: "Bölüm 2: İlk TriaJ", choiceId: "TRIAGE_COMPLETED", durationMs: _stopwatch.elapsedMilliseconds, triggers: ["priority_${_firstPriority.toString().split('.').last}", "balance_score_${(_reactorHealth + _oxygenLevel + _commsSignal) / 3}"]);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Chapter3Screen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel(); _heartbeatTimer?.cancel();
    _pulseController.dispose(); _stressController.dispose(); _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double minHealth = math.min(_reactorHealth, math.min(_oxygenLevel, _commsSignal));
    Color stressColor = Color.lerp(AppTheme.neonCyan, Colors.red, 1.0 - minHealth)!;
    double xShift = _isGlitching ? (math.Random().nextDouble() * 20 - 10) : 0;
    double yShift = _isGlitching ? (math.Random().nextDouble() * 20 - 10) : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [stressColor.withOpacity(0.1 + (1.0 - minHealth) * 0.2), Colors.black])))),
          Transform.translate(
            offset: Offset(xShift, yShift),
            child: SafeArea(
              child: SingleChildScrollView( // SCROLL EKLENDI
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildHeader(stressColor),
                      const SizedBox(height: 10),
                      _buildNarrativeWindow(stressColor),
                      const SizedBox(height: 25), // SPACER YERINE SIZEDBOX
                      _buildPanel(title: "REAKTÖR ÇEKİRDEĞİ", subtitle: "TERMAL STABİLİZASYON GEREKLİ", value: _reactorHealth, color: Colors.orange, icon: Icons.flash_on, system: TriageSystem.reactor),
                      const SizedBox(height: 15),
                      _buildPanel(title: "OKSİJEN REZERVİ", subtitle: "BASINÇ SIZINTISI ALGILANDI", value: _oxygenLevel, color: Colors.cyan, icon: Icons.air, system: TriageSystem.oxygen),
                      const SizedBox(height: 15),
                      _buildPanel(title: "DÜNYA İLE İLETİŞİM", subtitle: "SİNYAL KAYBI: YENİDEN KAZANIM", value: _commsSignal, color: Colors.green, icon: Icons.wifi, system: TriageSystem.comms),
                      const SizedBox(height: 25), // SPACER YERINE SIZEDBOX
                      _buildSystemStatus(stressColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (minHealth < 0.3) IgnorePointer(child: AnimatedBuilder(animation: _stressController, builder: (context, child) { return Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.transparent, Colors.red.withOpacity(_stressController.value * 0.3)], stops: const [0.5, 1.0]))); })),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("BÖLÜM 2: İLK TRİAJ", style: GoogleFonts.rajdhani(color: color, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
          Text("DURUM: ${_isCompleted ? "STABİLİZASYON" : "KRİTİK HATA"}", style: GoogleFonts.sourceCodePro(color: color.withOpacity(0.6), fontSize: 10)),
        ]),
        Text("${_stopwatch.elapsed.inSeconds}s", style: GoogleFonts.sourceCodePro(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNarrativeWindow(Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(4)), child: Text("\"Gemi ölüyor Operatör. Üç sistem de yardımın için bağırıyor. Hangisini önce eline uzatıyorsun?\"", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)));
  }

  Widget _buildPanel({required String title, required String subtitle, required double value, required Color color, required IconData icon, required TriageSystem system}) {
    bool isFocused = _focusedSystem == system;
    return GestureDetector(
      onTapDown: (_) => _setFocus(system),
      onTapUp: (_) => setState(() => _focusedSystem = TriageSystem.none),
      onTapCancel: () => setState(() => _focusedSystem = TriageSystem.none),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isFocused ? color.withOpacity(0.15) : Colors.black.withOpacity(0.4), border: Border.all(color: isFocused ? color : color.withOpacity(0.3), width: isFocused ? 2 : 1), borderRadius: BorderRadius.circular(8), boxShadow: isFocused ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)] : []),
        child: Column(children: [
          Row(children: [
            Icon(icon, color: isFocused ? color : color.withOpacity(0.6), size: 28), const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.rajdhani(color: isFocused ? Colors.white : color.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Text(subtitle, style: GoogleFonts.sourceCodePro(color: color.withOpacity(0.6), fontSize: 9)),
            ])),
            Text("${(value * 100).toInt()}%", style: GoogleFonts.sourceCodePro(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: value, backgroundColor: Colors.white.withOpacity(0.05), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8)),
          if (isFocused) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("ONARILIYOR...", style: GoogleFonts.sourceCodePro(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }

  Widget _buildSystemStatus(Color color) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.warning_amber, color: color, size: 16), const SizedBox(width: 8), Text("TÜM SİSTEMLERİ STABİLİZE ET (%90 ÜZERİ)", style: GoogleFonts.sourceCodePro(color: color, fontSize: 10, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 10),
      Text("ODAĞI SÜREKLİ DEĞİŞTİREREK DENGE KURUN", style: GoogleFonts.rajdhani(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 10, letterSpacing: 2.0)),
    ]));
  }
}
