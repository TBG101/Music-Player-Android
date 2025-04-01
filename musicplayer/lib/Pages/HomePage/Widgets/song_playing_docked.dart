import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/SongFullScreen/song_full_screen.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/song_image_widget.dart';
import 'package:musicplayer/controllers/music_controller.dart';

class SongPlayingDocked extends GetView<MusicController> {
  const SongPlayingDocked({super.key});

  Widget _buildImageArt(Uri? path) {
    if (path == null) {
      return const SongImageWidget(path: "lib/assets/img/NotFound.jpg");
    } else {
      return SongImageWidget(uri: path);
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
        child: StreamBuilder(
            stream: controller.audioHandler.mediaItem.stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text("Error"),
                );
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text("No Data"),
                );
              }
              return ListTile(
                onTap: () {
                  Get.to(const SongFullScreen());
                },
                contentPadding: EdgeInsets.zero,
                leading: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 50),
                    child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildImageArt(snapshot.data?.artUri))),
                subtitleTextStyle:
                    const TextStyle(fontSize: 10, color: Colors.white60),
                dense: true,
                title: Text(
                  snapshot.data?.title ?? "No Title",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.start,
                  softWrap: true,
                ),
                subtitle: Text(
                  snapshot.data?.artist ?? "No Artist",
                  overflow: TextOverflow.ellipsis,
                ),
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
              );
            }),
      ),
    );
  }
}
