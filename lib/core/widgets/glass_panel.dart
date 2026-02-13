import 'dart:ui';

import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? const Color(0x33131B28)
        : const Color(0xA8FFFFFF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isDark ? const Color(0x4DFFFFFF) : const Color(0x66FFFFFF),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
