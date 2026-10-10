import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:musicplayer/features/library/presentation/home_page.dart";
import "package:musicplayer/core/widgets/drawer/app_drawer.dart";
import "package:musicplayer/core/widgets/search/animation_search_bar.dart";
import 'package:musicplayer/features/youtube/presentation/video_list.dart';
import 'package:musicplayer/features/youtube/presentation/downloads_page.dart';
import "package:musicplayer/features/youtube/controller/youtube_controller.dart";

class YoutubeHomePage extends StatelessWidget {
  YoutubeHomePage({super.key});

  final controller = Get.find<YoutubeController>();
  final youtubeScaffoldKey = GlobalKey<ScaffoldState>();

  RichText titleWidget(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return RichText(
      overflow: TextOverflow.clip,
      textAlign: TextAlign.end,
      textDirection: TextDirection.rtl,
      softWrap: true,
      maxLines: 1,
      text: TextSpan(
        text: 'You',
        style: (textTheme.headlineSmall ?? const TextStyle(fontSize: 23))
            .copyWith(color: scheme.onSurface),
        children: <TextSpan>[
          TextSpan(
              text: 'Tube',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: scheme.error)),
        ],
      ),
      textScaler: const TextScaler.linear(1),
    );
  }

  PreferredSizeWidget appbarWdget(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
            closeIconColor: scheme.onSurface,
            isBackButtonVisible: true,
            duration: const Duration(milliseconds: 250),
            previousScreen: null,
            backIconColor: scheme.onSurface,
            centerTitle: 'YouTube',
            searchIconColor: scheme.onSurface,
            centerTitleStyle: textTheme.titleMedium
                    ?.copyWith(color: scheme.onSurface) ??
                TextStyle(color: scheme.onSurface, fontSize: 18),
            searchTextEditingController: controller.textController.value,
            horizontalPadding: 5,
            centerWidget: titleWidget(context),
            onDrawerOpen: () {
              youtubeScaffoldKey.currentState?.openDrawer();
            },
            searchYoutube: (text) async {
              // on submitted
              try {
                await controller.getSearchResults();
              } catch (e) {
                Get.snackbar("Couldn't fetch data from youtube", e.toString());
              }
              controller.update();
            },
          ),
        )));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: youtubeScaffoldKey,
        drawer: AppDrawer(
          selectedId: 'youtube',
          items: [
            DrawerItem(
              id: 'library',
              icon: Icons.library_music_outlined,
              selectedIcon: Icons.library_music,
              label: 'My music',
              subtitle: 'On this device',
              onTap: () => AppDrawer.go(context, const Home()),
            ),
            DrawerItem(
              id: 'youtube',
              icon: Icons.smart_display_outlined,
              selectedIcon: Icons.smart_display,
              label: 'YouTube',
              subtitle: 'Search & download',
              onTap: () => youtubeScaffoldKey.currentState?.closeDrawer(),
            ),
            DrawerItem(
              id: 'downloads',
              icon: Icons.download_outlined,
              selectedIcon: Icons.download,
              label: 'Downloads',
              onTap: () =>
                  AppDrawer.go(context, const DownloadsPage(), replace: false),
            ),
          ],
          bottomItem: DrawerItem(
            id: 'save-path',
            icon: Icons.folder_open_outlined,
            label: 'Choose where to save',
            subtitle: 'Download location',
            onTap: () {
              Navigator.pop(context);
              controller.pickSavePath();
            },
          ),
        ),
        appBar: appbarWdget(context),
        body: const Center(child: VideoList()),
      ),
    );
  }
}
