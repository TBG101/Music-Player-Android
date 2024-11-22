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
    // TODO: implement onInit
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

    downloadQuee.addTask(() => {downloadVid(myVideo!)});
    downloadQuee.startQuee();
  }

  Future<void> downloadVid(Video myVideo) async {
    final currentNotificationId = __notificationId++;
    try {
      final id = myVideo.id;
      notificationManager.notificationUpdate(
          "fetching data ${myVideo.title}", 0, currentNotificationId);

      final manifest = await yt.videos.streamsClient.getManifest(id);
      final audiostreamsInfo = manifest.audioOnly;

      final audio = audiostreamsInfo.withHighestBitrate();
      final audioStream = yt.videos.streamsClient.get(audio);

      final filePath =
          "${saveDownloadPath.value!}/${Utils.sanitizeFileName('${myVideo.title}.webm')}";

      final webmFile = File(filePath);

      // Delete the file if exists.
      if (webmFile.existsSync()) {
        webmFile.deleteSync();
      }

      //open the file
      var output = webmFile.openWrite(mode: FileMode.writeOnlyAppend);

      // Track the file download status.
      final fileLength = audio.size.totalBytes;
      var dataDownloaded = 0;

      // Create the message and set the cursor position.
      final msg = 'Downloading ${myVideo.title}.${audio.container.name}';
      stdout.writeln(msg);
      var timePassed = DateTime.now();
      // Listen for data received.
      await for (final data in audioStream) {
        // Keep track of the current downloaded data.
        dataDownloaded += data.length;
        final progress = ((dataDownloaded / fileLength) * 100).ceil();
        if (DateTime.now()
            .isAfter(timePassed.add(const Duration(seconds: 1)))) {
          notificationManager.notificationUpdate(
              msg, progress, currentNotificationId);
          // notificationUpdate("downloading ${myVideo.title}", progress);
          timePassed = DateTime.now();
        }

        // Write to file.
        output.add(data);
      }
      if (dataDownloaded < fileLength) {
        print("here");
        await output.close();
        notificationManager.showNotificationInfo(
            "Failed to download", currentNotificationId,
            body: "Download failed");
        webmFile.delete();
        return;
      }

      output.close();
      final c = Get.find<MusicController>();

      final imgBytes =
          (await http.get(Uri.parse(myVideo.thumbnails.maxResUrl))).bodyBytes;

      final imgPath =
          "${c.savePath.path}/${Utils.sanitizeFileName(myVideo.title)}.jpg";

      if (await File(imgPath).exists() == false) {
        debugPrint("SAVING IMG");
        File(imgPath).writeAsBytes(imgBytes);
      }

      final mp3File = File(
          "${saveDownloadPath.value!}/${Utils.sanitizeFileName('${myVideo.title}.mp3')}");

      notificationManager.showNotificationInfo(
          "Merging to MP4 ${myVideo.title}", currentNotificationId);

      Completer<bool> complete = Completer<bool>();

      FFmpegKit.executeAsync(
        "-y -i '${webmFile.path}' -vn -f mp3 '${mp3File.path}'",
        (session) async {
          final x = await session.getState();
          if (x == SessionState.running) return;
          if (x == SessionState.completed) {
            print("complected");
            complete.complete(true);
          } else if (x == SessionState.failed) {
            complete.completeError(false);
            print(("error mergin"));
          }
        },
        (log) {
          print(log.getMessage().toString());
        },
      );

      final bool res = await complete.future;

      if (res == false) {
        throw Exception("couldn't convert to mp3 file with ffmpeg");
      }

      if (webmFile.existsSync()) {
        webmFile.delete();
      }

      Utils.writeMetaData(mp3File, myVideo, imgBytes, imgPath);

      Utils.androidScanMediaTrigger(mp3File.path);

      notificationManager.showNotificationInfo(
          "Download Finished", currentNotificationId);

      // recheck all the files
      c.addNewSong();
    } catch (e) {
      notificationManager.showNotificationInfo(
          "Failed to download", currentNotificationId,
          body: e.toString());
    }
    videoQuee.removeLast();
  }

  void setSavePath(String? newValue) async {
    saveDownloadPath.value = newValue;
    if (newValue != null) await prefs.setString('downloadPath', newValue);

    debugPrint(newValue);
    Permission.manageExternalStorage.status.then((value) => print(value));
  }
}
