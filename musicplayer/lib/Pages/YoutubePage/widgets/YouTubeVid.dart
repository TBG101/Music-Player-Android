import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/controllers/youtubeController.dart';

class YouTubeVid extends GetView<YoutubeController> {
  const YouTubeVid({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width - 16;
    return SizedBox(
        height: 80,
        width: screenWidth,
        child: Stack(
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(children: [
                        Container(
                          color: Colors.black,
                        ),
                        Image.network(
                          controller
                              .videos.value![index].thumbnails.mediumResUrl,
                          fit: BoxFit.fitHeight,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Stack(
                              children: [
                                Text(
                                  controller.videos.value![index].duration
                                      .toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 1.3
                                      ..color =
                                          const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                Text(
                                  controller.videos.value![index].duration
                                      .toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 50,
                        width: screenWidth - (143),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0, right: 8, left: 8),
                          child: Text(
                            (controller.videos.value![index].title),
                            maxLines: 3,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.fade,
                                fontSize: 12),
                            softWrap: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: screenWidth - (133.35) - 40,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 8, left: 8, bottom: 8),
                          child: Text(
                            controller.videos.value![index].author,
                            maxLines: 1,
                            style: const TextStyle(
                              overflow: TextOverflow.fade,
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  onPressed: () {
                    controller.downloadVid(index);
                  },
                  icon: const ImageIcon(
                    AssetImage("lib/assets/img/download.png"),
                  ),
                )),
          ],
        ));
  }
}
