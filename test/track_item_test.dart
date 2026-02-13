import 'package:collaborative_music_player/domain/track_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TrackItem.fromPath extracts filename as title', () {
    final track = TrackItem.fromPath('/music/Daft Punk - One More Time.mp3');

    expect(track.title, 'Daft Punk - One More Time');
    expect(track.path, '/music/Daft Punk - One More Time.mp3');
    expect(track.artist, 'Local File');
  });
}
