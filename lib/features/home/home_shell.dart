import 'package:collaborative_music_player/core/theme/app_theme.dart';
import 'package:collaborative_music_player/core/widgets/glass_panel.dart';
import 'package:collaborative_music_player/design_system/accessibility/reduced_motion.dart';
import 'package:collaborative_music_player/design_system/theme/theme_tokens.dart';
import 'package:collaborative_music_player/features/library/library_tab.dart';
import 'package:collaborative_music_player/features/now_playing/now_playing_tab.dart';
import 'package:collaborative_music_player/features/party/party_tab.dart';
import 'package:collaborative_music_player/services/audio/audio_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    final pages = const [LibraryTab(), NowPlayingTab(), PartyTab()];
    final duration = prefersReducedMotion(context)
        ? Duration.zero
        : context.motion.medium;
    return Scaffold(
      extendBody: true,
      body: FrostedBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: duration,
                  child: KeyedSubtree(
                    key: ValueKey<int>(_tab),
                    child: pages[_tab],
                  ),
                ),
              ),
              const _MiniPlayerDock(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: GlassPanel(
          blur: 14,
          radius: 26,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: NavigationBar(
            selectedIndex: _tab,
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
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
        ),
      ),
    );
  }
}

class _MiniPlayerDock extends ConsumerWidget {
  const _MiniPlayerDock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).value;
    final playback = ref.watch(playbackStateProvider).value;
    if (item == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = playback?.playing ?? false;
    final duration = prefersReducedMotion(context)
        ? Duration.zero
        : context.motion.fast;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
        child: AnimatedSlide(
          duration: duration,
          offset: Offset.zero,
          child: GlassPanel(
            blur: 18,
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0x66FF4D2E),
                  child: Icon(Icons.album_rounded, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        item.artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: () {
                    if (isPlaying) {
                      ref.read(audioHandlerProvider).pause();
                    } else {
                      ref.read(audioHandlerProvider).play();
                    }
                  },
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
