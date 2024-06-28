import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/SongPlayingWidget.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/searchWidget.dart';
import 'package:musicplayer/Pages/YoutubePage/youtubeHomePage.dart';
import 'package:musicplayer/controllers/MusicController.dart';
import 'package:musicplayer/controllers/youtubeController.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MusicController controller =
      Get.find<MusicController>(); // music GetX controller
  final YoutubeController ytController =
      Get.find<YoutubeController>(); // music GetX controller

  bool hasPermission = false;
  var scaffoldKey = GlobalKey<ScaffoldState>();

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
        preferredSize: const Size(double.infinity, 65),
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
            isBackButtonVisible: true,
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
            onDrawerOpen: () {
              scaffoldKey.currentState?.openDrawer();
            },
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

  SafeArea drawerList() {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => YoutubeHomePage()));
            },
            child: const SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "YouTube",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          const Divider(),
          const Spacer(),
          const Divider(),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () {
                if (controller.doneInit.isTrue) {
                  controller.audioHandler.stop();
                  controller.initFalse();
                  controller.rescanFiles();
                  scaffoldKey.currentState?.closeDrawer();
                }
              },
              child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    "Rescan Files ?",
                    style: TextStyle(fontSize: 18),
                  )),
            ),
          ),
        ],
      ),
    ));
  }

  DateTime timeBackPressed = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final difference = DateTime.now().difference(timeBackPressed);
        final IsExistWaning = difference >= const Duration(seconds: 2);
        timeBackPressed = DateTime.now();
        if (IsExistWaning) {
          const msg = "Press back button again";
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            width: 200,
            duration: Duration(seconds: 2),
            shape: StadiumBorder(),
            behavior: SnackBarBehavior.floating,
            content: Text(
              msg,
              textAlign: TextAlign.center,
            ),
          ));
          return false;
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          return true;
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        drawer: Drawer(
          child: drawerList(),
        ),
        appBar: appbarWdget(),
        body: GetBuilder<MusicController>(
            init: controller,
            builder: (controller) {
              return SafeArea(
                  child: controller.doneInit.isFalse
                      ? Center(
                          child: Obx(() => Text(
                              "${controller.musicCountcurrent}/${controller.musicCount}")))
                      : controller.hasError.isTrue
                          ? const Text("ERROR")
                          : controller.musicList.isEmpty
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : Stack(
                                  children: [
                                    ListView.builder(
                                      itemCount: controller
                                              .textController.value.text.isEmpty
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
                                          duration:
                                              const Duration(milliseconds: 500),
                                          child: SongPlayingWdiget(),
                                        ),
                                      );
                                    })
                                  ],
                                ));
            }),
      ),
    );
  }
}
