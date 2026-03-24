import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizon_protocol/screens/chapter1_screen.dart';
import 'package:horizon_protocol/screens/chapter2_screen.dart';
import 'package:horizon_protocol/screens/chapter3_screen.dart';

class DevNav extends StatefulWidget {
  const DevNav({super.key});

  @override
  State<DevNav> createState() => _DevNavState();
}

class _DevNavState extends State<DevNav> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded) ...[
            _buildNavButton("C1", const Chapter1Screen()),
            const SizedBox(height: 8),
            _buildNavButton("C2", const Chapter2Screen()),
            const SizedBox(height: 8),
            _buildNavButton("C3", const Chapter3Screen()),
            const SizedBox(height: 8),
            // Gelecek bölümler için placeholder
            _buildNavButton("C4", null), 
            const SizedBox(height: 12),
          ],
          FloatingActionButton.small(
            backgroundColor: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            child: Icon(
              _isExpanded ? Icons.close : Icons.bug_report,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String label, Widget? target) {
    return InkWell(
      onTap: () {
        if (target != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => target),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.sourceCodePro(
            color: target != null ? Colors.white : Colors.white24,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
