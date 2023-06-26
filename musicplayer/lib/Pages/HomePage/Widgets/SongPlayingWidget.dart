import "dart:io";
import "dart:ui";

import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:musicplayer/controllers/MusicController.dart";

class SongPlayingWdiget extends StatelessWidget {
  SongPlayingWdiget({super.key});

  final MusicController controller = Get.find<MusicController>();

  Widget artUri() {
    if (controller.song.value?.artUri == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(90),
        child: Image.asset(
          "lib/assets/img/NotFound.JPG",
          width: 30,
          height: 30,
          fit: BoxFit.cover,
        ),
      );
    } else if (controller.song.value!.artUri?.path == null) {
      return const SizedBox.shrink();
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(90),
        child: Image.file(
          File.fromUri(controller.song.value!.artUri!),
          width: 30,
          height: 30,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 2),
        child: Container(
          padding:
              const EdgeInsets.only(top: 10, bottom: 10, right: 10, left: 12),
          height: 75,
          width: MediaQuery.of(context).size.width,
          decoration:
              const BoxDecoration(color: Color.fromARGB(111, 64, 66, 88)),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: artUri(),
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
              ]),
        ),
      ),
    );
  }
}
