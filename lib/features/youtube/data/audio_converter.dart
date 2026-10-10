import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:musicplayer/core/utils/utils.dart';

import 'audio_downloader.dart';

class AudioConverter {
  Future<File> convertToMp3(
    File sourceFile,
    String title,
    String savePath, {
    File? coverFile,
    String? artist,
    String? album,
    String? genre,
    int? trackNumber,
    int? year,
    Duration? duration,
    void Function(int percent)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (isCancelled?.call() ?? false) {
      throw const DownloadCancelledException();
    }

    final baseName = Utils.sanitizeFileName(title);
    final tempFile = File('$savePath/.$baseName.part.mp3');

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final hasCover =
        coverFile != null && await coverFile.exists();

    final totalMs = duration?.inMilliseconds ?? 0;
    var lastPercent = -1;
    final completer = Completer<void>();
    Timer? cancelWatcher;

    try {
      final arguments = <String>[
        '-y',
        '-i',
        sourceFile.path,
        if (hasCover) ...[
          '-i',
          coverFile.path,
        ],
        '-map',
        '0:a:0',
        if (hasCover) ...[
          '-map',
          '1:v:0',
        ],
        '-map_metadata',
        '-1',
        '-c:a',
        'libmp3lame',
        '-q:a',
        '2',
        if (hasCover) ...[
          '-c:v',
          'mjpeg',
          '-disposition:v:0',
          'attached_pic',
          '-metadata:s:v',
          'title=Album cover',
          '-metadata:s:v',
          'comment=Cover (front)',
        ],
        '-id3v2_version',
        '3',
        '-metadata',
        'title=$title',
        if (artist != null) ...[
          '-metadata',
          'artist=$artist',
        ],
        if (album != null) ...[
          '-metadata',
          'album=$album',
        ],
        if (genre != null) ...[
          '-metadata',
          'genre=$genre',
        ],
        if (trackNumber != null) ...[
          '-metadata',
          'track=$trackNumber',
        ],
        if (year != null) ...[
          '-metadata',
          'date=$year',
        ],
        '-f',
        'mp3',
        tempFile.path,
      ];

      final session = await FFmpegKit.executeWithArgumentsAsync(
        arguments,
        (completedSession) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        null,
        (statistics) {
          if (onProgress == null || totalMs <= 0) return;

          final percent = ((statistics.getTime() / totalMs) * 100)
              .clamp(0, 100)
              .toInt();

          if (percent == lastPercent) return;

          lastPercent = percent;
          onProgress(percent);
        },
      );

      final sessionId = session.getSessionId();

      if (isCancelled != null) {
        cancelWatcher = Timer.periodic(
          const Duration(milliseconds: 500),
          (timer) {
            if (!isCancelled()) return;

            timer.cancel();
            cancelWatcher = null;

            if (sessionId != null) {
              FFmpegKit.cancel(sessionId).catchError(
                (Object _) {},
              );
            }
          },
        );
      }

      await completer.future;

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isCancel(returnCode)) {
        await _deleteQuietly(sourceFile);
        throw const DownloadCancelledException();
      }

      if (!ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput();
        final failStackTrace = await session.getFailStackTrace();

        throw Exception(
          'FFmpeg conversion failed '
          '(code ${returnCode?.getValue()})\n'
          'output: $output\n'
          'failStackTrace: $failStackTrace',
        );
      }

      if (isCancelled?.call() ?? false) {
        await _deleteQuietly(sourceFile);
        throw const DownloadCancelledException();
      }

      final mp3File = await _uniqueTarget(savePath, baseName);

      await tempFile.rename(mp3File.path);
      await _deleteQuietly(sourceFile);

      onProgress?.call(100);

      return mp3File;
    } catch (_) {
      await _deleteQuietly(tempFile);
      rethrow;
    } finally {
      cancelWatcher?.cancel();
    }
  }

  Future<File> _uniqueTarget(
    String savePath,
    String baseName,
  ) async {
    var candidate = File('$savePath/$baseName.mp3');
    var suffix = 2;

    while (await candidate.exists()) {
      candidate = File('$savePath/$baseName ($suffix).mp3');
      suffix++;
    }

    return candidate;
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
