import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class TrackItem {
  const TrackItem({
    required this.id,
    required this.path,
    required this.title,
    this.artist,
    this.durationMs,
  });

  final String id;
  final String path;
  final String title;
  final String? artist;
  final int? durationMs;

  factory TrackItem.fromPath(String path) {
    final fileName = p.basenameWithoutExtension(path);
    return TrackItem(
      id: _uuid.v4(),
      path: path,
      title: fileName,
      artist: 'Local File',
    );
  }

  factory TrackItem.fromJson(Map<String, dynamic> json) {
    return TrackItem(
      id: json['id'] as String,
      path: json['path'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      durationMs: json['durationMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'title': title,
      'artist': artist,
      'durationMs': durationMs,
    };
  }
}
