import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:musicplayer/core/utils/utils.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class ThumbnailService {
  Future<Uint8List?> _downloadThumbnail(Video video) async {
    final urls = [
      video.thumbnails.maxResUrl,
      video.thumbnails.highResUrl,
      video.thumbnails.standardResUrl,
      video.thumbnails.mediumResUrl,
      video.thumbnails.standardResUrl,
      video.thumbnails.lowResUrl,
    ];

    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (_) {
        // Try the next thumbnail.
      }
    }

    return null;
  }

  Future<String?> saveThumbnail(
    Video video,
    String savePath,
  ) async {
    final imgBytes = await _downloadThumbnail(video);

    if (imgBytes == null) {
      return null;
    }

    final imgPath = "$savePath/${Utils.sanitizeFileName(video.title)}.jpg";

    final file = File(imgPath);

    if (!await file.exists()) {
      await file.writeAsBytes(imgBytes);
    }

    return imgPath;
  }

  Future<Uint8List?> getThumbnailBytes(Video video) {
    return _downloadThumbnail(video);
  }
}
