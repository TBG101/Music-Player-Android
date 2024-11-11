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
    final height = MediaQuery.of(context).size.height - 50;
    final width = MediaQuery.of(context).size.width - 50;
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
          const Spacer(),
          // iamge here
          SizedBox(
            width: width * 0.8,
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
            stream: controller.audioHandler.positionDataStream,
            builder: ((context, snapshot) {
              if (snapshot.hasData && controller.song.value != null) {
                final songDuration = controller.currentSongDuration.value;
                if (songDuration.inMilliseconds > 0) {
                  double progress = snapshot.data!.inMilliseconds /
                      songDuration.inMilliseconds;

                  return Slider(
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
                      final newDuration = Duration(
                          milliseconds:
                              (value * songDuration.inMilliseconds).toInt());
                      controller.seekTime(newDuration);
                    },
                  );
                }
              }
              return Text(controller.song.value!.duration.toString());
            }),
          )
          // controls
          ,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
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
                  icon: const Icon(Icons.skip_next_rounded)),
            ],
          ),
          const Spacer()
        ],
      ),
    );
  }
}
