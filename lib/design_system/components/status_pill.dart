import 'package:flutter/material.dart';

enum StatusTone { info, success, warning, error }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.info,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      StatusTone.info => (const Color(0x332D7FF9), const Color(0xFF2D7FF9)),
      StatusTone.success => (const Color(0x3332D583), const Color(0xFF32D583)),
      StatusTone.warning => (const Color(0x33FFB020), const Color(0xFFFFB020)),
      StatusTone.error => (const Color(0x33FF4D4F), const Color(0xFFFF4D4F)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
