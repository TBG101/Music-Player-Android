import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/SongFullScreen/song_full_screen.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/song_image_widget.dart';
import 'package:musicplayer/controllers/music_controller.dart';

class SongPlayingDocked extends GetView<MusicController> {
  const SongPlayingDocked({super.key});

  String _getArtistName() => controller.song.value == null
      ? "Null"
      : controller.song.value!.artist ?? "No Artist";

  String _getSongName() =>
      controller.song.value == null ? "Null" : controller.song.value!.title;

  Widget artUri() {
    if (controller.song.value?.artUri == null ||
        controller.song.value?.artUri?.path == null) {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
        decoration: BoxDecoration(
            boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 10)],
            color: const Color(0xff212121),
            border: Border.all(color: Colors.white12, width: 1),
            borderRadius: const BorderRadius.all(Radius.circular(12))),
        child: ListTile(
          onTap: () {
            Get.to(const SongFullScreen());
          },
          contentPadding: EdgeInsets.zero,
          leading: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 50),
            child: AspectRatio(
                aspectRatio: 1,
                child: Obx(() {
                  return artUri();
                })),
          ),
          subtitleTextStyle:
              const TextStyle(fontSize: 10, color: Colors.white60),
          dense: true,
          title: Obx(() {
            return Text(
              _getSongName(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.start,
              softWrap: true,
            );
          }),
          subtitle: Obx(() {
            return Text(
              _getArtistName(),
              overflow: TextOverflow.ellipsis,
            );
          }),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
          ),
        ),
      ),
    );
  }
}
