import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/YoutubePage/widgets/YouTubeVid.dart';
import 'package:musicplayer/controllers/youtubeController.dart';

class Searching extends StatelessWidget {
  Searching({super.key});

  final controller = Get.find<YoutubeController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<YoutubeController>(builder: (controller) {
      return controller.textController.value.text.isEmpty
          ? const SizedBox.shrink()
          : ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() => YouTubeVid(
                      index: index,
                      idVid: controller.videos[index]["id"]["videoId"],
                      snippetVid: controller.videos[index]["snippet"])),
                );
              },
            );
    });
  }
}
