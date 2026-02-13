import 'package:collaborative_music_player/core/theme/app_theme.dart';
import 'package:collaborative_music_player/features/home/home_shell.dart';
import 'package:flutter/material.dart';

class PartyMusicApp extends StatelessWidget {
  const PartyMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Party Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
