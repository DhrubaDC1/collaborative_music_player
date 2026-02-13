import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _accent = Color(0xFFFF4D2E);
  static const Color _mint = Color(0xFF38F2C7);

  static ThemeData get lightTheme {
    final base = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.light,
      ).copyWith(primary: _accent, secondary: _mint),
      scaffoldBackgroundColor: const Color(0xFFF6F3EE),
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.dmSans(textStyle: base.textTheme.bodyMedium),
        bodySmall: GoogleFonts.dmSans(textStyle: base.textTheme.bodySmall),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: _accent,
        thumbColor: _mint,
        inactiveTrackColor: Color(0x33FFFFFF),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: _accent,
            brightness: Brightness.dark,
          ).copyWith(
            primary: _accent,
            secondary: _mint,
            surface: const Color(0xFF121722),
          ),
      scaffoldBackgroundColor: const Color(0xFF070A0E),
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.dmSans(textStyle: base.textTheme.bodyMedium),
        bodySmall: GoogleFonts.dmSans(textStyle: base.textTheme.bodySmall),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: _accent,
        thumbColor: _mint,
        inactiveTrackColor: Color(0x22FFFFFF),
      ),
    );
  }
}

class FrostedBackground extends StatelessWidget {
  const FrostedBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF070A0E), Color(0xFF121722), Color(0xFF0A1218)]
              : const [Color(0xFFF6F3EE), Color(0xFFE6E1D7), Color(0xFFF9F8F3)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.07 : 0.09,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 0.9,
                      colors: [Color(0x66FF4D2E), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
