import 'package:collaborative_music_player/design_system/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

class GlassInput extends StatelessWidget {
  const GlassInput({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: glass.panelSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(glass.radiusSm),
          borderSide: BorderSide(color: glass.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(glass.radiusSm),
          borderSide: BorderSide(color: glass.border),
        ),
      ),
    );
  }
}
