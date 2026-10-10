import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'audio_library_cache.g.dart';

class AudioSongs extends Table {
  IntColumn get id => integer()();

  TextColumn get title => text().nullable()();

  TextColumn get artist => text().nullable()();

  TextColumn get album => text().nullable()();

  IntColumn get duration => integer()();

  TextColumn get uri => text()();

  IntColumn get albumId => integer().nullable()();

  TextColumn get albumArt => text().nullable()();

  TextColumn get cachedArtPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {uri};
}

@DriftDatabase(tables: [AudioSongs])
class AudioLibraryCache extends _$AudioLibraryCache {
  AudioLibraryCache._(super.e);

  static Future<AudioLibraryCache> create() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      p.join(directory.path, 'audio_library.sqlite'),
    );

    return AudioLibraryCache._(
      NativeDatabase.createInBackground(file),
    );
  }

  @override
  int get schemaVersion => 1;

  Future<List<AudioFile>> getSongs() async {
    final rows = await select(audioSongs).get();

    return rows.map(_toAudioFile).toList();
  }

  Future<void> replaceSongs(List<AudioFile> songs) async {
    await transaction(() async {
      await delete(audioSongs).go();
      await batch((batch) {
        batch.insertAll(
          audioSongs,
          songs.map(_toCompanion).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<void> deleteByUri(String uri) {
    return (delete(audioSongs)..where((tbl) => tbl.uri.equals(uri))).go();
  }

  Future<void> clear() async {
    await delete(audioSongs).go();
  }

  AudioFile _toAudioFile(AudioSong row) {
    return AudioFile(
      id: row.id,
      title: row.title,
      artist: row.artist,
      album: row.album,
      duration: row.duration,
      uri: row.uri,
      albumId: row.albumId,
      albumArt: row.albumArt,
      cachedArtPath: row.cachedArtPath,
    );
  }

  AudioSongsCompanion _toCompanion(AudioFile song) {
    return AudioSongsCompanion(
      id: Value(song.id),
      title: Value(song.title),
      artist: Value(song.artist),
      album: Value(song.album),
      duration: Value(song.duration),
      uri: Value(song.uri),
      albumId: Value(song.albumId),
      albumArt: Value(song.albumArt),
      cachedArtPath: Value(song.cachedArtPath),
    );
  }
}