import 'package:audio_service/audio_service.dart';
import 'package:collaborative_music_player/services/audio/app_audio_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioHandlerProvider = Provider<AppAudioHandler>((_) {
  throw UnimplementedError(
    'Audio handler must be overridden in ProviderScope.',
  );
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  return ref.watch(audioHandlerProvider).playbackState;
});

final queueProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(audioHandlerProvider).queue;
});

final mediaItemProvider = StreamProvider<MediaItem?>((ref) {
  return ref.watch(audioHandlerProvider).mediaItem;
});

final positionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioHandlerProvider).player.positionStream;
});

final durationProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioHandlerProvider).player.durationStream;
});
