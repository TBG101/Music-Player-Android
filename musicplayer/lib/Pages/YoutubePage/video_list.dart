import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/YoutubePage/widgets/YouTubeVid.dart';
import 'package:musicplayer/controllers/youtubeController.dart';

class VideoList extends GetView<YoutubeController> {
  const VideoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return controller.textController.value.text.isEmpty
          ? const SizedBox.shrink()
          : Obx(() {
              return ListView.builder(
                  itemCount: controller.videos.value == null
                      ? 0
                      : controller.videos.value!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: YouTubeVid(
                        index: index,
                      ),
                    );
                  });
            });
    });
  }
}
