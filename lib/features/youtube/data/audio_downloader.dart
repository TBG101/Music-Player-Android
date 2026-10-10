import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musicplayer/core/utils/utils.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadCancelledException implements Exception {
  const DownloadCancelledException();

  @override
  String toString() => 'Download cancelled';
}

class AudioDownloader {
  final http.Client _http = http.Client();

  File prepareFile(String savePath, String title, String extension) {
    final filePath = "$savePath/${Utils.sanitizeFileName('$title.$extension')}";
    final file = File(filePath);

    if (file.existsSync()) {
      file.deleteSync();
    }

    return file;
  }

  /// googlevideo returns 403 for stream URLs which require a PO token.
  /// Checking with HEAD fails fast instead of letting the stream client
  /// silently refetch the manifest before every 403 and never yield bytes.
  Future<bool> isServing(StreamInfo stream) async {
    try {
      final response = await _http.head(stream.url, headers: {
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36',
      });
      return response.statusCode < 400;
    } on Exception {
      return false;
    }
  }

  /// Downloads the first candidate stream that is actually being served.
  /// Candidates are ordered by preference (audio-only preferred over muxed).
  Future<File> downloadFirstAvailable(
    List<StreamInfo> candidateStreams,
    Stream<List<int>> Function(StreamInfo stream) getStream,
    String savePath,
    String title, {
    void Function(int downloadedBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    Object? lastError;
    for (final stream in candidateStreams) {
      final serving = await isServing(stream);
      print(
          "Stream ${stream.tag} (${stream.container.name}): serving=$serving");
      if (!serving) {
        lastError = "Stream ${stream.tag} is not serving bytes";
        continue;
      }

      try {
        final sourceFile = prepareFile(savePath, title, stream.container.name);
        await downloadAudioStream(
          () => getStream(stream),
          sourceFile,
          stream.size.totalBytes,
          onProgress: onProgress,
          isCancelled: isCancelled,
        );
        return sourceFile;
      } on DownloadCancelledException {
        rethrow;
      } catch (e) {
        lastError = "Stream ${stream.tag} failed: $e";
        print(lastError);
      }
    }
    throw Exception("Download failed: $lastError");
  }

  Future<void> downloadAudioStream(
    Stream<List<int>> Function() streamFactory,
    File file,
    int fileLength, {
    void Function(int downloadedBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    const maxAttempts = 3;
    const stallTimeout = Duration(seconds: 60);

    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (isCancelled?.call() ?? false) {
        throw const DownloadCancelledException();
      }
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
        final output = file.openWrite();
        var dataDownloaded = 0;
        print(
            "Attempt $attempt: starting download of ${file.path} with expected size $fileLength bytes");

        try {
          await for (final data in streamFactory().timeout(stallTimeout)) {
            if (isCancelled?.call() ?? false) {
              throw const DownloadCancelledException();
            }
            dataDownloaded += data.length;
            onProgress?.call(dataDownloaded, fileLength);
            output.add(data);
          }
        } finally {
          await output.close();
        }

        if (dataDownloaded < fileLength) {
          lastError =
              "Incomplete download: received $dataDownloaded of $fileLength bytes";
          print(lastError);
          continue;
        }
        return;
      } on DownloadCancelledException {
        if (file.existsSync()) {
          file.deleteSync();
        }
        rethrow;
      } catch (e) {
        lastError = "Attempt $attempt error: $e";
        print(lastError);
      }
    }

    if (file.existsSync()) {
      file.deleteSync();
    }
    throw Exception("Download failed: $lastError");
  }
}
