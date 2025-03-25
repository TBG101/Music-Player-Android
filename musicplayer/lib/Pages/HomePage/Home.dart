import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/searchWidget.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/expandable_screen.dart';
import 'package:musicplayer/Pages/YoutubePage/youtubeHomePage.dart';
import 'package:musicplayer/controllers/music_controller.dart';
import 'package:musicplayer/controllers/youtube_controller.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MusicController controller = Get.find<MusicController>();
  final YoutubeController ytController = Get.find<YoutubeController>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Alignment _getBoxAlignment() => controller.song.value == null
      ? const Alignment(1.25, 1.25)
      : Alignment.bottomCenter;

  String _getArtistName(int index) {
    final list = controller.textController.value.text.isEmpty
        ? controller.musicList
        : controller.filteredList;
    final artist = list[index].artist;
    return (artist == "<unknown>" || artist == null) ? "No Artist" : artist;
  }

  RichText _buildTitleWidget() {
    return RichText(
      overflow: TextOverflow.clip,
      textAlign: TextAlign.end,
      textDirection: TextDirection.rtl,
      maxLines: 1,
      text: const TextSpan(
        text: 'My ',
        style: TextStyle(color: Colors.white, fontSize: 23),
        children: [
          TextSpan(
            text: 'Music',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.purpleAccent),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size(double.infinity, 65),
      child: SafeArea(
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: AnimationSearchBar(
            onChanged: (_) {
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
            centerWidget: _buildTitleWidget(),
            onDrawerOpen: () => scaffoldKey.currentState?.openDrawer(),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(int index) {
    final list = controller.textController.value.text.isEmpty
        ? controller.musicList
        : controller.filteredList;

    if (index == list.length) {
      return const SizedBox(height: 80);
    }

    return ListTile(
      onTap: () => controller.playSong(index),
      onLongPress: () {
        Get.dialog(Dialog(
          child: SizedBox(
            height: 140,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    list[index].title,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text("Delete song"),
                    onTap: () => controller.deleteSong(index),
                  ),
                ],
              ),
            ),
          ),
        ));
      },
      title: Text(list[index].title),
      subtitle: Text(_getArtistName(index)),
      leading: controller.artWorkGetter(index),
    );
  }

  Widget _buildDrawer() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => YoutubeHomePage()),
              ),
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
            InkWell(
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
                  "Rescan Files?",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(child: _buildDrawer()),
      body: GetBuilder<MusicController>(
        init: controller,
        builder: (controller) {
          if (controller.doneInit.isFalse) {
            return Center(
              child: Obx(() => Text(
                  "${controller.musicCountcurrent}/${controller.musicCount}")),
            );
          }

          if (controller.hasError.isTrue) {
            return const Center(child: Text("ERROR"));
          }

          if (controller.musicList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: _buildAppBar(),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.textController.value.text.isEmpty
                          ? controller.musicList.length + 1
                          : controller.filteredList.length + 1,
                      itemBuilder: (context, index) => _buildListTile(index),
                    ),
                  ),
                ],
              ),
              Obx(() {
                return Visibility(
                  visible: controller.visible.value,
                  child: AnimatedAlign(
                    curve: Curves.ease,
                    alignment: _getBoxAlignment(),
                    duration: const Duration(milliseconds: 500),
                    child: const ExpandableSongScreen(),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
