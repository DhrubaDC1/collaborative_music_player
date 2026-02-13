import 'package:collaborative_music_player/core/widgets/glass_panel.dart';
import 'package:collaborative_music_player/services/audio/audio_providers.dart';
import 'package:collaborative_music_player/services/party/party_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NowPlayingTab extends ConsumerWidget {
  const NowPlayingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(mediaItemProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);
    final party = ref.watch(partySessionProvider);

    final isPlaying = playbackAsync.value?.playing ?? false;
    final position = positionAsync.value ?? Duration.zero;
    final duration =
        durationAsync.value ?? mediaItemAsync.value?.duration ?? Duration.zero;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Now Playing',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          GlassPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xAAFF4D2E), Color(0xAA38F2C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.album_rounded, size: 120),
                ),
                const SizedBox(height: 18),
                Text(
                  mediaItemAsync.value?.title ?? 'Pick a track from Library',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(mediaItemAsync.value?.artist ?? 'Local collection'),
                const SizedBox(height: 12),
                Slider(
                  value: duration.inMilliseconds <= 0
                      ? 0
                      : position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                  max: duration.inMilliseconds <= 0
                      ? 1
                      : duration.inMilliseconds.toDouble(),
                  onChanged: duration.inMilliseconds <= 0
                      ? null
                      : (value) {
                          final target = Duration(milliseconds: value.toInt());
                          final notifier = ref.read(
                            partySessionProvider.notifier,
                          );
                          if (party.isHost) {
                            notifier.hostSeek(target);
                          } else {
                            ref.read(audioHandlerProvider).seek(target);
                          }
                        },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(_format(position)), Text(_format(duration))],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        if (party.isHost) {
                          ref
                              .read(partySessionProvider.notifier)
                              .hostPrevious();
                          return;
                        }
                        ref.read(audioHandlerProvider).skipToPrevious();
                      },
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    const SizedBox(width: 18),
                    FilledButton(
                      onPressed: () {
                        final notifier = ref.read(
                          partySessionProvider.notifier,
                        );
                        if (isPlaying) {
                          if (party.isHost) {
                            notifier.hostPause();
                          } else {
                            ref.read(audioHandlerProvider).pause();
                          }
                          return;
                        }
                        if (party.isHost) {
                          notifier.hostPlay();
                        } else {
                          ref.read(audioHandlerProvider).play();
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 18),
                    IconButton.filledTonal(
                      onPressed: () {
                        if (party.isHost) {
                          ref.read(partySessionProvider.notifier).hostNext();
                          return;
                        }
                        ref.read(audioHandlerProvider).skipToNext();
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            blur: 14,
            child: Row(
              children: [
                const Icon(Icons.sync_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    party.isConnected
                        ? 'Sync skew: ${party.syncSkewMs}ms | host offset: ${party.hostOffsetMs}ms'
                        : 'Party session offline',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration duration) {
    final mm = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
