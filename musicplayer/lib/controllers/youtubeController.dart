// https://www.googleapis.com/youtube/v3/search?part=snippet&key=AIzaSyAww7JGtgWljnrXWdpRaf82Br3g8IwD_Ro&type=video&q=jelly

import 'dart:convert';
import 'dart:io';

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
  RxList<dynamic> videos = [].obs;
  var searchData;

  late String _localPath;
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

    _prepareSaveDir();
    try {
      await _findLocalPath().then(
        (value) => Dio().download(
          downloadLink["link"],
          "$value/${downloadLink["title"]}.mp3",
          onReceiveProgress: (count, total) {
            debugPrint(count.toString());
          },
        ),
      );
    } catch (e) {
      debugPrint("--- ERROR DOWNLOADING ---");
    }
  }

  Future<void> _prepareSaveDir() async {
    _localPath = (await _findLocalPath())!;

    print(_localPath);
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
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
}
