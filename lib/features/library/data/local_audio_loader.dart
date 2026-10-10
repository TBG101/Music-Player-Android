import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';
import 'package:musicplayer/features/library/data/audio_library_repository.dart';
import 'package:musicplayer/core/services/art_work_utils.dart';
import 'package:musicplayer/core/services/media_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAudioLoader {
  static const int minDurationMs = 60000;
  static const String _artCacheVersionKey = "artCacheV3";
  final AudioLibraryRepository _audioLibrary =
      Get.find<AudioLibraryRepository>();

  Future<List<AudioFile>> getCachedSongs() {
    return _audioLibrary.loadCachedSongs();
  }

  Future<void> deleteCachedSong(String uri) {
    return _audioLibrary.deleteSong(uri);
  }

  Future<List<AudioFile>> fetchSongs({bool overwriteArt = false}) async {
    debugPrint('Fetching songs...');

    await _migrateArtCache();

    final songs = await MediaScanner.getAllAudio();

    final defaultArtPath = await ArtWorkUtils.getCachePath();
    final fallbackArtUri =
        File(await ArtWorkUtils.getDefaultArtPath()).uri.toString();

    final eligible =
        songs.where((song) => song.duration > minDurationMs).toList();

    final musicList = <AudioFile>[];

    // Resolve artwork in small batches: already-cached songs are just a file
    // existence check, while cold-cache songs hit the platform channel. The
    // batches keep a bounded number of retriever calls in flight.
    const batchSize = 8;
    for (var i = 0; i < eligible.length; i += batchSize) {
      final batch = eligible
          .sublist(i, min(i + batchSize, eligible.length))
          .map((song) async {
        final cachedArtPath = await ArtWorkUtils.resolveArtworkPath(
          song,
          defaultArtPath,
          fallbackArtUri,
          overwrite: overwriteArt,
        );
        return song.copyWith(cachedArtPath: cachedArtPath);
      });

      musicList.addAll(await Future.wait(batch));
    }

    await _audioLibrary.replaceSongs(musicList);

    return musicList;
  }

  Future<void> _migrateArtCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_artCacheVersionKey) ?? false) return;

    await ArtWorkUtils.clearLegacyArtCache();
    await prefs.setBool(_artCacheVersionKey, true);
  }
}
