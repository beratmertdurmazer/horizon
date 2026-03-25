import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/services/persona_mr.dart';
import 'package:horizon_protocol/screens/intro_screen.dart';
import 'package:horizon_protocol/screens/admin_dashboard_screen.dart';
import 'package:horizon_protocol/utils/string_extensions.dart';

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

  void _showAdminLoginDialog() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: BorderSide(color: AppTheme.neonCyan)),
        title: Text("ADMIN YETKİLENDİRMESİ", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("LÜTFEN ERİŞİM KODUNU GİRİNİZ", style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              style: GoogleFonts.sourceCodePro(color: Colors.white),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
                hintText: "PIN",
                hintStyle: GoogleFonts.sourceCodePro(color: Colors.white10),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İPTAL", style: GoogleFonts.rajdhani(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text == "1234") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
              } else {
                AudioService().playStaticBurst();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("YETKİSİZ ERİŞİM: HATALI PIN", style: GoogleFonts.sourceCodePro())),
                );
              }
            },
            child: Text("GİRİŞ", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                    const SizedBox(height: 40),

                    // ADMIN ACCESS (DISCREET)
                    Opacity(
                      opacity: 0.3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _showAdminLoginDialog,
                            child: Text(
                              "// GİZLİ ANALİZ PANELİ //",
                              style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 9, letterSpacing: 2),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _showClinicalAssessmentLoginDialog,
                            child: Text(
                              "// KLİNİK DEĞERLENDİRME VERİLERİ //",
                              style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 9, letterSpacing: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
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

  void _showClinicalAssessmentLoginDialog() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: BorderSide(color: AppTheme.neonCyan)),
        title: Text("KLİNİK VERİ ERİŞİMİ", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("LÜTFEN YETKİLİ ERİŞİM KODUNU GİRİNİZ", style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              style: GoogleFonts.sourceCodePro(color: Colors.white),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
                hintText: "PIN",
                hintStyle: GoogleFonts.sourceCodePro(color: Colors.white10),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İPTAL", style: GoogleFonts.rajdhani(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text == "1234") {
                Navigator.pop(context);
                _showClinicalPresentation();
              } else {
                AudioService().playStaticBurst();
                Navigator.pop(context);
              }
            },
            child: Text("DOĞRULA", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showClinicalPresentation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(side: BorderSide(color: AppTheme.neonCyan.withOpacity(0.5))),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "KLİNİK DEĞERLENDİRME ANALİZİ",
                      style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _clinicalChapters.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) => _buildChapterCard(_clinicalChapters[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> ch) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BÖLÜM ${ch['id']}: ${ch['title']}",
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (ch['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: (ch['color'] as Color).withOpacity(0.3)),
                ),
                child: Text(
                  ch['iq_type'].toString().toTurkishUpperCase(),
                  style: GoogleFonts.sourceCodePro(color: ch['color'], fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildDetailRow("Sahne", ch['scene']),
          _buildDetailRow("Amaç", ch['purpose']),
          _buildDetailRow("Mekanik", ch['mechanic']),
          _buildDetailRow("Psikometrik", ch['psychometric']),
          _buildDetailRow("Psikolojik Veri", ch['metrics']),
          _buildDetailRow("Analiz Çıktısı", ch['outcome']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.sourceCodePro(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _clinicalChapters = [
    {
      "id": "1",
      "title": "Soğuk Uyanış",
      "iq_type": "Akıcı Zeka",
      "color": Colors.cyanAccent,
      "scene": "Issız, karanlık uzay istasyonu koridoru ve sistem sesleri.",
      "purpose": "Kriz anında bilişsel kaynakları aktive etme ve örüntü yakalama.",
      "mechanic": "Alfanümerik Pattern Bulmaca",
      "psychometric": "Kriz Yönetimi, Hızlı Adaptasyon, Sayısal Muhakeme.",
      "metrics": "errorCount, durationMs, timeToFirstClick",
      "outcome": "Bilişsel Sosyalizasyon & Örüntü Tanıma"
    },
    {
      "id": "2",
      "title": "Triage",
      "iq_type": "Sistem Zekası",
      "color": Colors.orangeAccent,
      "scene": "Duman altındaki enerji kontrol odası, kısıtlı enerji kaynağı.",
      "purpose": "Kurumsal bekâ ile insani empati arasındaki dengeyi ölçmek.",
      "mechanic": "Kaynak Tahsisi Seçimi",
      "psychometric": "Stratejik Karar Alma, Kurumsal Sadakat, Kaynak Yönetimi.",
      "metrics": "choiceId, switch_count, focus_order, final_levels",
      "outcome": "Stratejik Önceliklendirme"
    },
    {
      "id": "3",
      "title": "Parazitler",
      "iq_type": "Seçici Dikkat",
      "color": Colors.redAccent,
      "scene": "Veri terminali ekranı ve aniden fırlayan parazit pencereler.",
      "purpose": "Ana işe odaklanırken çevresel gürültüyü (noise) filtreleme.",
      "mechanic": "Sembol Eşleştirme + Pop-up Noise",
      "psychometric": "Odaklanma Kapasitesi, Hata Toleransı, Detay Dikkat.",
      "metrics": "reactionTime, tile_flips, box_closing_strategy, symbolMatchErrors",
      "outcome": "Çeldirici Zafiyeti & KPI: Minimum Süre"
    },
    {
      "id": "4",
      "title": "Kritik Yol",
      "iq_type": "Etik Zeka",
      "color": Colors.amberAccent,
      "scene": "Karanlık asansör boşluğu veya robotik laboratuvar girişi.",
      "purpose": "Zorlayıcı şartlarda felsefi/stratejik tutarlılık testi.",
      "mechanic": "Fiziksel Yol Ayrımı (Bölüm 2 Uzantısı)",
      "psychometric": "Karar Tutarlılığı, Öz-Disiplin ve Integrity.",
      "metrics": "choiceConsistency",
      "outcome": "Söylem-Eylem Tutarlılığı"
    },
    {
      "id": "5",
      "title": "Erişim",
      "iq_type": "İşleyen Bellek",
      "color": Colors.purpleAccent,
      "scene": "Kırmızı geri sayım barı eşliğinde kilitli kapı terminali.",
      "purpose": "Zaman kısıtı altında metin analiz hızı ve şifre çözümü.",
      "mechanic": "Kısıtlı Sürede Metin Analizi",
      "psychometric": "Zaman Yönetimi, Analitik Taramacılık, Bilişsel Yük.",
      "metrics": "failedAttempts, readingTime, durationMs",
      "outcome": "Baskı Altında Bilgi İşleme"
    },
    {
      "id": "6",
      "title": "Kaos",
      "iq_type": "Duygu Düzenleme",
      "color": Colors.deepOrangeAccent,
      "scene": "Siren sesleri, ekran titremesi ve sahte hata mesajları.",
      "purpose": "Kaosun ortasında en rasyonel ve basit adımı bulabilme.",
      "mechanic": "Sahte Alarmlar & UI Gürültüsü",
      "psychometric": "Duygusal Dayanıklılık (Resilience), Panik Yönetimi.",
      "metrics": "panic_clicks, mutingSpeed",
      "outcome": "Stres Altında Soğukkanlılık"
    },
    {
      "id": "7",
      "title": "Binary Code",
      "iq_type": "Pratik Zeka",
      "color": Colors.blueAccent,
      "scene": "Donmuş ekran üzerinde akan 0 ve 1 veri şeridi.",
      "purpose": "Dış kaynakları kullanarak hızlı araştırma, öğrenme ve uygulama.",
      "mechanic": "Harici Kaynaklardan Şifre Çözümü",
      "psychometric": "Öğrenme Çevikliği (Learning Agility), Araştırmacılık.",
      "metrics": "durationMs, errorCount",
      "outcome": "Kaynak Kullanımı (Süre 2. plandadır)"
    },
    {
      "id": "8",
      "title": "Sızıntı",
      "iq_type": "Yürütücü İşlevler",
      "color": Colors.lightBlueAccent,
      "scene": "Basıncın düştüğü ve hava sızıntısı olan geçit koridoru.",
      "purpose": "Can güvenliği riski anında prosedürlere sadakat ölçümü.",
      "mechanic": "Protokol vs İnsani Yardım",
      "psychometric": "Prosedür Uyumu, Öz-Koruma vs. Risk Alma.",
      "metrics": "choiceId, reactionTime",
      "outcome": "Baskı Altında Protokol Sadakati"
    },
    {
      "id": "9",
      "title": "Enkaz",
      "iq_type": "İçsel Zeka",
      "color": Colors.tealAccent,
      "scene": "Hasarın raporlanması gereken sessiz ve teknik terminal odası.",
      "purpose": "Hatanın sorumluluğunu kime/neye atadığını saptamak.",
      "mechanic": "Kriz Sonrası Raporlama",
      "psychometric": "Hesap Verebilirlik (Accountability), Özyeterlilik.",
      "metrics": "choiceId",
      "outcome": "Öz-Farkındalık & Sorumluluk"
    },
    {
      "id": "10-11",
      "title": "Tartışma",
      "iq_type": "Sosyal Zeka",
      "color": Colors.greenAccent,
      "scene": "Dönüş yolunda kokpitteki AI modülleri çatışması.",
      "purpose": "Çatışma anında otoriterleşme vs. uzlaşı arama eğilimi.",
      "mechanic": "IA vs Empati Seçimi",
      "psychometric": "Müzakere Becerileri, Takım Yönetimi, Demokratik Liderlik.",
      "metrics": "choiceId, negotiationSteps, finalAgreement",
      "outcome": "Çatışma Çözümü & Liderlik Stili"
    },
    {
      "id": "12",
      "title": "Müdahale",
      "iq_type": "Kişilerarası IQ",
      "color": Colors.pinkAccent,
      "scene": "Partner modülün kritik hata yaptığı dijital arayüz.",
      "purpose": "Partner hatasına karşı cezalandırıcı vs. geliştirici tepki.",
      "mechanic": "Partner Hatası Yönetimi",
      "psychometric": "Psikolojik Güvenlik, Mentorluk, Delegasyon Etiği.",
      "metrics": "choiceId, forgiveDelay, selection",
      "outcome": "Psikolojik Güvenlik İnşası"
    },
    {
      "id": "13",
      "title": "Final",
      "iq_type": "Organizasyonel Zeka",
      "color": Colors.indigoAccent,
      "scene": "Sistemlerin finalize edildiği görkemli final ekranı.",
      "purpose": "Tüm kontrolü elde tutma vs. delege ederek yetkilendirme.",
      "mechanic": "Görev Devri (Self vs Delegate)",
      "psychometric": "Güven İnşası, Stratejik Yetkilendirme.",
      "metrics": "choiceId, readDuration, delegationRatio, finalDecision",
      "outcome": "Delegasyon & Yetkilendirme"
    },
  ];

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
        const SizedBox(height: 10),
        Text(
          "KPI NOTU: BÖLÜM 1, 3, 5 İÇİN MİNİMUM SÜRE KRİTİKTİR. BÖLÜM 7'DE SEÇİM KALİTESİ ÖNCELİKLİDİR.",
          style: GoogleFonts.sourceCodePro(color: Colors.amberAccent.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.bold),
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
