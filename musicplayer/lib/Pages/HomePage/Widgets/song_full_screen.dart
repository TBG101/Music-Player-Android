import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/controllers/MusicController.dart';

class SongFullScreen extends StatefulWidget {
  final Widget songImage;

  const SongFullScreen({super.key, required this.songImage});

  @override
  State<SongFullScreen> createState() => _SongFullScreenState();
}

class _SongFullScreenState extends State<SongFullScreen> {
  final controller = Get.find<MusicController>();

  bool moving = false;
  double sliderValue = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 50;
    final height =
        MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    return SizedBox(
      width: MediaQuery.of(context).size.width - 50,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // back button
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_back_ios_rounded))
                ],
              ),
            ),
          ),

          SizedBox(
            height: height * 0.48,
            width: width,
            child: Align(
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: 1,
                child: widget.songImage,
              ),
            ),
          ),

          SizedBox(
            width: width,
            child: Obx(
              () => Text(
                controller.song.value == null
                    ? "null"
                    : controller.song.value!.title,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Obx(() => Text(controller.song.value == null
              ? "null"
              : controller.song.value!.artist ?? "")),

          // slider for time control
          StreamBuilder<Duration>(
            initialData: Duration.zero,
            stream: controller.audioHandler.positionDataStream,
            builder: ((context, snapshot) {
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              if (!snapshot.hasData) {
                return const Text("data not available");
              }
              if (controller.song.value == null) {
                return const Text(
                    "controller.song.value is null \nNo song selected");
              }

              final songDuration = controller.song.value!.duration;

              if (songDuration == null) {
                return const Text("songDuration is null");
              }

              return FutureBuilder(
                future: controller.audioHandler
                    .getMediaItem(controller.song.value!.id),
                builder: (context, snapshotFuture) {
                  double progress = snapshot.data!.inMilliseconds /
                      snapshotFuture.data!.duration!.inMilliseconds;
                  return Slider(
                    activeColor: Colors.white,
                    value: moving ? sliderValue : progress,
                    onChangeStart: (value) {
                      setState(() {
                        moving = true;
                        sliderValue = value;
                      });
                    },
                    onChanged: (value) {
                      setState(() {
                        sliderValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        moving = false;
                      });
                      final newDuration = snapshotFuture.data!.duration!;
                      controller.seekTime(newDuration);
                    },
                  );
                },
              );

              // if (songDuration.inMilliseconds > 0) {
              //   double progress =
              //       snapshot.data!.inMilliseconds / songDuration.inMilliseconds;
              //   return Slider(
              //     activeColor: Colors.white,
              //     value: moving ? sliderValue : progress,
              //     onChangeStart: (value) {
              //       setState(() {
              //         moving = true;
              //         sliderValue = value;
              //       });
              //     },
              //     onChanged: (value) {
              //       setState(() {
              //         sliderValue = value;
              //       });
              //     },
              //     onChangeEnd: (value) {
              //       setState(() {
              //         moving = false;
              //       });
              //       final newDuration = Duration(
              //           milliseconds:
              //               (value * songDuration.inMilliseconds).toInt());
              //       controller.seekTime(newDuration);
              //     },
              //   );
              // }
            }),
          ), // controls

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    controller.audioHandler.skipToPrevious();
                  },
                  icon: const Icon(Icons.skip_previous_rounded)),
              Obx(
                () => IconButton(
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
                  onPressed: () {
                    controller.audioHandler.skipToNext();
                  },
                  icon: const Icon(Icons.skip_next_rounded))
            ],
          )
        ],
      ),
    );
  }
}
