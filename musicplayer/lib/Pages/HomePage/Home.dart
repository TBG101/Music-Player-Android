import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/SongPlayingWidget.dart';
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
    controller.initHandler();
    controller.getSongs();
    controller.getState();
    controller.itemPlaying();

    requestPermission().then((value) {
      setState(() {
        hasPermission = value;
      });
    });

    super.initState();
  }

  Alignment boxAligment() {
    if (controller.song.value == null) {
      return const Alignment(1.25, 1.25);
    } else {
      return Alignment.bottomCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 8,
          toolbarHeight: 70,
          title: TextField(
            controller: controller.textController.value,
            onChanged: (value) {
              controller.filterList();
            },
          )),
      body: GetBuilder<MusicController>(builder: (controller) {
        return SafeArea(
            child: controller.hasError.isTrue
                ? const Text("ERROR")
                : controller.musicList.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            itemCount:
                                controller.textController.value.text.isEmpty
                                    ? controller.musicList.length
                                    : controller.filteredList.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                  onTap: () async {
                                    controller.playSong(index);
                                  },
                                  title: Text(controller
                                          .textController.value.text.isEmpty
                                      ? controller.musicList[index].title
                                      : controller.filteredList[index].title),
                                  subtitle: Text(controller
                                          .textController.value.text.isEmpty
                                      ? controller.musicList[index].artist ??
                                          "No Artist"
                                      : controller.filteredList[index].artist ??
                                          "No Artist"),
                                  dense: false,
                                  leading: controller.artWorkGetter(index));
                            },
                          ),
                          Obx(() {
                            return Visibility(
                              visible: controller.visible.value,
                              child: AnimatedAlign(
                                curve: Curves.ease,
                                alignment: boxAligment(),
                                duration: const Duration(milliseconds: 500),
                                child: SongPlayingWdiget(),
                              ),
                            );
                          })
                        ],
                      ));
      }),
    );
  }
}
