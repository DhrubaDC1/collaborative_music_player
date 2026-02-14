import 'package:collaborative_music_player/design_system/components/glass_surface.dart';
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
    return GlassSurface(
      padding: padding,
      radius: radius,
      blur: blur,
      child: child,
    );
  }
}
