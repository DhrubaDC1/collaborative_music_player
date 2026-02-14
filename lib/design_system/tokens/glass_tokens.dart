import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.backgroundGradient,
    required this.panelStrong,
    required this.panelMedium,
    required this.panelSoft,
    required this.border,
    required this.shadow,
    required this.blurSm,
    required this.blurMd,
    required this.blurLg,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
  });

  final Gradient backgroundGradient;
  final Color panelStrong;
  final Color panelMedium;
  final Color panelSoft;
  final Color border;
  final Color shadow;
  final double blurSm;
  final double blurMd;
  final double blurLg;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  @override
  GlassTokens copyWith({
    Gradient? backgroundGradient,
    Color? panelStrong,
    Color? panelMedium,
    Color? panelSoft,
    Color? border,
    Color? shadow,
    double? blurSm,
    double? blurMd,
    double? blurLg,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
  }) {
    return GlassTokens(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      panelStrong: panelStrong ?? this.panelStrong,
      panelMedium: panelMedium ?? this.panelMedium,
      panelSoft: panelSoft ?? this.panelSoft,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      blurSm: blurSm ?? this.blurSm,
      blurMd: blurMd ?? this.blurMd,
      blurLg: blurLg ?? this.blurLg,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
    );
  }

  @override
  ThemeExtension<GlassTokens> lerp(
    ThemeExtension<GlassTokens>? other,
    double t,
  ) {
    if (other is! GlassTokens) {
      return this;
    }
    return GlassTokens(
      backgroundGradient:
          LinearGradient.lerp(
            backgroundGradient as LinearGradient,
            other.backgroundGradient as LinearGradient,
            t,
          ) ??
          backgroundGradient,
      panelStrong: Color.lerp(panelStrong, other.panelStrong, t) ?? panelStrong,
      panelMedium: Color.lerp(panelMedium, other.panelMedium, t) ?? panelMedium,
      panelSoft: Color.lerp(panelSoft, other.panelSoft, t) ?? panelSoft,
      border: Color.lerp(border, other.border, t) ?? border,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
      blurSm: lerpDouble(blurSm, other.blurSm, t) ?? blurSm,
      blurMd: lerpDouble(blurMd, other.blurMd, t) ?? blurMd,
      blurLg: lerpDouble(blurLg, other.blurLg, t) ?? blurLg,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t) ?? radiusSm,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t) ?? radiusMd,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t) ?? radiusLg,
    );
  }

  static const GlassTokens light = GlassTokens(
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF6F3EE), Color(0xFFE6E1D7), Color(0xFFF9F8F3)],
    ),
    panelStrong: Color(0xC2FFFFFF),
    panelMedium: Color(0xA8FFFFFF),
    panelSoft: Color(0x8AFFFFFF),
    border: Color(0x66FFFFFF),
    shadow: Color(0x22000000),
    blurSm: 8,
    blurMd: 14,
    blurLg: 22,
    radiusSm: 14,
    radiusMd: 20,
    radiusLg: 26,
  );

  static const GlassTokens dark = GlassTokens(
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF070A0E), Color(0xFF121722), Color(0xFF0A1218)],
    ),
    panelStrong: Color(0x66131B28),
    panelMedium: Color(0x4F131B28),
    panelSoft: Color(0x3A131B28),
    border: Color(0x4DFFFFFF),
    shadow: Color(0x55000000),
    blurSm: 8,
    blurMd: 14,
    blurLg: 22,
    radiusSm: 14,
    radiusMd: 20,
    radiusLg: 26,
  );
}
