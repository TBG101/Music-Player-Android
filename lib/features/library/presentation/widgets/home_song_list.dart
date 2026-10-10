import 'package:flutter/material.dart';
import 'package:musicplayer/features/library/presentation/widgets/home_song_tile.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';

class HomeSongListView extends StatelessWidget {
  final LibraryController controller;
  final List<AudioFile> activeList;

  const HomeSongListView({
    super.key,
    required this.controller,
    required this.activeList,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: 800,
      padding: EdgeInsets.zero,
      itemCount: activeList.length + 1,
      itemBuilder: (context, index) {
        if (index == activeList.length) {
          return const SizedBox(height: 80);
        }

        return HomeSongTile(
          controller: controller,
          song: activeList[index],
          index: index,
          queueSource: activeList,
        );
      },
    );
  }
}
