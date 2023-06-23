import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:musicplayer/controllers/MusicController.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MusicController controller =
      Get.put(MusicController()); // music GetX controller

  final OnAudioQuery _audioQuery = OnAudioQuery(); // audio query to get music

  final _audioHandler = GetIt.instance<AudioHandler>();

  Future<bool> requestPermission() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
      return true;
    } else {
      return true;
    }
  }

  bool hasPermission = false;
  @override
  void initState() {
    controller.getSongs();
    requestPermission().then((value) {
      setState(() {
        hasPermission = value;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 8,
          title: const Text("data"),
        ),
        body: !hasPermission
            ? const Center(child: Text("NO PERMISSION"))
            : SafeArea(
                child: ListView.builder(
                itemCount: controller.musicList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      Uri? art = null;
                      await _audioQuery
                          .queryArtwork(
                              controller.musicList[index].id, ArtworkType.AUDIO,
                              format: ArtworkFormat.JPEG,
                              size: 500,
                              quality: 500)
                          .then((value) async {
                        if (value == null) return;
                        var savePath = await getApplicationDocumentsDirectory();

                        await File(
                                "${savePath.path}${controller.musicList[index].title}.jpg")
                            .writeAsBytes(value)
                            .then((value) => art = (value.uri));
                      });
                      String? _path = controller.musicList[index].uri;

                      var _item = MediaItem(
                        id: _path!,
                        title: controller.musicList[index].title,
                        artist: controller.musicList[index].artist,
                        album: controller.musicList[index].album,
                        artUri: art,
                        duration: Duration(
                            milliseconds:
                                controller.musicList[index].duration ?? 0),
                      );

                      _audioHandler.playMediaItem(_item);
                    },

                    title: Text(controller.musicList[index].title),
                    subtitle:
                        Text(controller.musicList[index].artist ?? "No Artist"),

                    dense: false,

                    // This Widget will query/load image.
                    // You can use/create your own widget/method using [queryArtwork].
                    leading: QueryArtworkWidget(
                      controller: _audioQuery,
                      id: controller.musicList![index].id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget:
                          Image.asset("lib/assets/img/NotFound.JPG"),
                    ),
                  );
                },
              )));
  }
}
