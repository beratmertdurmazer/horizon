import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:horizon_protocol/core/app_theme.dart';
import 'package:horizon_protocol/services/audio_service.dart';
import 'package:horizon_protocol/services/persona_mr.dart';

class ChapterBreatherScreen extends StatefulWidget {
  final String completedChapterTitle;
  final String nextChapterHint;
  final Widget nextScreen;
  final int breatheDurationSeconds;

  const ChapterBreatherScreen({
    super.key,
    required this.completedChapterTitle,
    required this.nextChapterHint,
    required this.nextScreen,
    this.breatheDurationSeconds = 4,
  });

  @override
  State<ChapterBreatherScreen> createState() => _ChapterBreatherScreenState();
}

class _ChapterBreatherScreenState extends State<ChapterBreatherScreen>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _fadeInController;
  late AnimationController _fadeOutController;
  late Animation<double> _breatheAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  late Stopwatch _stopwatch;
  Timer? _autoAdvanceTimer;
  bool _isTransitioning = false;

  // Subtle particle system
  final List<_Particle> _particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();

    // Breathing pulse animation (continuous)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breatheAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeOut),
    );
    _fadeInController.forward();

    // Fade out animation (triggered before navigation)
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    // Generate floating particles
    _generateParticles();
    _particleTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateParticles(),
    );

    // Auto-advance after breather duration
    _autoAdvanceTimer = Timer(
      Duration(seconds: widget.breatheDurationSeconds),
      _advanceToNext,
    );
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.0005 + random.nextDouble() * 0.001,
        size: 1.0 + random.nextDouble() * 2.0,
        opacity: 0.1 + random.nextDouble() * 0.3,
      ));
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (var p in _particles) {
        p.y -= p.speed;
        if (p.y < 0) p.y = 1.0;
      }
    });
  }

  void _advanceToNext() {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;
    _stopwatch.stop();

    PersonaMR().logChapterMetrics(
      chapterId: "BREATHER_${widget.completedChapterTitle}",
      totalTimeMs: _stopwatch.elapsedMilliseconds,
    );

    _fadeOutController.forward().then((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _fadeInController.dispose();
    _fadeOutController.dispose();
    _autoAdvanceTimer?.cancel();
    _particleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeOutAnimation.status == AnimationStatus.forward ||
                _fadeOutAnimation.status == AnimationStatus.completed
            ? _fadeOutAnimation
            : _fadeInAnimation,
        child: Stack(
          children: [
            // Subtle grid background
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),

            // Floating particles
            ..._particles.map((p) => Positioned(
                  left: p.x * MediaQuery.of(context).size.width,
                  top: p.y * MediaQuery.of(context).size.height,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.neonCyan.withOpacity(p.opacity),
                    ),
                  ),
                )),

            // Breathing radial glow
            AnimatedBuilder(
              animation: _breatheAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.neonCyan
                              .withOpacity(_breatheAnimation.value * 0.04),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Completed chapter indicator
                    AnimatedBuilder(
                      animation: _breatheAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 60,
                          height: 1,
                          color: AppTheme.neonCyan.withOpacity(
                              _breatheAnimation.value * 0.5),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // Completed chapter title
                    Text(
                      widget.completedChapterTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "TAMAMLANDI",
                      style: GoogleFonts.sourceCodePro(
                        color: AppTheme.neonCyan.withOpacity(0.4),
                        fontSize: 10,
                        letterSpacing: 6,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Breathing dot
                    AnimatedBuilder(
                      animation: _breatheAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 6 + _breatheAnimation.value * 4,
                          height: 6 + _breatheAnimation.value * 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.neonCyan.withOpacity(
                                _breatheAnimation.value * 0.6),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan.withOpacity(
                                    _breatheAnimation.value * 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // Next chapter hint
                    Text(
                      widget.nextChapterHint,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white10,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom scanline
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _breatheAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _breatheAnimation.value * 0.3,
                      child: Text(
                        "SİSTEM STABIL · SONRAKI GÖREV YÜKLENİYOR",
                        style: GoogleFonts.sourceCodePro(
                          color: AppTheme.neonCyan,
                          fontSize: 8,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, speed, size, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
