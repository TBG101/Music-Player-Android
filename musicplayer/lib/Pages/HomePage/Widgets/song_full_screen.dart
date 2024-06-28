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
    return SizedBox(
      width: MediaQuery.of(context).size.width - 50,
      height: MediaQuery.of(context).size.height - 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // back button
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.arrow_back_ios))
              ],
            ),
          ),

          // iamge here
          AspectRatio(
            aspectRatio: 1,
            child: widget.songImage,
          ),

          Obx(
            () => Text(controller.song.value == null
                ? "null"
                : controller.song.value!.title),
          ),
          Obx(() => Text(controller.song.value == null
              ? "null"
              : controller.song.value!.artist ?? "")),
          // // slider for time control

          Obx(() {
            if (controller.playbackState.value != null &&
                controller.song.value != null) {
              if (controller.song.value!.duration != null) {
                return Slider(
                  value: moving
                      ? sliderValue
                      : controller
                              .playbackState.value!.position.inMilliseconds /
                          controller.song.value!.duration!.inMilliseconds,
                  onChangeStart: (value) {
                    value = sliderValue;
                    moving = true;
                  },
                  onChanged: (value) {
                    sliderValue = value;
                    setState(() {});
                  },
                  onChangeEnd: (value) {
                    moving = false;
                    if (controller.playbackState.value != null &&
                        controller.song.value != null) {
                      if (controller.song.value!.duration != null) {
                        final ms = value *
                            controller.song.value!.duration!.inMilliseconds;
                        final newDuration = Duration(milliseconds: ms.toInt());
                        controller.seekTime(newDuration);
                      }
                    }
                  },
                );
              }
            }
            return const SizedBox.shrink();
          }),

          // controls
        ],
      ),
    );
  }
}
