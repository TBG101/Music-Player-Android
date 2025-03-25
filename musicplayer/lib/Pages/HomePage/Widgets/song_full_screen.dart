import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/song_image_widget.dart';
import 'package:musicplayer/controllers/music_controller.dart';
import 'package:musicplayer/models/data_audio_position.dart';
import 'package:musicplayer/utils/utils.dart';

class SongFullScreen extends StatefulWidget {
  const SongFullScreen({super.key});

  @override
  State<SongFullScreen> createState() => _SongFullScreenState();
}

class _SongFullScreenState extends State<SongFullScreen> {
  final controller = Get.find<MusicController>();

  bool moving = false;
  double sliderValue = 0;

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
            padding: const EdgeInsets.only(bottom: 90),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  IconButton(
                      iconSize: 26,
                      onPressed: () {},
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                      )),
                  const Center(
                      child: Text(
                    "Now Playing",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ))
                ],
              ),
            ),
          ),

          // song image
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SizedBox(
              width: width * 0.95,
              child: Align(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Obx(
                    () => SongImageWidget(
                        path: getPath(), raduis: 5, height: 100, width: 100),
                  ),
                ),
              ),
            ),
          ),

          // song title
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

          // artist
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Obx(() => Text(controller.song.value == null
                ? "null"
                : controller.song.value!.artist ?? "")),
          ),

          // slider for time control
          StreamBuilder<dataAudioPosition>(
            initialData: dataAudioPosition(
                duration: const Duration(milliseconds: 0),
                position: const Duration(milliseconds: 0)),
            stream: controller.audioHandler.audioPositionStream,
            builder: ((context, snapshot) {
              if (snapshot.hasError) return Text("Error: ${snapshot.error}");

              if (!snapshot.hasData) return const Text("data not available");

              if (snapshot.data == null) {
                return const Text("snapshot.data is null");
              }

              if (controller.song.value == null) {
                return const Text(
                    "controller.song.value is null \nNo song selected");
              }

              final songDuration = snapshot.data!.duration;
              bool disabled = false;
              double progress = 0;
              if (songDuration.inMilliseconds == 0) {
                disabled = true;
              } else {
                progress = snapshot.data!.position.inMilliseconds /
                    songDuration.inMilliseconds;
              }

              songDuration.inMilliseconds;

              String songDurationStr =
                  Utils.formatDurationToMinutesAndSeconds(songDuration);

              String songCurrentPositionStr =
                  Utils.formatDurationToMinutesAndSeconds(
                      snapshot.data!.position);
              return FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(songCurrentPositionStr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white)),
                    SizedBox(
                      width: width * 0.9,
                      child: Slider(
                        activeColor: Colors.white,
                        value: moving ? sliderValue : progress,
                        onChangeStart: (value) {
                          if (disabled) return;
                          setState(() {
                            moving = true;
                            sliderValue = value;
                          });
                        },
                        onChanged: (value) {
                          if (disabled) return;
                          setState(() {
                            sliderValue = value;
                          });
                        },
                        onChangeEnd: (value) {
                          if (disabled) return;
                          setState(() {
                            moving = false;
                          });
                          final newDuration = Duration(
                              milliseconds:
                                  (value * songDuration.inMilliseconds)
                                      .toInt());
                          controller.seekTime(newDuration);
                        },
                      ),
                    ),
                    Text(songDurationStr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            }),
          ),

          // controls
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () {
                      controller.audioHandler.switchShuffle();
                    },
                    icon: const Icon(Icons.shuffle_rounded)),
                IconButton(
                    iconSize: 40,
                    onPressed: () {
                      controller.audioHandler.skipToPrevious();
                    },
                    icon: const Icon(Icons.skip_previous_rounded)),
                Obx(
                  () => IconButton(
                      iconSize: 40,
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
                    iconSize: 40,
                    onPressed: () {
                      controller.audioHandler.skipToNext();
                    },
                    icon: const Icon(Icons.skip_next_rounded)),
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.repeat_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
