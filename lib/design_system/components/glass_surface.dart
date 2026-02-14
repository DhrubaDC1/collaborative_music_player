import 'dart:ui';

import 'package:collaborative_music_player/design_system/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius,
    this.blur,
    this.background,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final double? blur;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final effectiveRadius = radius ?? glass.radiusMd;
    final effectiveBlur = blur ?? glass.blurMd;
    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background ?? glass.panelMedium,
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: Border.all(color: glass.border),
            boxShadow: [
              BoxShadow(
                color: glass.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
