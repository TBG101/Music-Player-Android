import 'package:musicplayer/features/library/domain/audio_file.dart';
import 'package:musicplayer/features/library/data/audio_library_cache.dart';

class AudioLibraryRepository {
  AudioLibraryRepository(this._database);

  final AudioLibraryCache _database;

  Future<List<AudioFile>> loadCachedSongs() {
    return _database.getSongs();
  }

  Future<void> replaceSongs(List<AudioFile> songs) {
    return _database.replaceSongs(songs);
  }

  Future<void> deleteSong(String uri) {
    return _database.deleteByUri(uri);
  }
}
