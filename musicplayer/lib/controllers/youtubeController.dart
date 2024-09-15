import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/session_state.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:metadata_god/metadata_god.dart' as md;
import 'package:mime/mime.dart';
import 'package:musicplayer/controllers/Logic.dart';
import 'package:musicplayer/controllers/MusicController.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YoutubeController extends GetxController {
  var loading = false.obs;
  var textController = TextEditingController().obs;
  final saveDownloadPath = Rxn<String>();
  final __notification = AwesomeNotifications();
  var yt = YoutubeExplode();

  final videos = Rxn<VideoSearchList>();

  late SharedPreferences prefs;

  final videoQuee = <Video>[];

  var downloadingVideo = false;

  @override
  void onInit() async {
    // TODO: implement onInit
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    saveDownloadPath.value = prefs.getString('downloadPath');
  }

  Future<void> getSearchResults() async {
    textController.refresh();
    videos.value =
        await (yt.search(textController.value.text).asStream()).first;
    videos.refresh();
    print(videos.value.toString());
    print(videos.value?.length.toString());
  }

  Future<RelatedVideosList?> findMusicRecomendation() async {
    final controller = Get.find<MusicController>();
    final title = controller.musicList[0].title;
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

    videoQuee.add(myVideo);
    downloadingVideo = true;
    while (downloadingVideo == true && videoQuee.isNotEmpty) {
      await downloadVid();
    }
    downloadingVideo = false;
  }

  Future<void> downloadVid() async {
    try {
      final myVideo = videoQuee.last;
      final id = myVideo.id;
      notificationUpdate("fetching data ${myVideo.title}", 0);
      final manifest = await yt.videos.streamsClient.getManifest(id);
      final audiostreamsInfo = manifest.audioOnly;

      final audio = audiostreamsInfo.withHighestBitrate();
      final audioStream = yt.videos.streamsClient.get(audio);

      final filePath =
          "${saveDownloadPath.value!}/${Logic.checkVideoTitle('${myVideo.title}.webm')}";
      final file = File(filePath);

      // Delete the file if exists.
      if (file.existsSync()) {
        file.deleteSync();
      }
      //open the file
      var output = file.openWrite(mode: FileMode.writeOnlyAppend);

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
          notificationUpdate("downloading ${myVideo.title}", progress);
          timePassed = DateTime.now();
        }

        // Write to file.
        output.add(data);
      }
      if (dataDownloaded < fileLength) {
        print("here");
        await output.close();
        notificationFinished(title: "Donwload finished ${myVideo.title}");
        file.delete();
        return;
      }

      output.close();
      final c = Get.find<MusicController>();
      final imgBytes =
          (await http.get(Uri.parse(myVideo.thumbnails.maxResUrl))).bodyBytes;
      final imgPath =
          "${c.savePath.path}/${Logic.checkVideoTitle(myVideo.title)}.jpg";
      if (await File(imgPath).exists() == false) {
        debugPrint("SAVING IMG");
        File(imgPath).writeAsBytes(imgBytes);
      }

      final newFile = File(
          "${saveDownloadPath.value!}/${Logic.checkVideoTitle('${myVideo.title}.mp3')}");
      // final mimeType = lookupMimeType(filePath);

      notificationFinished(title: "Merging to MP4 ${myVideo.title}");

      Completer<bool> complete = Completer<bool>();
      FFmpegKit.executeAsync(
        "-y -i '${file.path}' -vn -f mp3 '${newFile.path}'",
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
      if (!file.existsSync()) {
        file.delete();
        return;
      }
      final metadata = await MetadataRetriever.fromFile(newFile);
      await md.MetadataGod.writeMetadata(
          file: newFile.path,
          metadata: md.Metadata(
              title: myVideo.title,
              artist: myVideo.author,
              durationMs: (metadata.trackDuration ?? 0).toDouble(),
              fileSize: newFile.lengthSync(),
              picture: md.Picture(
                  data: imgBytes, mimeType: lookupMimeType(imgPath) ?? "")));

      androidScanMediaTrigger(newFile.path);
      notificationFinished(title: "Download Finished ${myVideo.title}");

      // might work might not i have no idea
      c.addNewSong(newFile.path);
      c.rescanFiles();
    } catch (e) {
      notificationFinished(title: "Failed to download");
      print(e);
    }

    videoQuee.removeLast();
  }

  void setSavePath(String? newValue) async {
    saveDownloadPath.value = newValue;
    if (newValue != null) await prefs.setString('downloadPath', newValue);

    debugPrint(newValue);
    Permission.manageExternalStorage.status.then((value) => print(value));
  }

  String? getSavePath() {
    return saveDownloadPath.value;
  }

  void notificationFinished({String? title}) {
    __notification.createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        actionType: ActionType.Default,
        title: 'Download Finished',
        body: title,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Message,
        locked: false,
        color: Colors.blue,
      ),
    );
  }

  void notificationUpdate(String title, int progress) {
    __notification.createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        actionType: ActionType.Default,
        title: 'Downloading',
        body: title,
        notificationLayout: NotificationLayout.ProgressBar,
        category: NotificationCategory.Progress,
        progress: progress,
        locked: true,
        color: Colors.blue,
      ),
    );
  }

  void androidScanMediaTrigger(String? mp3FilePath) async {
    if (mp3FilePath == null) return;
    MediaScanner.loadMedia(path: mp3FilePath)
        .then((value) => print(value.toString()));
  }
}
