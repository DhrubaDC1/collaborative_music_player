import 'package:collaborative_music_player/domain/track_item.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeAudioService {
  Future<TrackItem> resolveTrack(String inputUrl) async {
    final yt = YoutubeExplode();
    try {
      final videoId = VideoId.parseVideoId(inputUrl);
      if (videoId == null) {
        throw const FormatException('Invalid YouTube URL');
      }

      final video = await yt.videos.get(videoId);
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final stream = manifest.audioOnly.withHighestBitrate();

      return TrackItem(
        id: videoId,
        path: stream.url.toString(),
        title: video.title,
        artist: video.author,
        durationMs: video.duration?.inMilliseconds,
      );
    } finally {
      yt.close();
    }
  }
}
