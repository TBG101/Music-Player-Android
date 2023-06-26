import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/SongPlayingWidget.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/searchWidget.dart';
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

  void controllerInit() {
    controller.initHandler();
    controller.getSongs();
    controller.getState();
    controller.itemPlaying();
  }

  bool hasPermission = false; 
  @override
  void initState() {
    controllerInit();

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

  String artistSetter(int index) {
    if (controller.textController.value.text.isEmpty) {
      if (controller.musicList[index].artist == "<unknown>") return "No Artist";
      return controller.musicList[index].artist ?? "";
    } else {
      if (controller.filteredList[index].artist == "<unknown>") {
        return "No Artist";
      }
      return controller.filteredList[index].artist ?? "";
    }
  }

  RichText titleWidget() {
    return RichText(
      overflow: TextOverflow.clip,
      textAlign: TextAlign.end,
      textDirection: TextDirection.rtl,
      softWrap: true,
      maxLines: 1,
      textScaleFactor: 1,
      text: const TextSpan(
        text: 'My ',
        style: TextStyle(color: Colors.white, fontSize: 23),
        children: <TextSpan>[
          TextSpan(
              text: 'Music',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
        ],
      ),
    );
  }

  PreferredSizeWidget appbarWdget() {
    return PreferredSize(
        preferredSize: const Size(double.infinity, 60),
        child: SafeArea(
            child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          alignment: Alignment.center,
          child: AnimationSearchBar(
            onChanged: (text) {
              controller.queeUpdate();
              controller.filterList();
            },
            onClosed: () {
              controller.textController.value.clear();
              controller.queeUpdate();
              controller.filterList();
            },
            closeIconColor: Colors.white,
            isBackButtonVisible: false,
            duration: const Duration(milliseconds: 250),
            previousScreen: null,
            backIconColor: Colors.black,
            centerTitle: 'My Music',
            searchIconColor: Colors.white,
            centerTitleStyle:
                const TextStyle(color: Colors.white, fontSize: 18),
            searchTextEditingController: controller.textController.value,
            horizontalPadding: 5,
            centerWidget: titleWidget(),
          ),
        )));
  }

  Widget listViewBuilderWidget(int index) {
    if (controller.textController.value.text.isEmpty &&
        index == controller.musicList.length) {
      return const SizedBox(
        height: 80,
      );
    }
    if (controller.textController.value.text.isNotEmpty &&
        index == controller.filteredList.length) {
      return const SizedBox(
        height: 80,
      );
    }
    return ListTile(
        onTap: () async {
          controller.playSong(index);
        },
        title: Text(controller.textController.value.text.isEmpty
            ? controller.musicList[index].title
            : controller.filteredList[index].title),
        subtitle: Text(artistSetter(index)),
        dense: false,
        leading: controller.artWorkGetter(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbarWdget(),
      body: GetBuilder<MusicController>(builder: (controller) {
        return SafeArea(
            child: controller.hasError.isTrue
                ? const Text("ERROR")
                : controller.musicList.isEmpty || controller.doneInit.isFalse
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            itemCount:
                                controller.textController.value.text.isEmpty
                                    ? controller.musicList.length + 1
                                    : controller.filteredList.length + 1,
                            itemBuilder: (context, index) {
                              return listViewBuilderWidget(index);
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
