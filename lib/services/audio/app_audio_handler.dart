import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:collaborative_music_player/domain/track_item.dart';
import 'package:just_audio/just_audio.dart';

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AppAudioHandler() {
    _player.playbackEventStream.listen((_) => _broadcastState());
    _player.currentIndexStream.listen(_syncMediaItem);
    _player.durationStream.listen(_syncDurations);
  }

  final AudioPlayer _player = AudioPlayer();
  final Map<String, TrackItem> _trackByPath = <String, TrackItem>{};

  AudioPlayer get player => _player;
  Duration get currentPosition => _player.position;

  Future<void> configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> replaceQueueFromTracks(List<TrackItem> tracks) async {
    _trackByPath
      ..clear()
      ..addEntries(tracks.map((e) => MapEntry(e.path, e)));

    final mediaItems = tracks
        .map(
          (track) => MediaItem(
            id: track.path,
            title: track.title,
            artist: track.artist ?? 'Unknown Artist',
            duration: track.durationMs == null
                ? null
                : Duration(milliseconds: track.durationMs!),
            extras: {'trackId': track.id},
          ),
        )
        .toList(growable: false);

    queue.add(mediaItems);
    await _player.setAudioSources(
      mediaItems
          .map((media) => AudioSource.file(media.id, tag: media))
          .toList(growable: false),
    );
    _syncMediaItem(_player.currentIndex);
    _broadcastState();
  }

  Future<void> appendTracks(List<TrackItem> tracks) async {
    final currentTracks = queue.value
        .map(
          (item) => TrackItem(
            id: item.extras?['trackId'] as String? ?? item.id,
            path: item.id,
            title: item.title,
            artist: item.artist,
            durationMs: item.duration?.inMilliseconds,
          ),
        )
        .toList();
    await replaceQueueFromTracks(<TrackItem>[...currentTracks, ...tracks]);
  }

  Future<void> clearQueue() async {
    queue.add(const []);
    await _player.stop();
    await _player.setAudioSources(const []);
    mediaItem.add(null);
    _broadcastState();
  }

  Future<void> playTrackAt(int index) async {
    if (index < 0 || index >= queue.value.length) {
      return;
    }
    await _player.seek(Duration.zero, index: index);
    await play();
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _broadcastState();
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    _broadcastState();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    _broadcastState();
  }

  @override
  Future<void> skipToQueueItem(int index) =>
      _player.seek(Duration.zero, index: index);

  @override
  Future<void> stop() async {
    await _player.stop();
    _broadcastState();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await _player.dispose();
    await super.onTaskRemoved();
  }

  Future<Map<String, dynamic>> snapshot() async {
    final index = _player.currentIndex ?? 0;
    final item = index < queue.value.length ? queue.value[index] : null;
    return {
      'index': index,
      'trackPath': item?.id,
      'positionMs': _player.position.inMilliseconds,
      'isPlaying': _player.playing,
      'speed': _player.speed,
      'hostTimeMs': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<void> applyRemoteCommand(Map<String, dynamic> payload) async {
    final command = payload['command'] as String?;
    if (command == null) return;

    switch (command) {
      case 'play':
        final index = payload['index'] as int?;
        final positionMs = payload['positionMs'] as int?;
        if (index != null && index >= 0 && index < queue.value.length) {
          await _player.seek(
            Duration(milliseconds: positionMs ?? 0),
            index: index,
          );
        } else if (positionMs != null) {
          await _player.seek(Duration(milliseconds: positionMs));
        }
        await play();
        return;
      case 'pause':
        final positionMs = payload['positionMs'] as int?;
        if (positionMs != null) {
          await _player.seek(Duration(milliseconds: positionMs));
        }
        await pause();
        return;
      case 'seek':
        final positionMs = payload['positionMs'] as int? ?? 0;
        await seek(Duration(milliseconds: positionMs));
        return;
      case 'next':
        await skipToNext();
        return;
      case 'previous':
        await skipToPrevious();
        return;
      case 'syncTick':
        await _applySyncTick(payload);
        return;
    }
  }

  Future<void> _applySyncTick(Map<String, dynamic> payload) async {
    final expectedPosition = payload['positionMs'] as int?;
    final hostTime = payload['hostTimeMs'] as int?;
    final hostOffset = payload['hostOffsetMs'] as int?;
    if (expectedPosition == null || hostTime == null || hostOffset == null) {
      return;
    }

    final hostPlaying = payload['isPlaying'] as bool?;
    if (hostPlaying != null) {
      if (hostPlaying && !_player.playing) {
        await play();
      } else if (!hostPlaying && _player.playing) {
        await pause();
      }
    }

    final nowHostMs = DateTime.now().millisecondsSinceEpoch + hostOffset;
    final extrapolated = expectedPosition + (nowHostMs - hostTime);
    final actual = _player.position.inMilliseconds;
    final error = extrapolated - actual;
    final absoluteError = error.abs();

    if (absoluteError > 120) {
      await seek(Duration(milliseconds: extrapolated.clamp(0, 1 << 31)));
      await setSpeed(1.0);
      return;
    }

    if (absoluteError > 30) {
      final nudge = (error / 1000).clamp(-0.02, 0.02);
      await setSpeed(1.0 + nudge);
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 700), () async {
          await setSpeed(1.0);
        }),
      );
    }
  }

  void _syncDurations(Duration? _) {
    final currentQueue = queue.value;
    if (currentQueue.isEmpty) return;

    final updated = <MediaItem>[];
    final sequence = _player.sequence;
    for (var i = 0; i < currentQueue.length; i++) {
      final item = currentQueue[i];
      Duration? duration = item.duration;
      if (i < sequence.length) {
        duration = sequence[i].duration ?? duration;
      }
      updated.add(item.copyWith(duration: duration));
    }
    queue.add(updated);
    _syncMediaItem(_player.currentIndex);
  }

  void _syncMediaItem(int? currentIndex) {
    final index = currentIndex ?? 0;
    if (index < 0 || index >= queue.value.length) {
      mediaItem.add(null);
      return;
    }
    mediaItem.add(queue.value[index]);
  }

  void _broadcastState() {
    final processingState = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.playPause,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 4],
        processingState: processingState,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }
}
