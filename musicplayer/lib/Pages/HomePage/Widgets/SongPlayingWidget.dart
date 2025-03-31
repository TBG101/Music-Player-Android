import "dart:io";
import "dart:ui";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:musicplayer/Pages/SongFullScreen/song_full_screen.dart";
import 'package:musicplayer/Pages/HomePage/Widgets/song_image_widget.dart';
import "package:musicplayer/controllers/music_controller.dart";

class SongPlayingWdiget extends StatefulWidget {
  final bool isFullScreen;
  final AnimationController animationController;

  const SongPlayingWdiget(
      {super.key,
      required this.isFullScreen,
      required this.animationController});

  @override
  State<SongPlayingWdiget> createState() => _SongPlayingWdigetState();
}

class _SongPlayingWdigetState extends State<SongPlayingWdiget> {
  final MusicController controller = Get.find<MusicController>();
  late final bool isFullScreen;
  double containerHeight = 75;
  bool canDrag = true;
  double borderRaduis = 20;

  late Animation<double> animation;
  late Animation<Color?> animationColor;
  late AnimationController animationController;

  final widgetPlayingColor = const Color.fromARGB(111, 64, 66, 88);

  @override
  void initState() {
    super.initState();
    // initialize the isFullScreen variable
    isFullScreen = widget.isFullScreen;

    // initialize the animationController
    animationController = widget.animationController;

    // initialize the animation
    animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: animationController, curve: Curves.fastOutSlowIn));

    // initliaz color animation
    animationColor =
        ColorTween(begin: const Color(0xFF000434), end: widgetPlayingColor)
            .animate(CurvedAnimation(
                parent: animationController, curve: Curves.fastOutSlowIn));
  }

  Widget artUri() {
    if (controller.song.value?.artUri == null ||
        controller.song.value!.artUri?.path == null) {
      return Obx(() {
        return const SongImageWidget(path: "lib/assets/img/NotFound.jpg");
      });
    } else {
      return Obx(() {
        return SongImageWidget(
            path: File.fromUri(controller.song.value!.artUri!).absolute.path);
      });
    }
  }

  Widget dockedSongWidget() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 50),
                child: AspectRatio(aspectRatio: 1, child: artUri()),
              ),
              Obx(() {
                return Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: SizedBox(
                    width: 205,
                    child: Text(
                      controller.song.value == null
                          ? "Null"
                          : controller.song.value!.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.start,
                      softWrap: true,
                    ),
                  ),
                );
              }),
              Obx(
                () => IconButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      controller.playbackState.value!.playing
                          ? controller.audioHandler.pause()
                          : controller.audioHandler.play();
                    },
                    icon: Icon(controller.playbackState.value!.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded)),
              ),
              IconButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    controller.audioHandler.skipToNext();
                  },
                  icon: const Icon(Icons.skip_next_rounded))
            ],
          )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;
    return AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return ClipRRect(
              borderRadius: BorderRadius.circular(
                  borderRaduis * animationController.value),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 5 * animationController.value,
                    sigmaY: 4 * animationController.value),
                child: Container(
                    padding: const EdgeInsets.only(
                        top: 10, bottom: 10, right: 10, left: 12),
                    height: screenHeight,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(color: animationColor.value),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.topCenter,
                      children: [
                        AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              return Opacity(
                                  opacity: animation.value,
                                  child: dockedSongWidget());
                            }),
                        AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              return Opacity(
                                  opacity: 1 - animation.value,
                                  child: const SongFullScreen());
                            })
                      ],
                    )),
              ));
        });
  }
}
