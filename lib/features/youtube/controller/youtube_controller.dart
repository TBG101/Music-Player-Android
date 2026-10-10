import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/youtube/data/download_queue.dart';
import 'package:musicplayer/features/youtube/data/download_task.dart';
import 'package:musicplayer/features/youtube/data/audio_converter.dart';
import 'package:musicplayer/features/youtube/data/audio_downloader.dart';
import 'package:musicplayer/features/youtube/data/thumbnail_service.dart';
import 'package:musicplayer/features/youtube/data/youtube_manifest_service.dart';
import 'package:musicplayer/features/youtube/data/youtube_stream_client.dart';
import 'package:musicplayer/core/services/notification_manager.dart';
import 'package:musicplayer/core/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YoutubeController extends GetxController {
  final c = Get.find<LibraryController>();
  var notificationManager = NotificationManager();
  final _audioDownloader = AudioDownloader();
  final _audioConverter = AudioConverter();
  final _thumbnailService = ThumbnailService();
  final _manifestService = YoutubeManifestService();

  var loading = false.obs;
  var textController = TextEditingController().obs;
  final saveDownloadPath = Rxn<String>();
  final yt = YoutubeExplode(httpClient: AndroidStreamHttpClient());
  final downloadQueue = DownloadQueue();
  final videos = Rxn<VideoSearchList>();

  late SharedPreferences prefs;

  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    saveDownloadPath.value = prefs.getString('downloadPath');
  }

  Future<void> getSearchResults() async {
    textController.refresh();
    final result =
        await (yt.search(textController.value.text).asStream()).first;
    videos.value = result;
    videos.refresh();
  }

  Future<VideoSearchList?> findMusicRecomendation({int videoIndex = 0}) async {
    assert(videoIndex >= 0);

    final controller = Get.find<LibraryController>();
    final title = controller.musicList[videoIndex].title;
    return await yt.search(title ?? "").asStream().first;
  }

  Future<void> addVideoToQuee(int index, List<Video> listOfVideos) async {
    late final Video? myVideo;

    if (listOfVideos.isEmpty) {
      myVideo = videos.value?[index];
    } else {
      myVideo = listOfVideos[index];
    }
    if (myVideo == null) return;

    if (saveDownloadPath.value == null) {
      final picked = await pickSavePath();
      if (picked == null) return;
    }

    final activeStatuses = {
      DownloadStatus.queued,
      DownloadStatus.downloading,
      DownloadStatus.converting,
    };
    final existing = downloadQueue.byVideoId(myVideo.id.toString());
    if (existing != null && activeStatuses.contains(existing.status)) return;

    downloadQueue.addTask(
      DownloadTask(
        videoId: myVideo.id.toString(),
        title: myVideo.title,
        thumbnailUrl: myVideo.thumbnails.mediumResUrl,
      ),
      () => downloadVideo(myVideo!),
    );
  }

  Future<void> downloadVideo(Video myVideo) async {
    final videoId = myVideo.id.toString();
    final currentNotificationId =
        NotificationManager.notificationIdForVideo(videoId);
    try {
      downloadQueue.setStatus(videoId, DownloadStatus.downloading);
      notificationManager.showDownloadProgress(
        notificationId: currentNotificationId,
        videoId: videoId,
        videoTitle: myVideo.title,
        progress: 0,
        stageLabel: 'Fetching stream data…',
      );

      final manifest = await yt.videos.streamsClient.getManifest(myVideo.id);
      final candidates = _manifestService.selectAudioSources(manifest);
      final sourceFile = await _audioDownloader.downloadFirstAvailable(
        candidates,
        (streamInfo) => yt.videos.streamsClient.get(streamInfo),
        saveDownloadPath.value!,
        myVideo.title,
        isCancelled: () => downloadQueue.isCancelled(videoId),
        onProgress: (downloadedBytes, totalBytes) {
          final progress = totalBytes > 0
              ? ((downloadedBytes / totalBytes) * 100).clamp(0, 100).toInt()
              : 0;
          print(
              "Download progress: $downloadedBytes of $totalBytes bytes ($progress%)");
          downloadQueue.updateProgress(videoId,
              percent: progress,
              downloadedBytes: downloadedBytes,
              totalBytes: totalBytes);
          notificationManager.showDownloadProgress(
            notificationId: currentNotificationId,
            videoId: videoId,
            videoTitle: myVideo.title,
            progress: progress,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            thumbnailUrl: myVideo.thumbnails.mediumResUrl,
          );
        },
      );

      downloadQueue.setStatus(videoId, DownloadStatus.converting);
      notificationManager.showConverting(
        notificationId: currentNotificationId,
        videoId: videoId,
        videoTitle: myVideo.title,
        thumbnailUrl: myVideo.thumbnails.mediumResUrl,
      );
      final file = await _thumbnailService.saveThumbnail(
          myVideo, saveDownloadPath.value!);

      final mp3File = await _audioConverter.convertToMp3(
        sourceFile,
        myVideo.title,
        saveDownloadPath.value!,
        duration: myVideo.duration,
        coverFile: file != null ? File(file) : null,
        artist: myVideo.author,
        year: myVideo.publishDate?.year,
        album: myVideo.musicData.isNotEmpty
    ? myVideo.musicData[0].album
    : null,
        isCancelled: () => downloadQueue.isCancelled(videoId),
        onProgress: (percent) {
          notificationManager.showConverting(
            notificationId: currentNotificationId,
            videoId: videoId,
            videoTitle: myVideo.title,
            percent: percent,
            thumbnailUrl: myVideo.thumbnails.mediumResUrl,
          );
        },
      );



      if (downloadQueue.isCancelled(videoId)) {
        throw const DownloadCancelledException();
      }


      final previousPath = prefs.getString(_downloadedPathKey(videoId));
      if (previousPath != null && previousPath != mp3File.path) {
        final previousFile = File(previousPath);
        if (await previousFile.exists()) {
          await previousFile.delete();
        }
      }
      await prefs.setString(_downloadedPathKey(videoId), mp3File.path);

      await Utils.androidScanMediaTrigger(mp3File.path);

      await c.addNewSong();

      downloadQueue.setStatus(videoId, DownloadStatus.completed);
      notificationManager.showDownloadFinished(
        notificationId: currentNotificationId,
        videoId: videoId,
        videoTitle: myVideo.title,
        totalBytes: await mp3File.length(),
        thumbnailUrl: myVideo.thumbnails.mediumResUrl,
      );
    } on DownloadCancelledException {
      downloadQueue.setStatus(videoId, DownloadStatus.cancelled);
      await notificationManager.dismissDownload(currentNotificationId);
    } catch (e) {
      downloadQueue.setStatus(videoId, DownloadStatus.failed);
      notificationManager.showDownloadFailed(
        notificationId: currentNotificationId,
        videoId: videoId,
        videoTitle: myVideo.title,
        error: e.toString(),
        thumbnailUrl: myVideo.thumbnails.mediumResUrl,
      );
    }
  }

  String _downloadedPathKey(String videoId) => 'downloaded_path_$videoId';

  void setSavePath(String? newValue) async {
    if (newValue == null) return;
    saveDownloadPath.value = newValue;
    await prefs.setString('downloadPath', newValue);

    debugPrint(newValue);
    Permission.manageExternalStorage.status.then((value) => print(value));
  }

  /// Opens the system folder picker, persists the choice and returns it.
  /// Returns null when the user cancels, so callers can abort the download.
  Future<String?> pickSavePath() async {
    final downloadPath = await FilePicker.getDirectoryPath();
    setSavePath(downloadPath);
    return downloadPath;
  }

  @override
  void onClose() {
    yt.close();
    super.onClose();
  }
}
