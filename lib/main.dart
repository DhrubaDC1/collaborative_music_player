import 'package:collaborative_music_player/app/app.dart';
import 'package:collaborative_music_player/services/audio/app_audio_handler.dart';
import 'package:collaborative_music_player/services/audio/audio_providers.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appHandler = AppAudioHandler();

  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(appHandler)],
      child: const PartyMusicApp(),
    ),
  );

  _initializeAudioBackend(appHandler);
}

Future<void> _initializeAudioBackend(AppAudioHandler appHandler) async {
  try {
    await appHandler.configureSession();
    await AudioService.init(
      builder: () => appHandler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.collaborative_music_player.playback',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    ).timeout(const Duration(seconds: 4));
  } catch (error, stackTrace) {
    debugPrint('Audio backend init skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
