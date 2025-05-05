import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/searchWidget.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/song_playing_docked.dart';
import 'package:musicplayer/Pages/YoutubePage/youtubeHomePage.dart';
import 'package:musicplayer/controllers/music_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MusicController controller = Get.find<MusicController>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateSearch();
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size(double.infinity, 65),
      child: SafeArea(
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: AnimationSearchBar(
            onChanged: _onSearchChanged,
            onClosed: () {
              controller.textController.value.clear();
              _updateSearch();
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

  Alignment _getBoxAlignment() => controller.song.value == null
      ? const Alignment(1.25, 1.25)
      : Alignment.bottomCenter;

  String _getArtistName(SongModel song) {
    final artist = song.artist;
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

  void _updateSearch() {
    controller.queeUpdate();
    controller.filterList();
  }

  Widget _buildListTile(List<SongModel> activeList, int index) {
    if (index == activeList.length) return const SizedBox(height: 80);

    final song = activeList[index];

    return ListTile(
      onTap: () => controller.playSong(index),
      onLongPress: () => _showDeleteDialog(index, song.title),
      title: Text(
        song.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _getArtistName(song),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: _buildLeadingImage(index),
    );
  }

  Widget _buildLeadingArt(Uri? path) {
    if (path == null) return const CircularProgressIndicator();

    return ClipRRect(
      borderRadius: BorderRadius.circular(90),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.file(
          File(path.path),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          cacheWidth: 100,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: frame == null ? 0 : 1,
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeadingImage(int index) {
    return FutureBuilder(
      future: controller.getArtAsUint8List(index),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Icon(Icons.error);

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.data == null) {
          return const _DefaultImage();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(90),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: 100,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: frame == null ? 0 : 1,
                  child: child,
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(int index, String title) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Delete Song",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to delete \"$title\"?",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      controller.deleteSong(index);
                      Get.back();
                    },
                    child: const Text("Delete"),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                  child: Text("YouTube", style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
            const Divider(),
            const Spacer(),
            const Divider(),
            InkWell(
              onTap: _rescanFiles,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text("Rescan Files?", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rescanFiles() {
    if (controller.doneInit.isTrue) {
      controller.audioHandler.stop();
      controller.initFalse();
      controller.rescanFiles();
      scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeList = controller.textController.value.text.isEmpty
        ? controller.musicList
        : controller.filteredList;

    final listLength = activeList.length + 1;

    return Scaffold(
      key: scaffoldKey,
      appBar: _buildAppBar(),
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
                  Expanded(
                    child: Obx(
                      () => ListView.builder(
                        cacheExtent: 500,
                        padding: EdgeInsets.zero,
                        itemCount: listLength,
                        itemBuilder: (context, index) =>
                            _buildListTile(activeList, index),
                      ),
                    ),
                  ),
                ],
              ),
              Obx(() => Align(
                    alignment: Alignment.bottomCenter,
                    child: Visibility(
                      visible: controller.visible.value,
                      child: const SongPlayingDocked(),
                    ),
                  ))
            ],
          );
        },
      ),
    );
  }
}

class _DefaultImage extends StatelessWidget {
  const _DefaultImage();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(90),
      child: const AspectRatio(
        aspectRatio: 1,
        child: NotFoundImage(),
      ),
    );
  }
}

class NotFoundImage extends StatelessWidget {
  const NotFoundImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "lib/assets/img/NotFound.jpg",
      fit: BoxFit.cover,
      alignment: Alignment.center,
      cacheHeight: 50,
      cacheWidth: 50,
      gaplessPlayback: true,
    );
  }
}
