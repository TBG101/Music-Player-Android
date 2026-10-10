import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:musicplayer/core/widgets/drawer/app_drawer.dart';
import 'package:musicplayer/features/library/presentation/home_page.dart';
import 'package:musicplayer/features/youtube/controller/youtube_controller.dart';
import 'package:musicplayer/features/youtube/presentation/youtube_home_page.dart';
import 'package:musicplayer/features/youtube/data/download_task.dart';
import 'package:musicplayer/features/youtube/presentation/widgets/download_tile.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<YoutubeController>();
    final downloadQueue = controller.downloadQueue;
    return Scaffold(
      drawer: AppDrawer(
        selectedId: 'downloads',
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
            onTap: () => AppDrawer.go(context, YoutubeHomePage()),
          ),
          DrawerItem(
            id: 'downloads',
            icon: Icons.download_outlined,
            selectedIcon: Icons.download,
            label: 'Downloads',
            onTap: () => Navigator.pop(context),
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
      appBar: AppBar(
        title: const Text("Downloads"),
        actions: [
          IconButton(
            onPressed: () {
              final hasFinished = downloadQueue.tasks.any(
                (task) =>
                    task.status == DownloadStatus.completed ||
                    task.status == DownloadStatus.failed,
              );
              if (hasFinished) {
                downloadQueue.clearFinished();
              }
            },
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Obx(() {
        final tasks = downloadQueue.tasks;
        if (tasks.isEmpty) {
          return const Center(child: Text("No downloads"));
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: DownloadTile(task: tasks[index]),
            );
          },
        );
      }),
    );
  }
}
