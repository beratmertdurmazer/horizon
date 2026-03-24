import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/screens/chapter1_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  int _currentScene = 1;
  
  late AnimationController _fadeController;

  String _displayedNarrative = "";
  String _displayedAida = "";
  int _narrativeIndex = 0;
  int _aidaIndex = 0;
  Timer? _typewriterTimer;

  final Map<int, Map<String, String>> _scenes = {
    1: {
      "title": "KARANLIK VE SES",
      "narrative": "Karanlık... Mutlak ve sessiz bir karanlık. Başta nerede olduğunu, hatta kim olduğunu hatırlamıyorsun. Sadece soğuğu hissediyorsun; kemiklerine kadar işleyen, yapay bir kışın soğuğu.",
      "aida": "Bilincin geri yükleniyor, Operatör. Lütfen derin nefes almayı dene. Akciğerlerindeki cryo-sıvısının tahliye edilmesi gerekiyor.",
      "bg": "assets/images/concept_cyber_noir.png",
    },
    2: {
      "title": "UYANIŞ",
      "narrative": "Tüpün kapağı bir tıslama sesiyle açılıyor. İçerideki koruyucu jel zemine boşalırken, sendeleyerek dışarı çıkıyorsun. Yer çekimi, sanki vücudun bu dünyaya ait değilmiş gibi ağır geliyor.",
      "aida": "Burası Eventide İstasyonu. İnsanlığın Dünya dışındaki en uzak karakolu.",
      "bg": "assets/images/concept_cyber_noir_awakening_219348123_1774314851668.png",
    },
    3: {
      "title": "A.I.D.A. İLE TANIŞMA",
      "narrative": "Normalde binlerce personelin koşturması gereken bu koridorlar bomboş. Sadece acil durum aydınlatmalarının donuk kırmızı ışığı duvarlarda titriyor.",
      "aida": "Seni uyandırdığım için özür dilerim, Operatör. İstasyon bir 'Kritik Sistem Arızası' döngüsüne girdi. 400 mürettebat hâlâ cryo-uykusunda.",
      "bg": "assets/images/concept_cyber_noir_aida_328491231_1774314865905.png",
    },
    4: {
      "title": "İLK ADIM",
      "narrative": "Sen sadece bir 'çalışan' değilsin. Şu an bu metal yığınının içindeki tek bilinç, tek karar vericisin. 400 canın kaderi, parmak uçlarında.",
      "aida": "Kriz anlarında sistemi yönetecek 'bilişsel kapasitesi ve stres yönetimi en yüksek' kişi olarak sen seçildin. Oyun Başlıyor.",
      "bg": "assets/images/concept_cyber_noir_first_step_423981231231231_1774314880837.png",
    },
  };

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start(); // Initialize and start stopwatch
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    
    // Start the constant Space Hum
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
    });

    _startScene();
  }

  void _startScene() async {
    _displayedNarrative = "";
    _displayedAida = "";
    _narrativeIndex = 0;
    _aidaIndex = 0;
    _fadeController.reset();
    _fadeController.forward();
    
    if (_currentScene == 1) AudioService().playHeartbeat();
    if (_currentScene == 2) AudioService().playVacuumHiss();

    _startTypewriter();
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    final scene = _scenes[_currentScene]!;
    
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_narrativeIndex < scene["narrative"]!.length) {
          _displayedNarrative += scene["narrative"]![_narrativeIndex];
          _narrativeIndex++;
          // No sound for narrative
        } else if (_aidaIndex < scene["aida"]!.length) {
          _displayedAida += scene["aida"]![_aidaIndex];
          _aidaIndex++;
          AudioService().playTypingBeep(); // Beep only for A.I.D.A
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _nextScene() async {
    final scene = _scenes[_currentScene]!;
    if (_narrativeIndex < scene["narrative"]!.length || _aidaIndex < scene["aida"]!.length) {
      setState(() {
        _displayedNarrative = scene["narrative"]!;
        _displayedAida = scene["aida"]!;
        _narrativeIndex = scene["narrative"]!.length;
        _aidaIndex = scene["aida"]!.length;
      });
      _typewriterTimer?.cancel();
      return;
    }

    if (_currentScene < _scenes.length) {
      setState(() => _currentScene++);
      _startScene();
    } else {
      _finishIntro();
    }
  }

  void _finishIntro() {
    _stopwatch.stop(); // Stop the stopwatch
    PersonaMR().logChapterMetrics(
      chapterId: "INTRO_SEQUENCE",
      totalTimeMs: _stopwatch.elapsedMilliseconds,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Chapter1Screen()),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_currentScene]!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _nextScene,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Sequence specific Background
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                child: Image.asset(
                  scene["bg"]!,
                  key: ValueKey(_currentScene),
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.85), // Very dark background
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
            
            // Text Layer
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeController,
                      child: Text(
                        scene["title"]!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.neonCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        _displayedNarrative,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.8,
                          fontStyle: FontStyle.italic,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                      ),
                    ),
                    if (_displayedAida.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: const Border(left: BorderSide(color: AppTheme.neonCyan, width: 3)),
                          color: AppTheme.neonCyan.withOpacity(0.08),
                        ),
                        child: Text(
                          "A.I.D.A: \"$_displayedAida\"",
                          style: GoogleFonts.sourceCodePro(
                            color: AppTheme.neonCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                    if (_narrativeIndex >= scene["narrative"]!.length)
                      FadeTransition(
                        opacity: _fadeController,
                        child: Text(
                          "DEVAM ETMEK İÇİN DOKUN",
                          style: GoogleFonts.rajdhani(
                            color: Colors.white30,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Scanline / CRT Effect
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
