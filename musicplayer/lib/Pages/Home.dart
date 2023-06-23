import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/controllers/MusicController.dart';

import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MusicController controller =
      Get.put(MusicController()); // music GetX controller

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
                child: controller.musicList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : controller.hasError.isTrue
                        ? const Text("ERROR")
                        : ListView.builder(
                            itemCount: controller.musicList.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                  onTap: () async {
                                    controller.playSong(index);
                                  },
                                  title:
                                      Text(controller.musicList[index].title),
                                  subtitle: Text(
                                      controller.musicList[index].artist ??
                                          "No Artist"),
                                  dense: false,

                                  // This Widget will query/load image.
                                  // You can use/create your own widget/method using [queryArtwork].
                                  leading: controller.artWorkGetter(index));
                            },
                          )));
  }
}
