// https://www.googleapis.com/youtube/v3/search?part=snippet,contentDetail&key=AIzaSyAww7JGtgWljnrXWdpRaf82Br3g8IwD_Ro&type=video&q=jelly

import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:musicplayer/controllers/Logic.dart';
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

  Future<void> downloadVid(int index) async {
    final myVideo = videos.value?[index];
    if (videos.value == null) {
      return;
    }
    if (saveDownloadPath.value == null) return;
    final id = videos.value?[index].id;
    final manifest = await yt.videos.streamsClient.getManifest(id);
    final audiostreamsInfo = manifest.audioOnly;

    final audio = audiostreamsInfo.withHighestBitrate();
    final audioStream = yt.videos.streamsClient.get(audio);

    final fileName =
        "${saveDownloadPath.value!}/${Logic.checkVideoTitle('${myVideo!.title}.mp3')}";
    final file = File(fileName);

    // Delete the file if exists.
    if (file.existsSync()) {
      file.deleteSync();
    }

    final output = file.openWrite(mode: FileMode.writeOnlyAppend);

    // Track the file download status.
    final len = audio.size.totalBytes;
    var count = 0;

    // Create the message and set the cursor position.
    final msg = 'Downloading ${myVideo.title}.${audio.container.name}';
    stdout.writeln(msg);

    // Listen for data received.
    await for (final data in audioStream) {
      // Keep track of the current downloaded data.
      count += data.length;

      // Calculate the current progress.
      final progress = ((count / len) * 100).ceil();

      print(progress.toStringAsFixed(2));

      // Write to file.
      output.add(data);
    }
    await output.close();

    androidScanMediaTrigger(fileName);
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

  void notificationFinished(String title) {
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
