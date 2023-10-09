// https://www.googleapis.com/youtube/v3/search?part=snippet&key=AIzaSyAww7JGtgWljnrXWdpRaf82Br3g8IwD_Ro&type=video&q=jelly

import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:musicplayer/services/keys.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class youtubeController extends GetxController {
  var loading = false.obs;
  var textController = TextEditingController().obs;
  final saveDownloadPath = Rxn<String>();
  RxList<dynamic> videos = [].obs;
  var searchData;

  double progress = 0;
  late TargetPlatform? platform;

  void controllerInit() {
    if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&key=$API_KEY&type=video&q=${textController.value.text}'));
    videos.value = jsonDecode(response.body)["items"];
  }

  Future<void> downloadVid(
    int index,
  ) async {
    var uri = Uri.https("youtube-mp36.p.rapidapi.com", "/dl",
        {"id": videos[index]["id"]["videoId"] as String});
    final response = await http.get(uri, headers: {
      'X-RapidAPI-Key': 'a1db472272msh381390d8c748bf0p123c89jsnc292e2863054',
      'X-RapidAPI-Host': 'youtube-mp36.p.rapidapi.com',
    });

    var downloadLink = jsonDecode(response.body);
    print(downloadLink.toString());

    try {
      Dio().download(
        downloadLink["link"],
        "${saveDownloadPath.value}/${downloadLink["title"]}.mp3",
        onReceiveProgress: (count, total) async {
          progress = ((count / total) * 100);
          print(progress);

          await Future.delayed(Duration(seconds: 1)).then((value) {
            if (count <= total) {
              AwesomeNotifications().createNotification(
                content: NotificationContent(
                    id: 10,
                    channelKey: 'basic_channel',
                    actionType: ActionType.Default,
                    title: 'Download Finished',
                    body: 'Finished ${downloadLink["title"]}',
                    notificationLayout: NotificationLayout.ProgressBar,
                    category: NotificationCategory.Progress,
                    progress: progress.toInt(),
                    locked: false),
              );
            } else {
              AwesomeNotifications().createNotification(
                content: NotificationContent(
                    id: 10,
                    channelKey: 'basic_channel',
                    actionType: ActionType.Default,
                    title: 'Downloading',
                    body: '${downloadLink["title"]}',
                    notificationLayout: NotificationLayout.ProgressBar,
                    category: NotificationCategory.Progress,
                    progress: progress.toInt(),
                    locked: true,
                    color: Colors.white,
                    customSound: "lib/assetes/sound/uwu.mp3"),
              );
            }
          });
        },
      );
    } catch (e) {
      debugPrint("--- ERROR DOWNLOADING ---");
      debugPrint(e.toString());
    }
  }

  Future<String?> _findLocalPath() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // If not we will ask for permission first
      await Permission.storage.request();
    }
    if (platform == TargetPlatform.android) {
      // return "/storage/emulated/0/Download";
      return "/storage/emulated/0/Download";
    } else {
      var directory = await getApplicationDocumentsDirectory();
      return '${directory.path}${Platform.pathSeparator}Download';
    }
  }

  void setSavePath(String? newValue) {
    saveDownloadPath.value = newValue;
    debugPrint(newValue);
    Permission.manageExternalStorage.status.then((value) => print(value));
  }

  String? getSavePath() {
    return saveDownloadPath.value;
  }
}
