import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class SpacingTokens extends ThemeExtension<SpacingTokens> {
  const SpacingTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  SpacingTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return SpacingTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  ThemeExtension<SpacingTokens> lerp(
    ThemeExtension<SpacingTokens>? other,
    double t,
  ) {
    if (other is! SpacingTokens) {
      return this;
    }
    return SpacingTokens(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
    );
  }

  static const SpacingTokens defaults = SpacingTokens(
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
  );
}
