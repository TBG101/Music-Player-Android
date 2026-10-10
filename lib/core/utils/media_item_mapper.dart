import 'package:audio_service/audio_service.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';

class MediaItemMapper {
  static MediaItem fromSongModel(AudioFile song) {
    final artPath = song.cachedArtPath;

    return MediaItem(
      id: song.uri.toString(), // critical field
      title: song.title ?? "Unknown Title",
      artist: song.artist ?? "Unknown",
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      artUri: (artPath == null || artPath.isEmpty) ? null : Uri.parse(artPath),
      extras: {
        "songId": song.id,
        "hasLocalArt": true,
        "loadThumbnailUri": true,
      },
    );
  }
}
