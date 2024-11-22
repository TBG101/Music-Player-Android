import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/controllers/youtube_controller.dart';

class YouTubeVid extends GetView<YoutubeController> {
  const YouTubeVid({
    required this.videoDuration,
    required this.videoThumbnail,
    required this.videoTitle,
    required this.videoAuthor,
    required this.downloadVideoFunction,
    super.key,
    required this.index,
  });
  final Duration videoDuration;
  final String videoThumbnail;
  final String videoTitle;
  final String videoAuthor;
  final int index;
  final VoidCallback downloadVideoFunction;

  String formatDuration(Duration? duration) {
    if (duration == null) return "Can't fetch Duration";

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 16;
    final vidDuration = formatDuration(videoDuration);
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
                          videoThumbnail,
                          fit: BoxFit.fitHeight,
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            height: 30,
                            width: 60,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.9),
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8))),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Stack(
                              children: [
                              
                                Text(
                                  vidDuration,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
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
                            (videoTitle),
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
                            videoAuthor,
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
                    try {
                      downloadVideoFunction();
                    } catch (e) {
                      if (Get.isSnackbarOpen) {
                        Get.closeAllSnackbars();
                      }
                      Get.snackbar("Unhandled Exceptio caught when downloading",
                          e.toString(),
                          isDismissible: true);
                    }
                  },
                  icon: const ImageIcon(
                    AssetImage("lib/assets/img/download.png"),
                  ),
                )),
          ],
        ));
  }
}
