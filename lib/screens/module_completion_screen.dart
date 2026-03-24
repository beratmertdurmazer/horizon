import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/audio_service.dart';

class ModuleCompletionScreen extends StatefulWidget {
  final String moduleTitle;
  const ModuleCompletionScreen({super.key, required this.moduleTitle});

  @override
  State<ModuleCompletionScreen> createState() => _ModuleCompletionScreenState();
}

class _ModuleCompletionScreenState extends State<ModuleCompletionScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  double _progress = 0.0;
  Timer? _timer;
  final List<String> _logs = [
    "KARAR GEÇMİŞİ DERLENİYOR...",
    "PSİKOMETRİK VERİLER ŞİFRELENİYOR...",
    "LİDERLİK EĞİLİMİ ANALİZ EDİLİYOR...",
    "EKİP UYUM KATSAYISI HESAPLANIYOR...",
    "VERİ PAKETİ: HORIZON YÜKSEK KOMUTASI'NA (HHC) İLETİLİYOR...",
    "GÖZETMEN ÜNİTESİ: ANALİZ ONAYLANDI.",
    "BÖLÜM KAPATILIYOR. BAĞLANTI SONLANDIRILDI."
  ];
  int _logIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _finalize();
        }
        
        // Update logs based on progress
        _logIndex = (_progress * _logs.length).floor().clamp(0, _logs.length - 1);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().playAmbientLoop();
    });
  }

  void _finalize() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 60),
              _buildProgressSection(),
              const Spacer(),
              _buildLogTerminal(),
              const SizedBox(height: 20),
              _buildStatusFooter(),
            ],
          ),
        ),
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
            Text("MODÜL TAMAMLANDI", style: GoogleFonts.rajdhani(color: AppTheme.neonCyan, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
            Text(widget.moduleTitle.toUpperCase(), style: GoogleFonts.sourceCodePro(color: Colors.white54, fontSize: 12)),
          ],
        ),
        Icon(Icons.check_circle_outline, color: AppTheme.neonCyan, size: 32),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("VERİ İLETİMİ (HHC UPLINK)", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
            Text("${(_progress * 100).toInt()}%", style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 40),
        _buildMetricRow("PSİKOMETRİK ANALİZ", _progress > 0.4 ? 1.0 : _progress * 2.5),
        const SizedBox(height: 16),
        _buildMetricRow("LİDERLİK SKORU", _progress > 0.7 ? 1.0 : _progress * 1.4),
        const SizedBox(height: 16),
        _buildMetricRow("EKİP UYUMU", _progress > 0.9 ? 1.0 : _progress * 1.1),
      ],
    );
  }

  Widget _buildMetricRow(String label, double val) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label, style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10))),
        Expanded(
          child: LinearProgressIndicator(
            value: val.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(val >= 1.0 ? Colors.greenAccent : AppTheme.neonCyan.withOpacity(0.5)),
            minHeight: 2,
          ),
        ),
        const SizedBox(width: 12),
        Text(val >= 1.0 ? "DONE" : "WAIT", style: GoogleFonts.sourceCodePro(color: val >= 1.0 ? Colors.greenAccent : Colors.white24, fontSize: 8)),
      ],
    );
  }

  Widget _buildLogTerminal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SYSTEM LOGS:", style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 12),
          Text(
            _logs[_logIndex],
            style: GoogleFonts.sourceCodePro(color: AppTheme.neonCyan.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFooter() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(_pulseController.value),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          "GÖZETMEN ÜNİTESİ AKTİF. PERSO_MR_V3_LINK_ESTABLISHED",
          style: GoogleFonts.sourceCodePro(color: Colors.white24, fontSize: 8),
        ),
      ],
    );
  }
}
