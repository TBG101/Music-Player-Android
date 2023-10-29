import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';

import '../../../controllers/youtubeController.dart';

class YouTubeVid extends StatelessWidget {
  YouTubeVid({super.key, required this.snippetVid, required this.index});

  final Map<dynamic, dynamic> snippetVid;
  final controller = Get.find<YoutubeController>();
  final int index;

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width - 16;
    return SizedBox(
        height: 100,
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
                      aspectRatio: 4 / 3,
                      child: Stack(children: [
                        Image.network(
                          snippetVid["thumbnail"],
                          fit: BoxFit.fitWidth,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Stack(
                              children: [
                                Text(
                                  snippetVid["durationString"],
                                  style: TextStyle(
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 1.3
                                      ..color =
                                          const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                Text(
                                  snippetVid["durationString"],
                                  style: const TextStyle(
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
                    children: [
                      SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0, right: 8, left: 8),
                          child: Text(
                            parse(snippetVid["title"] as String).body!.text,
                            // htmlEscape.convert(snippetVid["title"] as String),
                            maxLines: 3,
                            style: const TextStyle(
                                overflow: TextOverflow.fade, fontSize: 15),
                            softWrap: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: screenWidth * 0.55,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 8, left: 8, bottom: 8),
                          child: Text(
                            snippetVid["channel"]["name"] as String,
                            maxLines: 2,
                            style: const TextStyle(overflow: TextOverflow.fade),
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

/*
 vid info= {
"publishedAt": "2023-07-17T19:16:30Z",
"channelId": "UC0DZmkupLYwc0yDsfocLh0A",
"title": "TITANIC vs. ICEBERG In Teardown...",
"description": "TITANIC vs. ICEBERG In Teardown... If you enjoyed this video, watch more here: ...",
"thumbnails": {
  "default": {
  "url": "https://i.ytimg.com/vi/YnfT4XSgVnc/default.jpg",
  "width": 120,
  "height": 90
  },
  "medium": {
  "url": "https://i.ytimg.com/vi/YnfT4XSgVnc/mqdefault.jpg",
  "width": 320,
  "height": 180
  },
  "high": {
  "url": "https://i.ytimg.com/vi/YnfT4XSgVnc/hqdefault.jpg",
  "width": 480,
  "height": 360
  }
},
"channelTitle": "Jelly",
"liveBroadcastContent": "none",
"publishTime": "2023-07-17T19:16:30Z"
} 
*/