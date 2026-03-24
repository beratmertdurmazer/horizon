import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/screens/chapter1_screen.dart';
import 'package:horizon_protocol/services/audio_service.dart';

class NarrativeScreen extends StatefulWidget {
  const NarrativeScreen({super.key});

  @override
  State<NarrativeScreen> createState() => _NarrativeScreenState();
}

class _NarrativeScreenState extends State<NarrativeScreen> {
  int _currentSceneIndex = 0;
  String _displayedText = "";
  Timer? _timer;
  bool _isTyping = false;
  bool _isStarted = false; 
  bool _hasStartedAmbient = false;

  final List<Map<String, dynamic>> _scenes = [
    {
      "title": "Sahne 1: Karanlık ve Ses",
      "text": "Karanlık... Mutlak ve sessiz bir karanlık. Başta nerede olduğunu, hatta kim olduğunu hatırlamıyorsun. Sadece soğuğu hissediyorsun; kemiklerine kadar işleyen, yapay bir kışın soğuğu.\n\nArdından bir ses duyuluyor. Kadın sesine benzeyen ama fazla pürüzsüz, fazla hatasız bir tını. Mekanik bir şefkatle fısıldıyor:\n\n— 'Bilincin geri yükleniyor, Operatör. Lütfen derin nefes almayı dene. Akciğerlerindeki cryo-sıvısının tahliye edilmesi gerekiyor.'",
      "visual": Colors.black,
      "glow": AppTheme.neonCyan,
      "image": "concept_cyber_noir_1774313728413.png",
    },
    {
      "title": "Sahne 2: Uyanış",
      "text": "Tüpün kapağı bir tıslama sesiyle açılıyor. İçerideki koruyucu jel zemine boşalırken, sendeleyerek dışarı çıkıyorsun. Dizlerin üzerine çöküyorsun; yer çekimi vücuduna ağır geliyor.\n\nBurası Eventide İstasyonu. İnsanlığın Dünya dışındaki en uzak karakolu.\n\nEtrafına bakıyorsun. Ana koridorun devasa pencerelerinden dışarıdaki mutlak boşluk görünüyor. Ancak bir terslik var. Normalde binlerce personelin koşturması gereken bu koridorlar bomboş. Sadece acil durum aydınlatmalarının donuk kırmızı ışığı duvarlarda titriyor.",
      "visual": const Color(0xFF1A1A1A),
      "glow": Colors.redAccent,
      "image": "concept_cyber_noir_awakening_219348123_1774314851668.png",
    },
    {
      "title": "Sahne 3: A.I.D.A. ile Tanışma",
      "text": "En yakındaki terminal ekranı aniden aydınlanır. Mavi, geometrik bir dalga formu ekranda süzülmeye başlar. Bu, istasyonun yapay zekası A.I.D.A.'dır.\n\n(A.I.D.A.): \"Seni uyandırdığım için özür dilerim, Operatör. Normal şartlarda 47 yıl daha uyuman gerekiyordu. Ancak istasyon bir 'Kritik Sistem Arızası' döngüsüne girdi.\n\nŞu an gemideki 400 mürettebat hâlâ cryo-uykusunda. Eğer sistemleri 15 dakika içinde stabilize edemezsek, yaşam destek üniteleri enerjiyi kesecek. İstasyonun kalbi, ana reaktör can çekişiyor.\"",
      "visual": const Color(0xFF0B121E),
      "glow": AppTheme.neonCyan,
      "image": "concept_cyber_noir_aida_fps_928131231_1774314955052.png",
    },
    {
      "title": "Sahne 4: İlk Adım",
      "text": "A.I.D.A. haklı. Metalik bir yanık kokusu burnuna gelmeye başladı bile. Uzaklardan gelen alarm sirenleri, sessizliği bir bıçak gibi kesiyor.\n\nSen sadece bir 'çalışan' değilsin. Şu an bu metal yığınının içindeki tek bilinç, tek karar vericisin. 400 canın kaderi, birazdan o terminale dokunacak olan parmak uçlarında.\n\nDerin bir nefes alıyorsun. Soğuk hava ciğerlerini yakıyor. İlk kontrol paneline doğru yürümeye başlıyorsun.\n\nOyun Başlıyor.",
      "visual": Colors.black,
      "glow": AppTheme.neonPurple,
      "image": "concept_cyber_noir_first_step_fps_123981231_1774314971208.png",
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  void _startTyping() {
    if (_timer != null) _timer!.cancel();
    
    setState(() {
      _displayedText = "";
      _isTyping = true;
    });

    int charIndex = 0;
    String fullText = _scenes[_currentSceneIndex]["text"];
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (charIndex < fullText.length) {
        setState(() {
          _displayedText += fullText[charIndex];
          charIndex++;
        });
        if (charIndex % 3 == 0) AudioService().playTypingBeep();
      } else {
        _timer?.cancel();
        setState(() => _isTyping = false);
      }
    });
  }

  void _handleInteraction() {
    if (!_isStarted) {
      setState(() => _isStarted = true);
      _startTyping();
      if (!_hasStartedAmbient) {
         AudioService().playAmbientLoop();
         _hasStartedAmbient = true;
      }
      return;
    }

    if (_isTyping) {
      _timer?.cancel();
      setState(() {
        _displayedText = _scenes[_currentSceneIndex]["text"];
        _isTyping = false;
      });
    } else if (_currentSceneIndex < _scenes.length - 1) {
      setState(() {
        _currentSceneIndex++;
      });
      _startTyping();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Chapter1Screen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var scene = _scenes[_currentSceneIndex];
    Color glowColor = scene["glow"] as Color;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _handleInteraction,
        child: Stack(
          children: [
            // Background Image
            if (scene["image"] != null)
              Positioned.fill(
                child: Image.asset(
                  "images/${scene["image"]}",
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.6),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            
            // Terminal Window
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SYSTEM STATUS: ${_isStarted ? "READY" : "WAITING"}",
                          style: GoogleFonts.rajdhani(
                            color: glowColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          "A.I.D.A. v4.2",
                          style: GoogleFonts.rajdhani(
                            color: glowColor.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: glowColor.withOpacity(0.2)),
                    const SizedBox(height: 30),
                    
                    // Main Terminal Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.90),
                          border: Border.all(color: glowColor.withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(top: 0, left: 0, child: _buildCorner(glowColor, 0)),
                            Positioned(top: 0, right: 0, child: _buildCorner(glowColor, 1)),
                            Positioned(bottom: 0, left: 0, child: _buildCorner(glowColor, 2)),
                            Positioned(bottom: 0, right: 0, child: _buildCorner(glowColor, 3)),
                            
                            if (!_isStarted)
                               Center(
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Icon(Icons.power_settings_new, color: glowColor, size: 48),
                                     const SizedBox(height: 20),
                                     Text(
                                       "[ DOKUN VE SİSTEMİ BAŞLAT ]",
                                       style: GoogleFonts.rajdhani(
                                         color: glowColor,
                                         fontSize: 16,
                                         fontWeight: FontWeight.bold,
                                         letterSpacing: 4.0,
                                       ),
                                     ),
                                   ],
                                 ),
                               )
                            else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.chevron_right, color: glowColor, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      scene["title"].toString().toUpperCase(),
                                      style: GoogleFonts.rajdhani(
                                        color: glowColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 3.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _displayedText,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textMain.withOpacity(0.95),
                                        fontSize: 16,
                                        height: 1.8,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    if (_isStarted && !_isTyping)
                      Center(
                        child: Text(
                          ">> SONRAKİ SAHNE İÇİN DOKUN <<",
                          style: GoogleFonts.rajdhani(
                            color: glowColor.withOpacity(0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Color color, int type) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        border: Border(
          top: type < 2 ? BorderSide(color: color, width: 3) : BorderSide.none,
          bottom: type >= 2 ? BorderSide(color: color, width: 3) : BorderSide.none,
          left: type % 2 == 0 ? BorderSide(color: color, width: 3) : BorderSide.none,
          right: type % 2 != 0 ? BorderSide(color: color, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
