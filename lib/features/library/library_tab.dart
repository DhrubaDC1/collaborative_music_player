import 'package:audio_service/audio_service.dart';
import 'package:collaborative_music_player/core/widgets/glass_panel.dart';
import 'package:collaborative_music_player/design_system/components/glass_button.dart';
import 'package:collaborative_music_player/design_system/components/glass_input.dart';
import 'package:collaborative_music_player/design_system/components/status_pill.dart';
import 'package:collaborative_music_player/domain/track_item.dart';
import 'package:collaborative_music_player/services/audio/audio_providers.dart';
import 'package:collaborative_music_player/services/party/party_session_service.dart';
import 'package:collaborative_music_player/services/youtube/youtube_audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key});

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> {
  final _youtubeController = TextEditingController();
  final _youtubeService = YoutubeAudioService();
  bool _addingYoutube = false;

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(queueProvider);
    final partyState = ref.watch(partySessionProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('Library', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const StatusPill(label: 'Local Music', tone: StatusTone.info),
              const StatusPill(
                label: 'YouTube Audio',
                tone: StatusTone.success,
              ),
              if (partyState.isHost)
                StatusPill(
                  label: 'Hosting ${partyState.peers.length}',
                  tone: StatusTone.warning,
                ),
            ],
          ),
          const SizedBox(height: 14),
          GlassPanel(
            radius: 24,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                GlassButton(
                  label: 'Import Files',
                  icon: Icons.folder_open_rounded,
                  onPressed: _importLocalTracks,
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.read(audioHandlerProvider).clearQueue(),
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear Queue'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassPanel(
            blur: 16,
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add from YouTube',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                GlassInput(
                  controller: _youtubeController,
                  hint: 'https://www.youtube.com/watch?v=...',
                ),
                const SizedBox(height: 10),
                GlassButton(
                  onPressed: _addingYoutube ? null : _addYoutubeTrack,
                  icon: Icons.play_circle_outline_rounded,
                  label: _addingYoutube ? 'Resolving...' : 'Add YouTube Audio',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: queueAsync.when(
              data: (queue) {
                if (queue.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tracks yet. Import local music or add YouTube audio.',
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: queue.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = queue[index];
                    return _TrackTile(item: item, index: index);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Queue error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importLocalTracks() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'],
    );
    if (result == null) return;

    final paths = result.paths.whereType<String>().toList(growable: false);
    if (paths.isEmpty) return;

    final tracks = paths.map(TrackItem.fromPath).toList(growable: false);
    await ref.read(audioHandlerProvider).appendTracks(tracks);
  }

  Future<void> _addYoutubeTrack() async {
    final url = _youtubeController.text.trim();
    if (url.isEmpty) {
      return;
    }
    setState(() => _addingYoutube = true);
    try {
      final track = await _youtubeService.resolveTrack(url);
      await ref.read(audioHandlerProvider).appendTracks(<TrackItem>[track]);
      _youtubeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added: ${track.title}')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add YouTube link: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addingYoutube = false);
      }
    }
  }
}

class _TrackTile extends ConsumerWidget {
  const _TrackTile({required this.item, required this.index});

  final MediaItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: 20,
      blur: 12,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () async {
          await ref.read(audioHandlerProvider).playTrackAt(index);
          final partyState = ref.read(partySessionProvider);
          if (partyState.isHost) {
            await ref.read(partySessionProvider.notifier).hostPlay();
          }
        },
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0x66FF4D2E), Color(0x6638F2C7)],
            ),
          ),
          child: const Icon(Icons.music_note_rounded),
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.artist ?? 'Unknown artist'),
        trailing: Text(
          item.duration == null ? '--:--' : _formatDuration(item.duration!),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
