import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';
import 'package:musicplayer/core/paths/app_paths.dart';
import 'package:musicplayer/core/services/media_scanner.dart';

class ArtWorkUtils {
  static const DEFAULT_IMAGE = "NotFound.jpg";

  static Future<void> saveDefaultArt() async {
    final defaultArtPath = "${(await AppPaths.artworkDir).path}/$DEFAULT_IMAGE";

    final ByteData data = await rootBundle.load("assets/img/NotFound.jpg");
    final Uint8List bytes = data.buffer.asUint8List();

    await File(defaultArtPath).writeAsBytes(bytes, flush: true);
  }

  static Future<String> getDefaultArtPath() async {
    return "${(await AppPaths.artworkDir).path}/$DEFAULT_IMAGE";
  }

  static Future<String> getCachePath() async {
    return (await AppPaths.artworkDir).path;
  }

  static Future<String> resolveArtworkPath(
    AudioFile song,
    String cacheDir,
    String fallbackUri, {
    bool overwrite = false,
  }) async {
    // Key per song. MediaStore's album id is not a safe grouping key: tracks
    // without an album tag all share one, so album keying would hand several
    // unrelated songs the same cover.
    final cacheFile = File("$cacheDir/song_${song.id}.jpg");
    // Written when the track provably has no cover so future refreshes skip
    // the MediaMetadataRetriever round trip instead of re-probing every time.
    final noArtMarker = File("$cacheDir/song_${song.id}.none");

    try {
      if (!overwrite) {
        if (await cacheFile.exists() && await cacheFile.length() > 0) {
          return cacheFile.uri.toString();
        }
        if (await noArtMarker.exists()) return fallbackUri;
      }

      final hasArt = await MediaScanner.cacheArtwork(
        song.uri,
        song.albumArt,
        cacheFile.path,
        overwrite: overwrite,
      );

      if (!hasArt) {
        // Remember the miss; also drop a stale file so the fallback renders.
        if (await cacheFile.exists()) await cacheFile.delete();
        await noArtMarker.writeAsString("");
        return fallbackUri;
      }

      if (overwrite) {
        // The file was rewritten; drop the decoded image so the new bytes are
        // used on the next render instead of the stale cached bitmap.
        await FileImage(cacheFile).evict();
        if (await noArtMarker.exists()) await noArtMarker.delete();
      }

      return cacheFile.uri.toString();
    } catch (e) {
      debugPrint("Error caching album art: $e");
      return fallbackUri;
    }
  }

  /// Wipes previously cached artwork (older `<id>.png` and `album_*.jpg`
  /// layouts). Keeps the bundled default image, which is rewritten on launch.
  static Future<void> clearLegacyArtCache() async {
    final dir = await AppPaths.artworkDir;
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is File && !entity.path.endsWith("/$DEFAULT_IMAGE")) {
        try {
          await entity.delete();
        } catch (e) {
          debugPrint("Could not delete legacy art ${entity.path}: $e");
        }
      }
    }
  }
}
