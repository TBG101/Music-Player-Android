// https://www.googleapis.com/youtube/v3/search?part=snippet&key=AIzaSyAww7JGtgWljnrXWdpRaf82Br3g8IwD_Ro&type=video&q=jelly

import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';

import 'package:musicplayer/services/keys.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/services.dart';

class YoutubeController extends GetxController {
  var loading = false.obs;
  var textController = TextEditingController().obs;
  final saveDownloadPath = Rxn<String>();
  RxList<dynamic> videos = [].obs;

  int progress = 0;
  late TargetPlatform? platform;
  late final SharedPreferences prefs;

  void controllerInit() async {
    if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }

    prefs = await SharedPreferences.getInstance();
    saveDownloadPath.value = prefs.getString('downloadPath');
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&key=$API_KEY&type=video&q=${textController.value.text}'));
    videos.value = jsonDecode(response.body)["items"];
  }

  Future<void> downloadVid(int index) async {
    var uri = Uri.https("youtube-mp36.p.rapidapi.com", "/dl", {
      "id": videos[index]["id"]["videoId"] as String
    }); // uri to get the video download link

    final response = await http.get(uri, headers: {
      'X-RapidAPI-Key': 'a1db472272msh381390d8c748bf0p123c89jsnc292e2863054',
      'X-RapidAPI-Host': 'youtube-mp36.p.rapidapi.com',
    });

    var downloadLink = jsonDecode(response.body);

    var filePath =
        "${saveDownloadPath.value.toString()}/${parse(downloadLink["title"] as String).body!.text}.mp3";

    debugPrint(downloadLink.toString());
    progress = 0;
    bool downloading = false;
    bool fileExist = await File(filePath).exists();

    if (fileExist) {
      debugPrint('\x1B[31mFILE ALREADY EXIST\x1B[0m');
      return;
    } else if (saveDownloadPath.value == null) {
      debugPrint('\x1B[31mNO SAVE PATH\x1B[0m');
      return;
    } else {
      try {
        downloading = true;
        Dio().download(
          downloadLink["link"],
          filePath,
          onReceiveProgress: (count, total) async {
            progress = ((count / total) * 100).toInt();
            downloading = true;
            debugPrint(progress.toString());
          },
        ).then((value) {
          Future.delayed(const Duration(seconds: 1)).then((value) {
            createFinishedNotification(downloadLink[
                "title"]); // create notification when download ends
            updateMetadata(filePath); // change the metadata of file
            androidScanMediaTrigger(filePath);
          });
          downloading = false;
        });
      } on Exception catch (e) {
        debugPrint("--- ERROR DOWNLOADING ---");
        debugPrint(e.toString());
        downloading = false;
        progress = -1;
      }

      while (downloading == true || (0 < progress && progress < 100)) {
        await Future.delayed(const Duration(milliseconds: 500)).then((value) {
          createdUpdatedNotification(downloadLink["title"]);
        });
      }
    }
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

  void updateMetadata(String fileSavePath) async {
    if (await File(fileSavePath).exists()) {
      Metadata metadata = await MetadataGod.readMetadata(file: fileSavePath);
      print("metadata.album: ${metadata.album}");
      print("metadata.albumArtist: ${metadata.albumArtist}");
      print("metadata.artist: ${metadata.artist}");
      print("metadata.discNumber: ${metadata.discNumber}");
      print("metadata.discTotal: ${metadata.discTotal}");
      print("metadata.durationMs: ${metadata.durationMs}");
      print("metadata.fileSize: ${metadata.fileSize}");
      print("metadata.genre: ${metadata.genre}");
      print("metadata.picture: ${metadata.picture?.mimeType}");
      print("metadata.title: ${metadata.title}");
      print("metadata.trackNumber: ${metadata.trackNumber}");
      print("metadata.trackTotal: ${metadata.trackTotal}");
      print("metadata.year: ${metadata.year}");
    }
  }

  void createFinishedNotification(String title) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        actionType: ActionType.Default,
        title: 'Download Finished',
        body: title,
        notificationLayout: NotificationLayout.ProgressBar,
        category: NotificationCategory.Progress,
        progress: progress.toInt(),
        locked: false,
        color: Colors.blue,
      ),
    );
  }

  void createdUpdatedNotification(String title) {
    AwesomeNotifications().createNotification(
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
    ediaScanner.loadMedia(path: mp3FilePath)
        .then((value) => print(value.toString()));
  }
}
