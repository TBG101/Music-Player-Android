import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';

class MediaScanner {
  static const mediaScan = MethodChannel('music.player/utils/scanMedia');

  // Handled on a native background task queue: the MediaStore query and the
  // MediaMetadataRetriever extraction are far too heavy for the platform main
  // thread, where they would stall frames for the whole background sync.
  static const heavyScan = MethodChannel('music.player/utils/heavyScan');

  static Future<void> scanFile(String path) async {
    await mediaScan.invokeMethod('scanMedia', {
      'mp3FilePath': path,
    });
  }

  static Future<List<AudioFile>> getAllAudio() async {
    final String res = await heavyScan.invokeMethod("getAllAudio");

    // Decode the whole-library payload off the UI isolate; for large libraries
    // jsonDecode of one big string is a visible frame drop on the main isolate.
    final List data = await Isolate.run(() => jsonDecode(res) as List);
    return data
        .map((e) => AudioFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteMedia(String audioUri) async {
    await mediaScan.invokeMethod("deleteAudio", {
      "audioUri": audioUri,
    });
  }

  /// Caches [audioUri]'s cover to [cachePath]. Returns true when the file is
  /// usable afterwards, false when the track has no embedded/album art.
  static Future<bool> cacheArtwork(
    String audioUri,
    String? artUri,
    String cachePath, {
    bool overwrite = true,
  }) async {
    try {
      await heavyScan.invokeMethod("cacheArtwork", {
        "audioUri": audioUri,
        "artUri": artUri,
        "cachePath": cachePath,
        "overwrite": overwrite,
      });
      return true;
    } on PlatformException catch (e) {
      // The native side reports "no art available" as an error; it is a
      // normal outcome, not a failure.
      if (e.code == "CACHE_FAILED") return false;
      rethrow;
    }
  }
}
