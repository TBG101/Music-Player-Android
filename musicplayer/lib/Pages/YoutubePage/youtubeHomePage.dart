import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:musicplayer/Pages/HomePage/Home.dart";
import "package:musicplayer/Pages/HomePage/Widgets/searchWidget.dart";
import 'package:musicplayer/Pages/YoutubePage/video_list.dart';
import "package:musicplayer/controllers/youtubeController.dart";

class YoutubeHomePage extends StatelessWidget {
  YoutubeHomePage({super.key});

  final controller = Get.find<YoutubeController>();
  final youtubeScaffoldKey = GlobalKey<ScaffoldState>();

  RichText titleWidget() {
    return RichText(
      overflow: TextOverflow.clip,
      textAlign: TextAlign.end,
      textDirection: TextDirection.rtl,
      softWrap: true,
      maxLines: 1,
      textScaleFactor: 1,
      text: const TextSpan(
        text: 'You',
        style: TextStyle(color: Colors.white, fontSize: 23),
        children: <TextSpan>[
          TextSpan(
              text: 'Tube',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ],
      ),
    );
  }

  PreferredSizeWidget appbarWdget() {
    return PreferredSize(
        preferredSize: const Size(double.infinity, 65),
        child: SafeArea(
            child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          alignment: Alignment.center,
          child: AnimationSearchBar(
            onChanged: (text) {},
            onClosed: () {
              controller.textController.value.clear();
            },
            closeIconColor: Colors.white,
            isBackButtonVisible: true,
            duration: const Duration(milliseconds: 250),
            previousScreen: null,
            backIconColor: Colors.black,
            centerTitle: 'YouTube',
            searchIconColor: Colors.white,
            centerTitleStyle:
                const TextStyle(color: Colors.white, fontSize: 18),
            searchTextEditingController: controller.textController.value,
            horizontalPadding: 5,
            centerWidget: titleWidget(),
            onDrawerOpen: () {
              youtubeScaffoldKey.currentState?.openDrawer();
            },
            searchYoutube: (text) async {
              // on submitted
              print(text);
              await controller.getSearchResults();
              controller.update();
            },
          ),
        )));
  }

  SafeArea drawerList(BuildContext context) {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Home()));
            },
            child: const SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "My music",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          const Divider(),
          const Spacer(),
          const Divider(),
          InkWell(
            onTap: () async {},
            child: const SizedBox(
                width: double.infinity,
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Text("data"))),
          ),
          InkWell(
            onTap: () async {
              String? downloadPath =
                  await FilePicker.platform.getDirectoryPath();
              controller.setSavePath(downloadPath);
            },
            child: const SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text("Chose Where to save"),
              ),
            ),
          )
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: youtubeScaffoldKey,
        drawer: Drawer(child: drawerList(context)),
        appBar: appbarWdget(),
        body: const Center(child: VideoList()),
      ),
    );
  }
}
