import 'package:collaborative_music_player/design_system/tokens/glass_tokens.dart';
import 'package:collaborative_music_player/design_system/tokens/motion_tokens.dart';
import 'package:collaborative_music_player/design_system/tokens/spacing_tokens.dart';
import 'package:flutter/material.dart';

extension ThemeTokenX on BuildContext {
  GlassTokens get glass => Theme.of(this).extension<GlassTokens>()!;
  MotionTokens get motion => Theme.of(this).extension<MotionTokens>()!;
  SpacingTokens get spacing => Theme.of(this).extension<SpacingTokens>()!;
}
