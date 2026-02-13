import 'package:collaborative_music_player/core/theme/app_theme.dart';
import 'package:collaborative_music_player/features/library/library_tab.dart';
import 'package:collaborative_music_player/features/now_playing/now_playing_tab.dart';
import 'package:collaborative_music_player/features/party/party_tab.dart';
import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    final pages = const [LibraryTab(), NowPlayingTab(), PartyTab()];
    return Scaffold(
      extendBody: true,
      body: FrostedBackground(
        child: SafeArea(
          child: IndexedStack(index: _tab, children: pages),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq_rounded),
            label: 'Now',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_rounded),
            label: 'Party',
          ),
        ],
      ),
    );
  }
}
