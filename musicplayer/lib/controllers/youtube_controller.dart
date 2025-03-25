import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/session_state.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/controllers/music_controller.dart';
import 'package:musicplayer/models/task_quee.dart';
import 'package:musicplayer/utils/notification_manager.dart';
import 'package:musicplayer/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YoutubeController extends GetxController {
  final c = Get.find<MusicController>();
  var notificationManager = NotificationManager();

  var loading = false.obs;
  var textController = TextEditingController().obs;
  final saveDownloadPath = Rxn<String>();
  final yt = YoutubeExplode();
  final downloadQuee = TaskQuee();
  final videos = Rxn<VideoSearchList>();

  late SharedPreferences prefs;

  final videoQuee = <Video>[];

  var downloadingVideo = false;

  var __notificationId = 0;

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

  Future<RelatedVideosList?> findMusicRecomendation(
      {int videoIndex = 0}) async {
    assert(videoIndex >= 0);

    final controller = Get.find<MusicController>();
    final title = controller.musicList[videoIndex].title;
    final listOfVideos = await yt.search(title).asStream().first;
    return yt.videos.getRelatedVideos(listOfVideos[0]);
  }

  Future<void> addVideoToQuee(int index, List<Video> listOfVideos) async {
    late final Video? myVideo;

    if (listOfVideos.isEmpty) {
      myVideo = videos.value?[index];
    } else {
      myVideo = listOfVideos[index];
    }
    if (videos.value == null ||
        myVideo == null ||
        saveDownloadPath.value == null) return;

    downloadQuee.addTask(() => {downloadVideo(myVideo!)});
    downloadQuee.startQuee();
  }

  Future<void> downloadVideo(Video myVideo) async {
    final currentNotificationId = __notificationId++;
    try {
      notificationManager.notificationUpdate(
          "fetching data ${myVideo.title}", 0, currentNotificationId);

      final manifest = await yt.videos.streamsClient.getManifest(myVideo.id);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      final audioStream = yt.videos.streamsClient.get(audioStreamInfo);

      final webmFile = await _prepareFile(myVideo.title, 'webm');
      final fileLength = audioStreamInfo.size.totalBytes;

      await _downloadAudioStream(audioStream, webmFile, fileLength,
          myVideo.title, currentNotificationId);

      final mp3File =
          await _convertToMp3(webmFile, myVideo.title, currentNotificationId);

      final imgPath = await _saveThumbnail(myVideo);

      Utils.writeMetaData(
          mp3File, myVideo, await File(imgPath).readAsBytes(), imgPath);

      Utils.androidScanMediaTrigger(mp3File.path);

      notificationManager.showNotificationInfo(
          "Download Finished", currentNotificationId);
    } catch (e) {
      notificationManager.showNotificationInfo(
          "Failed to download", currentNotificationId,
          body: e.toString());
    }
    videoQuee.removeLast();
    
  }

  Future<File> _prepareFile(String title, String extension) async {
    final filePath =
        "${saveDownloadPath.value!}/${Utils.sanitizeFileName('$title.$extension')}";
    final file = File(filePath);

    if (file.existsSync()) {
      file.deleteSync();
    }

    return file;
  }

  Future<void> _downloadAudioStream(Stream<List<int>> audioStream,
      File webmFile, int fileLength, String title, int notificationId) async {
    final output = webmFile.openWrite(mode: FileMode.writeOnlyAppend);
    var dataDownloaded = 0;
    final msg = 'Downloading $title.webm';
    var timePassed = DateTime.now();

    await for (final data in audioStream) {
      dataDownloaded += data.length;
      final progress = ((dataDownloaded / fileLength) * 100).ceil();

      if (DateTime.now().isAfter(timePassed.add(const Duration(seconds: 1)))) {
        notificationManager.notificationUpdate(msg, progress, notificationId);
        timePassed = DateTime.now();
      }

      output.add(data);
    }

    await output.close();

    if (dataDownloaded < fileLength) {
      notificationManager.showNotificationInfo(
          "Failed to download", notificationId,
          body: "Download failed");
      webmFile.deleteSync();
      throw Exception("Incomplete download");
    }
  }

  Future<File> _convertToMp3(
      File webmFile, String title, int notificationId) async {
    final mp3File = await _prepareFile(title, 'mp3');
    notificationManager.showNotificationInfo(
        "Merging to MP3 $title", notificationId);

    final completer = Completer<bool>();
    FFmpegKit.executeAsync(
      "-y -i '${webmFile.path}' -vn -f mp3 '${mp3File.path}'",
      (session) async {
        final state = await session.getState();
        if (state == SessionState.completed) {
          completer.complete(true);
        } else if (state == SessionState.failed) {
          completer.complete(false);
        }
      },
      (log) => print(log.getMessage()),
    );

    final success = await completer.future;
    if (!success) {
      throw Exception("Couldn't convert to mp3 file with ffmpeg");
    }

    webmFile.deleteSync();
    return mp3File;
  }

  Future<String> _saveThumbnail(Video myVideo) async {
    final c = Get.find<MusicController>();
    final imgBytes =
        (await http.get(Uri.parse(myVideo.thumbnails.maxResUrl))).bodyBytes;
    final imgPath =
        "${c.savePath.path}/${Utils.sanitizeFileName(myVideo.title)}.jpg";

    if (!await File(imgPath).exists()) {
      File(imgPath).writeAsBytesSync(imgBytes);
    }

    return imgPath;
  }

  void setSavePath(String? newValue) async {
    saveDownloadPath.value = newValue;
    if (newValue != null) await prefs.setString('downloadPath', newValue);

    debugPrint(newValue);
    Permission.manageExternalStorage.status.then((value) => print(value));
  }

  @override
  void onClose() {
    yt.close();
    super.onClose();
  }
}
