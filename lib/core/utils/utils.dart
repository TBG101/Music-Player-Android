import 'dart:io';
import 'package:musicplayer/core/services/media_scanner.dart';

class Utils {
  static Future<void> androidScanMediaTrigger(String? mp3FilePath) async {
    if (mp3FilePath == null) return;
    await MediaScanner.scanFile(mp3FilePath);
  }

  static String sanitizeFileName(String input) {
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    String sanitized = input.replaceAll(invalidChars, '_');

    if (sanitized.length > 255) {
      sanitized = sanitized.substring(0, 255);
    }

    return sanitized;
  }

  static Future<void> deleteMusicUri(Uri uri) async {
    if (uri.scheme == 'content') {
      // MediaStore entry: delete through the content resolver so the file and
      // its MediaStore row both go away.
      await MediaScanner.deleteMedia(uri.toString());
    } else {
      await File.fromUri(uri).delete();
    }
  }

  static String formatDurationToMinutesAndSeconds(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}
