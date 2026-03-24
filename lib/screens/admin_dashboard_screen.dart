import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/models/game_models.dart';
import 'package:horizon_protocol/services/database_service.dart';
import 'package:horizon_protocol/services/assessment_engine.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    final list = await _db.getAllCandidates();
    setState(() {
      _candidates = list;
      if (list.isNotEmpty) _selectedCandidate = list.first;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "HORIZON ADMIN PANEL // CORE_ANALYSIS",
          style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
            onPressed: _loadCandidates,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.neonCyan.withOpacity(0.3), height: 1),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
        : _candidates.isEmpty 
          ? _buildEmptyState()
          : Row(
              children: [
                // Sidebar: Candidate List
                _buildSidebar(),
                
                // Main Content: Analytics
                Expanded(
                  child: _selectedCandidate == null 
                    ? const Center(child: Text("ADAY SEÇİNİZ", style: TextStyle(color: Colors.white24)))
                    : _buildAnalyticsDashboard(),
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
          Icon(Icons.storage_outlined, size: 64, color: Colors.white12),
          const SizedBox(height: 20),
          Text("VERİTABANI BOŞ", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 18)),
          Text("HENÜZ TAMAMLANMIŞ TEST BULUNAMADI", style: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 12)),
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
      child: ListView.builder(
        itemCount: _candidates.length,
        itemBuilder: (context, index) {
          final c = _candidates[index];
          final isSelected = _selectedCandidate?.id == c.id;
          return ListTile(
            tileColor: isSelected ? AppTheme.neonCyan.withOpacity(0.05) : Colors.transparent,
            title: Text(c.name.toUpperCase(), style: GoogleFonts.rajdhani(color: isSelected ? AppTheme.neonCyan : Colors.white70, fontWeight: FontWeight.bold)),
            subtitle: Text(c.position, style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
            onTap: () => setState(() => _selectedCandidate = c),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCandidateHero(),
          const SizedBox(height: 40),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildRadarChart()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildScoreCards()),
            ],
          ),
          
          const SizedBox(height: 40),
          _buildFlagsSection(),
          
          const SizedBox(height: 40),
          _buildBarChartSection(),
        ],
      ),
    );
  }

  Widget _buildCandidateHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        gradient: LinearGradient(colors: [AppTheme.neonCyan.withOpacity(0.05), Colors.transparent]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("CANDIDATE_ID: ${_selectedCandidate!.id}", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10)),
              Text(_selectedCandidate!.name.toUpperCase(), style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Text("LEVEL_STATUS: COMPLETED // ARCHETYPE: ${_engine.getLeadershipArchetype(_selectedCandidate!.scores['leadership_impact'] ?? 0, _selectedCandidate!.scores['strategic_prioritization'] ?? 0)}", 
                style: GoogleFonts.sourceCodePro(color: Colors.white30, fontSize: 12)),
            ],
          ),
          _buildGaugeChart(),
        ],
      ),
    );
  }

  Widget _buildScoreCards() {
    final scores = _selectedCandidate!.scores;
    return Column(
      children: [
        _buildScoreItem("COGNITIVE FOCUS", scores['cognitive_focus'] ?? 0, Colors.blue),
        _buildScoreItem("STRATEGIC ALIGNMENT", scores['strategic_prioritization'] ?? 0, Colors.green),
        _buildScoreItem("STRESS RESILIENCE", scores['stress_resilience'] ?? 0, Colors.orange),
        _buildScoreItem("LEADERSHIP IMPACT", scores['leadership_impact'] ?? 0, Colors.purple),
      ],
    );
  }

  Widget _buildScoreItem(String label, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 10)),
              Text("${score.toInt()}%", style: GoogleFonts.rajdhani(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white10,
            color: color,
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeChart() {
    final score = _selectedCandidate!.scores['stress_resilience'] ?? 0;
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(value: score, color: AppTheme.neonCyan, radius: 5, showTitle: false),
                PieChartSectionData(value: 100 - score, color: Colors.white10, radius: 5, showTitle: false),
              ],
              startDegreeOffset: 270,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${score.toInt()}%", style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text("STRESS", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    final scores = _selectedCandidate!.scores;
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02)),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: AppTheme.neonCyan.withOpacity(0.2),
              borderColor: AppTheme.neonCyan,
              entryRadius: 3,
              dataEntries: [
                RadarEntry(value: scores['cognitive_focus'] ?? 0),
                RadarEntry(value: scores['strategic_prioritization'] ?? 0),
                RadarEntry(value: scores['stress_resilience'] ?? 0),
                RadarEntry(value: scores['leadership_impact'] ?? 0),
                RadarEntry(value: 50), // Balance point
              ],
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          gridBorderData: const BorderSide(color: Colors.white10),
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, angle) {
            switch (index) {
              case 0: return const RadarChartTitle(text: 'Cognitive');
              case 1: return const RadarChartTitle(text: 'Strategy');
              case 2: return const RadarChartTitle(text: 'Resilience');
              case 3: return const RadarChartTitle(text: 'Impact');
              default: return const RadarChartTitle(text: '');
            }
          },
        ),
      ),
    );
  }

  Widget _buildFlagsSection() {
    final flags = _selectedCandidate!.behavioralFlags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("BEHAVIORAL_FLAGS", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: flags.map((f) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Text(f.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.sourceCodePro(color: Colors.white70, fontSize: 10)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CHAPTER_TIMELINE (ms)", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: [
                _buildBarGroup(0, 45000),
                _buildBarGroup(1, 120000),
                _buildBarGroup(2, 85000),
                _buildBarGroup(3, 150000),
                _buildBarGroup(4, 30000),
              ],
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(show: false),
              gridData: FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppTheme.neonCyan.withOpacity(0.5),
          width: 20,
          borderRadius: BorderRadius.zero,
        ),
      ],
    );
  }
}
