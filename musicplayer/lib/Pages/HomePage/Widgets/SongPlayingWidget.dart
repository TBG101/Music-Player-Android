import "dart:io";
import "dart:ui";

import "package:flutter/animation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:get/get.dart";
import "package:musicplayer/Pages/HomePage/Widgets/song_full_screen.dart";
import 'package:musicplayer/Pages/HomePage/Widgets/song_image_widget.dart';
import "package:musicplayer/controllers/MusicController.dart";

class SongPlayingWdiget extends StatefulWidget {
  SongPlayingWdiget({super.key});

  @override
  State<SongPlayingWdiget> createState() => _SongPlayingWdigetState();
}

class _SongPlayingWdigetState extends State<SongPlayingWdiget>
    with SingleTickerProviderStateMixin {
  final MusicController controller = Get.find<MusicController>();
  double containerHeight = 75;
  bool canDrag = true;
  double borderRaduis = 20;

  late Animation<double> animation;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: animationController, curve: Curves.fastOutSlowIn));
  }

  Widget artUri() {
    if (controller.song.value?.artUri == null ||
        controller.song.value!.artUri?.path == null) {
      return const SongImageWidget(path: "lib/assets/img/NotFound.jpg");
    } else {
      return SongImageWidget(
          path: File.fromUri(controller.song.value!.artUri!).absolute.path);
    }
  }

  String getPath() {
    if (controller.song.value?.artUri == null ||
        controller.song.value!.artUri?.path == null) {
      return "lib/assets/img/NotFound.jpg";
    } else {
      return File.fromUri(controller.song.value!.artUri!).path;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: false,
      onPopInvoked: (value) {
        setState(() {
          containerHeight = 75;
          borderRaduis = 20;
          canDrag = true;
        });
      },
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (containerHeight <= 300) {
            containerHeight = 75;
            animationController.reverse();
          }
          setState(() {});
        },
        onVerticalDragUpdate: (details) {
          if (canDrag) {
            containerHeight = -details.localPosition.dy + 75;
            if (containerHeight < 75) {
              containerHeight = 75;
              borderRaduis = 20;
              animationController.forward();
            }
            if (containerHeight > 300) {
              containerHeight = screenHeight;
              borderRaduis = 0;
              canDrag = false;
            }
            setState(() {});
            return;
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRaduis),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: 5 * animation.value, sigmaY: 4 * animation.value),
            child: AnimatedContainer(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, right: 10, left: 12),
              height: containerHeight,
              width: MediaQuery.of(context).size.width,
              decoration:
                  const BoxDecoration(color: Color.fromARGB(111, 64, 66, 88)),
              child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 50),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: artUri(),
                      ),
                    ),
                    Padding(
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
                    ),
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
                        icon: const Icon(Icons.skip_next_rounded)),
                  ])
                  .animate(
                    target: (containerHeight) / screenHeight,
                  )
                  .fadeOut(
                    curve: Curves.ease,
                  )
                  .swap(
                      duration: const Duration(milliseconds: 500),
                      builder: (_, __) => SongFullScreen(
                            songImage: SongImageWidget(
                              path: getPath(),
                              raduis: 15,
                              height: 100,
                              width: 100,
                            ),
                          )
                              .animate(target: (containerHeight) / screenHeight)
                              .fadeIn(
                                curve: Curves.ease,
                              )),
            ),
          ),
        ),
      ),
    );
  }
}
