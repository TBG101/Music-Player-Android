import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/YoutubePage/widgets/YouTubeVid.dart';
import 'package:musicplayer/controllers/youtubeController.dart';

class VideoList extends StatelessWidget {
  final YoutubeController controller = Get.find<YoutubeController>();

  VideoList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<YoutubeController>(builder: (controller) {
      return controller.textController.value.text.isEmpty
          ? const SizedBox.shrink()
          : ListView.builder(
              itemCount: controller.videos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() => YouTubeVid(
                      index: index, snippetVid: controller.videos[index])),
                );
              },
            );
    });
  }
}
