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

          // iamge here
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
                    color: Colors.purple,
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
                if (snapshot.data != null && controller.song.value != null) {
                  if (controller.song.value!.duration != null) {
                    return Slider(
                      value: moving
                          ? sliderValue
                          : snapshot.data!.inMilliseconds /
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

                        final ms = value *
                            controller.song.value!.duration!.inMilliseconds;
                        final newDuration = Duration(milliseconds: ms.toInt());
                        controller.seekTime(newDuration);
                      },
                    );
                  }
                }
                return const SizedBox.shrink();
              })),

          // controls
        ],
      ),
    );
  }
}
