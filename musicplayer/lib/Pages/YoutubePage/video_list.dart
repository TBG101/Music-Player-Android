import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/YoutubePage/widgets/YouTubeVid.dart';
import 'package:musicplayer/controllers/youtubeController.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoList extends GetView<YoutubeController> {
  const VideoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return controller.textController.value.text.isEmpty
          ? FutureBuilder(
              future: controller.findMusicRecomendation(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("error occured while fetching recommended");
                }
                if (snapshot.data == null) {
                  return CircularProgressIndicator();
                }
                return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: YouTubeVid(
                          videoAuthor: snapshot.data![index].author,
                          videoDuration: snapshot.data![index].duration ??
                              const Duration(),
                          videoThumbnail:
                              snapshot.data![index].thumbnails.mediumResUrl,
                          videoTitle: snapshot.data![index].title,
                          downloadVideoFunction: () {
                            controller.addVideoToQuee(
                                index, snapshot.data ?? <Video>[]);
                          },
                          index: index,
                        ),
                      );
                    });
              },
            )
          : Obx(() {
              return controller.videos.value == null
                  ? const CircularProgressIndicator()
                  : ListView.builder(
                      itemCount: controller.videos.value!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: YouTubeVid(
                            index: index,
                            videoDuration:
                                controller.videos.value![index].duration ??
                                    const Duration(),
                            videoAuthor: controller.videos.value![index].author,
                            videoThumbnail: controller
                                .videos.value![index].thumbnails.mediumResUrl,
                            videoTitle: controller.videos.value![index].title,
                            downloadVideoFunction: () {
                              controller.addVideoToQuee(index, <Video>[]);
                            },
                          ),
                        );
                      });
            });
    });
  }
}
