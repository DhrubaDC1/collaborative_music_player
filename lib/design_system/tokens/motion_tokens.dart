import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class MotionTokens extends ThemeExtension<MotionTokens> {
  const MotionTokens({
    required this.fast,
    required this.medium,
    required this.slow,
    required this.standardCurve,
  });

  final Duration fast;
  final Duration medium;
  final Duration slow;
  final Curve standardCurve;

  @override
  MotionTokens copyWith({
    Duration? fast,
    Duration? medium,
    Duration? slow,
    Curve? standardCurve,
  }) {
    return MotionTokens(
      fast: fast ?? this.fast,
      medium: medium ?? this.medium,
      slow: slow ?? this.slow,
      standardCurve: standardCurve ?? this.standardCurve,
    );
  }

  @override
  ThemeExtension<MotionTokens> lerp(
    ThemeExtension<MotionTokens>? other,
    double t,
  ) {
    if (other is! MotionTokens) {
      return this;
    }
    return MotionTokens(
      fast: Duration(
        milliseconds:
            lerpDouble(
              fast.inMilliseconds.toDouble(),
              other.fast.inMilliseconds.toDouble(),
              t,
            )?.round() ??
            fast.inMilliseconds,
      ),
      medium: Duration(
        milliseconds:
            lerpDouble(
              medium.inMilliseconds.toDouble(),
              other.medium.inMilliseconds.toDouble(),
              t,
            )?.round() ??
            medium.inMilliseconds,
      ),
      slow: Duration(
        milliseconds:
            lerpDouble(
              slow.inMilliseconds.toDouble(),
              other.slow.inMilliseconds.toDouble(),
              t,
            )?.round() ??
            slow.inMilliseconds,
      ),
      standardCurve: other.standardCurve,
    );
  }

  static const MotionTokens defaults = MotionTokens(
    fast: Duration(milliseconds: 120),
    medium: Duration(milliseconds: 220),
    slow: Duration(milliseconds: 340),
    standardCurve: Curves.easeOutCubic,
  );
}
