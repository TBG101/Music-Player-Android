import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:metadata_god/metadata_god.dart' as md;
import 'package:mime/mime.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Utils {
  static void androidScanMediaTrigger(String? mp3FilePath) async {
    if (mp3FilePath == null) return;
    MediaScanner.loadMedia(path: mp3FilePath)
        .then((value) => print(value.toString()));
  }

  static void writeMetaData(
      File mp3File, Video myVideo, Uint8List imgBytes, String imgPath) async {
    final metadata = await MetadataRetriever.fromFile(mp3File);
    await md.MetadataGod.writeMetadata(
        file: mp3File.path,
        metadata: md.Metadata(
            title: myVideo.title,
            artist: myVideo.author,
            durationMs: (metadata.trackDuration ?? 0).toDouble(),
            fileSize: mp3File.lengthSync(),
            picture: md.Picture(
                data: imgBytes, mimeType: lookupMimeType(imgPath) ?? "")));
  }

  static String checkVideoTitle(String title) {
    return title
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '');
  }

  static void deleteMusicUri(Uri uri) {
    File.fromUri(uri).deleteSync();
  }
}
