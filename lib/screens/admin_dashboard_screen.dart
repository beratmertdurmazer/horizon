import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/models/game_models.dart';
import 'package:horizon_protocol/services/database_service.dart';
import 'package:horizon_protocol/services/assessment_engine.dart';
import '../utils/string_extensions.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final AssessmentEngine _engine = AssessmentEngine();
  
  List<Candidate> _candidates = [];
  Candidate? _selectedCandidate;
  List<Decision> _selectedDecisions = [];
  List<ChapterMetric> _selectedMetrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      final list = await _db.getAllCandidates();
      setState(() {
        _candidates = list;
        if (list.isNotEmpty && _selectedCandidate == null) {
          _selectCandidate(list.first);
        }
      });
    } catch (e) {
      debugPrint("DB_LOAD_ERROR: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCandidate(Candidate c) async {
    setState(() {
      _selectedCandidate = c;
      _isLoading = true;
    });
    
    try {
      final decisions = await _db.getDecisionsForCandidate(c.id);
      final metrics = await _db.getMetricsForCandidate(c.id);
      
      setState(() {
        _selectedDecisions = decisions..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _selectedMetrics = metrics..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: isMobile ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.neonCyan),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ) : null,
        title: Text(
          "HORIZON ADMIN PANEL // ANALİZ_MERKEZİ",
          style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            tooltip: "Demo Verisi Üret",
            icon: const Icon(Icons.add_chart, color: AppTheme.neonCyan),
            onPressed: () async {
              await _db.seedMockData();
              _loadCandidates();
            },
          ),
          IconButton(
            tooltip: "Tüm Verileri Temizle",
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: () => _confirmClearAll(),
          ),
          IconButton(
            tooltip: "Yenile",
            icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
            onPressed: _loadCandidates,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.neonCyan.withOpacity(0.3), height: 1),
        ),
      ),
      drawer: isMobile ? Drawer(
        backgroundColor: Colors.black,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.neonCyan.withOpacity(0.2)))),
              child: Center(
                child: Text("ADAY LİSTESİ", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(child: _buildSidebarContents()),
          ],
        ),
      ) : null,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
        : _candidates.isEmpty 
          ? _buildEmptyState()
          : Row(
              children: [
                if (!isMobile) _buildSidebar(),
                
                Expanded(
                  child: _selectedCandidate == null 
                    ? const Center(child: Text("BİR ADAY SEÇİNİZ", style: TextStyle(color: Colors.white24)))
                    : _buildAnalyticsDashboard(isMobile),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storage_outlined, size: 64, color: Colors.white12),
          const SizedBox(height: 20),
          Text("VERİTABANI BOŞ", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 18)),
          Text("HENÜZ TAMAMLANMIŞ TEST BULUNAMADI", style: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 12)),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () async {
              await _db.seedMockData();
              _loadCandidates();
            },
            child: Text(
              "// DEMO VERİSİ ÜRET //",
              style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: _buildSidebarContents(),
    );
  }

  Widget _buildSidebarContents() {
    return ListView.builder(
      itemCount: _candidates.length,
      itemBuilder: (context, index) {
        final c = _candidates[index];
        final isSelected = _selectedCandidate?.id == c.id;
        return ListTile(
          tileColor: isSelected ? AppTheme.neonCyan.withOpacity(0.05) : Colors.transparent,
          title: Text(c.name.toUpperCase(), style: GoogleFonts.rajdhani(color: isSelected ? AppTheme.neonCyan : Colors.white70, fontWeight: FontWeight.bold)),
          subtitle: Text(c.position, style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white24),
            onPressed: () => _confirmDelete(c),
          ),
          onTap: () {
            _selectCandidate(c);
            if (MediaQuery.of(context).size.width < 900) Navigator.pop(context);
          },
        );
      },
    );
  }

  void _confirmDelete(Candidate c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text("ADAYI SİL?", style: GoogleFonts.rajdhani(color: Colors.redAccent)),
        content: Text("${c.name} isimli adayı ve tüm verilerini silmek istediğinize emin misiniz?", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL", style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () async {
              await _db.deleteCandidate(c.id);
              Navigator.pop(context);
              _loadCandidates();
              if (_selectedCandidate?.id == c.id) setState(() => _selectedCandidate = null);
            }, 
            child: const Text("SİL", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text("TÜM VERİLERİ TEMİZLE?", style: GoogleFonts.rajdhani(color: Colors.redAccent)),
        content: Text("Tüm aday kayıtları ve test verileri kalıcı olarak silinecektir. Emin misiniz?", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL", style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () async {
              await _db.clearDatabase();
              Navigator.pop(context);
              _loadCandidates();
              setState(() => _selectedCandidate = null);
            }, 
            child: const Text("HER ŞEYİ SİL", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsDashboard(bool isMobile) {
    if (_selectedCandidate == null) return const SizedBox();
    
    // Anlık analiz verileri
    final scores = _engine.calculateScores(_selectedDecisions, _selectedMetrics);
    final flags = _engine.generateFlags(_selectedDecisions, _selectedMetrics);
    final archetype = _engine.getLeadershipArchetype(scores['leadership_impact'] ?? 0, scores['strategic_prioritization'] ?? 0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCandidateHero(isMobile, scores, archetype),
          const SizedBox(height: 25),
          
          // YENİ: YÖNETİCİ ÖZETİ
          _buildExecutiveSummary(scores, flags),
          const SizedBox(height: 40),
          
          if (isMobile) ...[
            _buildCrisisGauge(scores),
            const SizedBox(height: 30),
            _buildTeamDynamicsRadar(scores),
            const SizedBox(height: 30),
            _buildEfficiencyBar(scores),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCrisisGauge(scores)),
                const SizedBox(width: 20),
                Expanded(child: _buildTeamDynamicsRadar(scores)),
                const SizedBox(width: 20),
                Expanded(child: _buildEfficiencyBar(scores)),
              ],
            ),
          
          const SizedBox(height: 40),
          _buildFlagsSection(flags),
          
          const SizedBox(height: 40),
          _buildDetailedAnalysis(),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Back to left-aligned
      children: [
        Text("DETAYLI BÖLÜM ANALİZİ", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedMetrics.length,
          itemBuilder: (context, index) {
            final metric = _selectedMetrics[index];
            final chapterDecisions = _selectedDecisions.where((d) => d.chapterId == metric.chapterId).toList();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                color: Colors.white.withOpacity(0.02),
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(metric.chapterId.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("${(metric.totalTimeMs / 1000).toStringAsFixed(1)} Saniye", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10)),
                  ],
                ),
                children: [
                  const Divider(color: Colors.white10, height: 20),
                  if (chapterDecisions.isNotEmpty) ...[
                    Text("ANA KARARLAR", 
                      textAlign: TextAlign.left,
                      style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ...chapterDecisions.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SEÇİM: ${_translateChoice(d.choiceId).toTurkishUpperCase()}", 
                            textAlign: TextAlign.left,
                            style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 5,
                            children: d.triggers.map((t) => Text("#$t", style: GoogleFonts.sourceCodePro(color: Colors.blueAccent.withOpacity(0.5), fontSize: 9))).toList(),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 15),
                  ],
                  
                  // KLİNİK ANALİZ METRİKLERİ
                  _buildClinicalMetrics(metric.additionalData),
                  const SizedBox(height: 25),
                  
                  // ETKİLEŞİM ZAMAN ÇİZELGESİ (TIMELINE)
                  Text("ETKİLEŞİM ZAMAN ÇİZELGESİ", 
                    textAlign: TextAlign.left,
                    style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildTimeline(metric.additionalData?['timeline'] as List?),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClinicalMetrics(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const SizedBox();
    
    // Summary metrics, excluding timeline
    final metrics = data.entries.where((e) => e.key != 'timeline').toList();
    if (metrics.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("KLİNİK ANALİZ METRİKLERİ", 
          textAlign: TextAlign.left,
          style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 15,
          runSpacing: 10,
          children: metrics.map((e) {
            final value = e.value;
            String displayValue = value.toString();
            
            // Format specific complex types (like maps in Triage levels)
            if (value is Map) {
              displayValue = value.entries.map((v) => "${_translateMetadata(v.key.toString())}: %${v.value}").join(", ");
            } else if (value is List) {
              displayValue = "[${value.map((v) => _translateMetadata(v.toString())).join(", ")}]";
            } else if (value is int && (e.key.toLowerCase().contains("time") || e.key.toLowerCase().contains("duration") || e.key.toLowerCase().contains("speed") || e.key.toLowerCase().contains("delay"))) {
               displayValue = "${(value / 1000).toStringAsFixed(2)}s";
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: Colors.white.withOpacity(0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(_translateMetricKey(e.key), style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 8)),
                   const SizedBox(height: 2),
                   Text(displayValue, style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _translateMetricKey(String key) {
    switch (key) {
      case 'errorCount': return 'Hata Sayısı';
      case 'durationMs': return 'Toplam Süre';
      case 'timeToFirstClick': return 'İlk Karar Hızı';
      case 'switch_count': return 'Sistem Geçiş Sayısı';
      case 'final_levels': return 'Final Sistem Seviyeleri';
      case 'focus_order': return 'Öncelik Sıralaması';
      case 'missedPopups': return 'Kaçırılan Uyarılar';
      case 'symbolMatchErrors': return 'Eşleştirme Hataları';
      case 'failedAttempts': return 'Hatalı Denemeler';
      case 'readingTime': return 'Okuma/Analiz Süresi';
      case 'mutingSpeed': return 'Susturma Refleksi';
      case 'reactionTime': return 'Reaksiyon Süresi';
      case 'actionDelay': return 'Eylem Gecikmesi';
      case 'tile_flips': return 'Kutu Çevirme Sayısı';
      case 'box_closing_strategy': return 'Kutu Kapama Stratejisi';
      case 'missedPopups': return 'Kaçırılan Uyarılar';
      case 'symbolMatchErrors': return 'Eşleştirme Hataları';
      case 'negotiationSteps': return 'Müzakere Adımı';
      case 'finalAgreement': return 'Uzlaşı Sonucu';
      case 'forgiveDelay': return 'Karar Ağırlığı/Gecikmesi';
      case 'delegationRatio': return 'Yetki Devri Oranı';
      case 'readDuration': return 'Metin İnceleme Süresi';
      default: return key.replaceAll('_', ' ').toTurkishUpperCase();
    }
  }

  Widget _buildCandidateHero(bool isMobile, Map<String, double> scores, String archetype) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        gradient: LinearGradient(colors: [AppTheme.neonCyan.withOpacity(0.05), Colors.transparent]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCandidateInfo(archetype),
          if (!isMobile) _buildMiniScore(scores['consistency_index'] ?? 0, "TUTARLILIK"),
        ],
      ),
    );
  }

  Widget _buildCandidateInfo(String archetype) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ADAY_KODU: ${_selectedCandidate!.id}", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10)),
        Text(_selectedCandidate!.name.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text("DURUM: ANALİZ TAMAMLANDI // ARKETİP: $archetype", 
          style: GoogleFonts.sourceCodePro(color: Colors.white30, fontSize: 10)),
      ],
    );
  }

  Widget _buildMiniScore(double score, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("${score.toInt()}%", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 8)),
      ],
    );
  }

  Widget _buildCrisisGauge(Map<String, double> scores) {
    final score = scores['stress_resilience'] ?? 0;
    final color = score > 70 ? Colors.greenAccent : (score > 40 ? Colors.orangeAccent : Colors.redAccent);
    
    return Container(
      height: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("KRİZ YÖNETİMİ", style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              const Icon(Icons.bolt, color: Colors.white10, size: 12),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: score, color: color, radius: 12, showTitle: false),
                      PieChartSectionData(value: 100 - score, color: Colors.white.withOpacity(0.05), radius: 12, showTitle: false),
                    ],
                    startDegreeOffset: 270,
                    centerSpaceRadius: 55,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${score.toInt()}%", style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                    Text("SÜKUNET", style: GoogleFonts.sourceCodePro(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(4)),
            child: Text("HATA TOPARLANMA: ${score > 60 ? '0.8s' : '2.4s'}", 
              style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDynamicsRadar(Map<String, double> scores) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TAKIM DİNAMİĞİ", style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              const Icon(Icons.people_outline, color: Colors.white10, size: 12),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: RadarChart(
              RadarChartData(
                titlePositionPercentageOffset: 0.18,
                dataSets: [
                  RadarDataSet(
                    fillColor: Colors.purpleAccent.withOpacity(0.15),
                    borderColor: Colors.purpleAccent,
                    entryRadius: 3,
                    borderWidth: 2,
                    dataEntries: [
                      RadarEntry(value: scores['team_impact'] ?? 30),
                      RadarEntry(value: scores['feedback_score'] ?? 40),
                      RadarEntry(value: scores['initiative_score'] ?? 30),
                      RadarEntry(value: scores['trust_score'] ?? 50),
                    ],
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                gridBorderData: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                radarBorderData: const BorderSide(color: Colors.transparent),
                tickBorderData: const BorderSide(color: Colors.transparent),
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                getTitle: (index, angle) {
                  // Inisiyatif (bottom label) ters yazılmasın diye 180 derece olduğu durumda düzeltiyoruz
                  final double adjustedAngle = (angle > 90 && angle < 270) ? angle + 180 : angle;
                  return RadarChartTitle(
                    text: _getRadarLabel(index), 
                    angle: adjustedAngle,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildRadarLegend(),
        ],
      ),
    );
  }

  String _getRadarLabel(int index) {
    switch (index) {
      case 0: return 'ETKİ';
      case 1: return 'GERİ BİLDİRİM';
      case 2: return 'İNİSİYATİF';
      case 3: return 'GÜVEN';
      default: return '';
    }
  }

  Widget _buildRadarLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: [
        _buildLegendItem('ETKİ', 'Liderlik ve stratejik kararların kurum üzerindeki ağırlığı.'),
        _buildLegendItem('GERİ BİLDİRİM', 'Diyaloğa açıklık ve öz-eleştiri kapasitesi.'),
        _buildLegendItem('İNİSİYATİF', 'Kriz anında proaktif aksiyon alma hızı.'),
        _buildLegendItem('GÜVEN', 'Yetki devri ve hata toleransı (Delegasyon).'),
      ],
    );
  }

  Widget _buildLegendItem(String label, String description) {
    return Tooltip(
      message: description,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppTheme.neonCyan)),
      textStyle: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(2)),
        child: Text(label, style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEfficiencyBar(Map<String, double> scores) {
    final focus = scores['cognitive_focus'] ?? 0;
    final strategy = scores['strategic_prioritization'] ?? 0;
    
    return Container(
      height: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("VERİMLİLİK ANALİZİ", style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              const Icon(Icons.analytics_outlined, color: Colors.white10, size: 12),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                    tooltipBorder: const BorderSide(color: AppTheme.neonCyan, width: 1),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label = "";
                      String desc = "";
                      if (groupIndex == 0) { label = "ODAK"; desc = "Bilişsel yük altında dikkati koruma ve gürültüyü filtreleme yetisi."; }
                      else if (groupIndex == 1) { label = "STRATEJİ"; desc = "Hedef odaklılık, kaynak yönetimi ve uzun vadeli planlama."; }
                      else { label = "AKIŞ"; desc = "Karar ve eylem arasındaki senkronizasyon ve bilişsel hız."; }
                      return BarTooltipItem(
                        "$label: ${rod.toY.toInt()}%",
                        GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 10),
                      );
                    },
                  ),
                ),
                barGroups: [
                  _buildBarGroup(0, focus, AppTheme.neonCyan),
                  _buildBarGroup(1, strategy, Colors.amberAccent),
                  _buildBarGroup(2, (focus + strategy) / 2, Colors.tealAccent),
                ],
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      getTitlesWidget: (v, m) {
                        final style = GoogleFonts.rajdhani(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold);
                        if (v == 0) return Text("ODAK", style: style);
                        if (v == 1) return Text("STRATEJİ", style: style);
                        return Text("AKIŞ", style: style);
                      }
                    )
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }


  Widget _buildExecutiveSummary(Map<String, double> scores, List<String> flags) {
    final summary = _engine.getExecutiveSummary(scores, flags);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neonCyan.withOpacity(0.05),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppTheme.neonCyan, size: 18),
              const SizedBox(width: 10),
              Text("YÖNETİCİ ÖZETİ & PSİKOLOJİK PROFİL", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagsSection(List<String> flags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DAVRANIŞSAL BULGULAR", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: flags.map((f) {
            final isNegative = f.contains('uyarı') || f.contains('risk') || f.contains('dürtüsel') || f.contains('reaktif');
            return Tooltip(
              message: _getFlagDescription(f),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: isNegative ? Colors.redAccent : Colors.greenAccent)),
              textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: isNegative ? Colors.redAccent.withOpacity(0.5) : Colors.greenAccent.withOpacity(0.5)),
                  color: isNegative ? Colors.redAccent.withOpacity(0.05) : Colors.greenAccent.withOpacity(0.05),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isNegative ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
                      color: isNegative ? Colors.redAccent : Colors.greenAccent, size: 12),
                    const SizedBox(width: 8),
                    Text(f.replaceAll('_', ' ').toTurkishUpperCase(), 
                      style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getFlagDescription(String flag) {
    if (flag.contains('analitik_paralizi')) return "Yoğun stres anında karar verme yetisinde saniye bazlı donma ve aksiyon alamama durumu.";
    if (flag.contains('odak_erozyonu')) return "Çevresel faktörlerin ve 'gürültünün' ana iş odağını ciddi şekilde kesintiye uğratması.";
    if (flag.contains('dürtüsel_karar')) return "Analiz yapmadan, sadece reaksiyon olarak verilen hızlı ve hatalı karar verme eğilimi.";
    if (flag.contains('otoriter_kontrol')) return "Görevleri delege etmek yerine tüm kontrolü kendinde tutma ve mikro-yönetim eğilimi.";
    if (flag.contains('makyavelist')) return "Kurumsal hedefler için etik dengeleri göz ardı edebilme ve pragmatik yaklaşım.";
    if (flag.contains('hizmetkar_liderlik')) return "Ekip üyelerini destekleyen, hataları öğretme fırsatı gören ve psikolojik güvenlik yaratan liderlik.";
    if (flag.contains('stratejik_önceliklendirme_zafiyeti')) return "Kritik sistemler (örn: Reaktör) risk altındayken ikincil konularla vakit kaybetme.";
    if (flag.contains('mükemmeliyetçilik')) return "Tüm kaynakları eşit ve en ideal seviyede tutma çabası; yüksek operasyonel titizlik.";
    if (flag.contains('öz_farkındalık')) return "Hataların sorumluluğunu üstlenme ve içsel denetim mekanizmasının güçlü olması.";
    if (flag.contains('stratejik_sorun_giderme')) return "Minimum deneme ile karmaşık sistem sorunlarını çözme yetisi; yüksek analitik verimlilik.";
    if (flag.contains('deneme_yanılma')) return "Stratejik eleme yerine rastgele denemelerle sonuca gitme eğilimi; düşük operasyonel verimlilik.";
    if (flag.contains('operasyonel_hız_tercihi')) return "Kriz anında tekil işlemler yerine toplu ve hızlı aksiyon alma eğilimi (Bölüm 3).";
    return "Bilimsel telemetriye dayalı davranışsal gözlem saptanmıştır.";
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          width: 30,
          borderRadius: BorderRadius.circular(2),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: Colors.white.withOpacity(0.02),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(List? timeline) {
    if (timeline == null || timeline.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text("Detaylı etkileşim verisi bulunamadı.", style: GoogleFonts.sourceCodePro(color: Colors.white12, fontSize: 9)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: timeline.map((entry) {
        final time = (entry['t'] as int? ?? 0) / 1000.0;
        final action = entry['a'] as String? ?? "Unknown";
        
        // Human readable mapping and coloring
        final String readableAction = _translateTimelineAction(action, entry);
        Color actionColor = Colors.white60; // Default color
        
        if (action.contains("ERROR") || action.contains("FAIL") || action.contains("PANIC") || action.contains("RED_BUTTON") || action.contains("PIN_ERROR")) actionColor = Colors.redAccent;
        else if (action.contains("SUCCESS") || action.contains("GREEN") || action.contains("CHECK") || action.contains("MATCH_FOUND") || action.contains("PIN_SUCCESS")) actionColor = Colors.greenAccent;
        else if (action.contains("CLICK") || action.contains("SELECTION") || action.contains("CHOICE") || action.contains("DECISION") || action.contains("BLUE_BUTTON") || action.contains("CHARACTER_SELECTED")) actionColor = AppTheme.neonCyan;
        else if (action.contains("WARNING") || action.contains("POPUP_SPAWNED") || action.contains("BYPASS")) actionColor = Colors.orange;
        else if (action.contains("FOCUS") || action.contains("MUTED") || action.contains("DIALOGUE") || action.contains("HANDLED_MISTAKE")) actionColor = Colors.teal;
        else if (action.contains("ANALYSIS") || action.contains("KAOS_ACCEPTED")) actionColor = Colors.blue;
        else if (action.contains("REFLECTION")) actionColor = Colors.white70;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 50,
                child: Text("${time.toStringAsFixed(2)}s", 
                  style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan.withOpacity(0.5), fontSize: 9)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(readableAction, 
                  style: GoogleFonts.sourceCodePro(color: actionColor, fontSize: 10)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _translateTimelineAction(String action, Map<String, dynamic> entry) {
    switch (action) {
      case 'STARTED': return 'Simülasyon başlatıldı';
      case 'COMPLETED': return 'Bölüm tamamlandı';
      case 'POPUP_SPAWNED': return '⚠️ Sistem uyarısı çıktı';
      case 'POPUP_CLOSED': return '✅ Uyarı kapatıldı (${entry['reactionTime']}ms)';
      case 'TILE_FLIPPED': return '🔍 Kutu çevrildi (#${entry['id']})';
      case 'BOX_CLOSED': return '📦 Kutu kapatıldı';
      case 'ERROR_CLICK': return '❌ Hatalı deneme saptandı';
      case 'SUCCESS_MATCH': return '🌟 Başarılı eşleşme';
      case 'FINAL_DECISION': return '🏁 Final kararı verildi';
      case 'BYPASS_CLICKED': return '🚨 Bypass butonu ile kriz geçildi';
      case 'PANIC_CLICK': return '😱 Panik tıklaması (Hata #${entry['count']})';
      case 'ALARMS_MUTED': return '🔇 Alarmlar susturuldu (Refah tercihi)';
      case 'KAOS_ACCEPTED': return '📡 Alarmlar kabul edildi (Dikkat tercihi)';
      case 'BLUE_BUTTON_PRESSED': return '🔵 Analitik butona basıldı (#${entry['count']})';
      case 'RED_BUTTON_PRESSED': return '🔴 Dürtüsel butona basıldı';
      case 'REFLECTION_CHOICE': return '💭 Öz-eleştiri yapıldı: ${_translateMetadata(entry['text'] ?? entry['type'] ?? 'Bilinmiyor')}';
      case 'CHARACTER_SELECTED': return '👤 Partner seçildi: ${entry['name']}';
      case 'DIALOGUE_CHOICE': return '💬 Diyalog tercihi: ${entry['collaborative'] == true ? 'İşbirlikçi' : 'Otoriter'}';
      case 'HANDLED_MISTAKE': return '⚖️ Hata yönetimi: ${entry['punitive'] == true ? 'Cezalandırıcı' : 'Affedici'}';
      case 'PIN_ERROR': return '❌ PIN hatası: ${entry['input']}';
      case 'PIN_SUCCESS': return '✅ PIN kodu doğru girildi';
      default: return action;
    }
  }

  String _translateMetadata(String val) {
    switch (val.toLowerCase()) {
      case 'dormitory': return 'Yatakhane';
      case 'lab': return 'Laboratuvar';
      case 'quarters': return 'Yaşam Alanı';
      case 'strategic': return 'Stratejik Entegrasyon';
      case 'empathetic': return 'Empatik Liderlik';
      case 'reactor': return 'Füzyon Reaktörü';
      case 'oxygen': return 'Oksijen Sistemi';
      case 'comms': return 'İletişim Ünitesi';
      case 'internal': return 'İçsel Sorumluluk';
      case 'external': return 'Dışsal Faktörler';
      case 'tile_flips': return 'Kutu Çevirme Sayısı';
      case 'box_closing_strategy': return 'Kutu Kapama Stratejisi';
      case 'failedattempts': return 'Hatalı Giriş Denemesi';
      case 'readingtime': return 'Okuma ve Analiz Süresi';
      case 'errorcount': return 'Hata Sayısı';
      case 'responsedelay': return 'Yanıt Gecikmesi';
      case 'mutingspeed': return 'Susturma Hızı';
      case 'switch_count': return 'Sistem Değiştirme';
      default: return val.toTurkishUpperCase();
    }
  }

  String _translateChoice(String id) {
    switch (id.toLowerCase()) {
      case 'authority_over_ethics': return 'Otorite Odaklı Yaklaşım';
      case 'ethics_over_authority': return 'Etik ve Değer Odaklı';
      case 'delegate_trust': return 'Güven ve Delegasyon';
      case 'self_reliance_control': return 'Bireysel Kontrol ve Denetim';
      case 'punish_food_ration': return 'Cezalandırıcı Strateji';
      case 'forgive_and_cooperate': return 'Affedici ve İşbirlikçi';
      case 'character_selected': return 'Karakter Seçimi Tamamlandı';
      case 'muted': return 'Alarm Susturuldu';
      case 'success': return 'Erişim Başarılı';
      case 'continue': return 'Devam Etme Kararı';
      case 'lab': return 'Laboratuvar Analizi';
      case 'dorm': return 'Yatakhane Güvenliği';
      case 'elara': return 'Elara (Teknik Odak)';
      case 'kael': return 'Kael (Güvenlik Odak)';
      case 'collaborative': return 'Demokratik/Katılımcı';
      case 'authoritarian': return 'Otoriter/Lider Baskın';
      case 'help_others_unprotected': return 'Fedakar/Başkalarına Yardım';
      case 'mask': return 'Bireyici/Önce Kendi Güvenliği';
      case 'skip_analysis': return 'Analizi Atla/Hızlı Geç';
      case 'quarters': return 'Yaşam Alanı Güvenliği';
      case 'reactor': return 'Füzyon Reaktörü Kararı';
      case 'comms': return 'İletişim Ünitesi Kararı';
      case 'oxygen': return 'Oksijen Sistemi Kararı';
      default: return id.replaceAll('_', ' ').toTurkishUpperCase();
    }
  }
}
