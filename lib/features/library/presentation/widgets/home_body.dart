import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/library/presentation/widgets/home_song_list.dart';
import 'package:musicplayer/features/player/presentation/song_playing_docked.dart';

class HomeBody extends StatelessWidget {
  final LibraryController controller;

  const HomeBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Obx (not GetBuilder): the branch below reads Rx values (doneInit,
    // hasError, musicList) and LibraryController never calls update(), so a
    // GetBuilder here would build the loading view once and never leave it.
    return Obx(() {
      if (controller.doneInit.isFalse || controller.loadingSongs.isTrue) {
        return _LoadingView(controller: controller);
      }

      if (controller.hasError.isTrue) {
        return const _MessageView(
          icon: Icons.error_outline_rounded,
          title: "Something went wrong",
          subtitle: "Your music library couldn't be loaded.",
        );
      }

      // Initialisation has finished, so an empty list is a real empty
      // library, not a loading state (the old code showed a spinner forever).
      if (controller.musicList.isEmpty) {
        return const _MessageView(
          icon: Icons.library_music_outlined,
          title: "No music found",
          subtitle: "Songs you add to this device will show up here.",
        );
      }

      return Stack(
        children: [
          Obx(() {
            final searching = controller.textController.text.isNotEmpty;
            // Explicit length reads: textController isn't observable and
            // passing the list reference below registers nothing. Without
            // these, this Obx throws "improper use" on the non-search path
            // and search updates would never rebuild the list.
            final musicCount = controller.musicList.length;
            final filteredCount = controller.filteredList.length;
            final activeList =
                searching ? controller.filteredList : controller.musicList;
            final activeCount = searching ? filteredCount : musicCount;

            if (searching && activeCount == 0) {
              return const _MessageView(
                icon: Icons.search_off_rounded,
                title: "No results",
                subtitle: "Try a different title or artist.",
              );
            }

            return HomeSongListView(
              controller: controller,
              activeList: activeList,
            );
          }),
          Align(
            alignment: Alignment.bottomCenter,
            child: Obx(() {
              final show = controller.song.value != null;
              // Slide + fade instead of popping in; IgnorePointer so the
              // hidden dock can't swallow taps while it's off screen.
              return IgnorePointer(
                ignoring: !show,
                child: AnimatedSlide(
                  offset: show ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: show ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const SongPlayingDocked(),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    });
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            "Loading music...",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
