import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class TerminalOverlay extends StatefulWidget {
  final Widget child;
  const TerminalOverlay({super.key, required this.child});

  @override
  State<TerminalOverlay> createState() => _TerminalOverlayState();
}

class _TerminalOverlayState extends State<TerminalOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Scanlines & Grain
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TerminalPainter(
                    flickerValue: _controller.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TerminalPainter extends CustomPainter {
  final double flickerValue;
  _TerminalPainter({required this.flickerValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 1. Organic Fog (Slow Moving)
    final fogRandom = math.Random(6789);
    for (int i = 0; i < 15; i++) {
      // Moves much slower now with 20s cycle
      double x = (fogRandom.nextDouble() * size.width + (flickerValue * 30)) % size.width;
      double y = (fogRandom.nextDouble() * size.height + (flickerValue * 15)) % size.height;
      double radius = 150 + fogRandom.nextDouble() * 200;
      
      paint.shader = ui.Gradient.radial(
        Offset(x, y),
        radius,
        [
          Colors.white.withOpacity(0.04), // Back to subtle
          Colors.transparent,
        ],
      );
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    paint.shader = null;

    // 2. Sharper Noise
    final random = math.Random(12345);
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 200; i++) {
       double x = random.nextDouble() * size.width;
       double y = random.nextDouble() * size.height;
       paint.color = Colors.white.withOpacity(random.nextDouble() * 0.04);
       canvas.drawRect(Rect.fromLTWH(x, y, 1.0, 1.0), paint);
    }

    // 3. Deeper Vignette
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.width * 1.2,
      [
        Colors.transparent,
        Colors.black.withOpacity(0.7), // Darker edges
      ],
    );
    paint.shader = gradient;
    canvas.drawRect(rect, paint);
    paint.shader = null;

    // 4. Subtle Pro Scanlines
    double lineSpacing = 4.0;
    paint.strokeWidth = 0.5; // Thinner for professionalism
    for (double y = 0; y < size.height; y += lineSpacing) {
      // Very slight pulse
      paint.color = Colors.white.withOpacity(0.03 + (math.sin(flickerValue * 4.0 + y) * 0.01));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TerminalPainter oldDelegate) => true;
}
