import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';

void showDeleteSongDialog({
  required LibraryController controller,
  required AudioFile song,
}) {
  if (controller.isCurrentlyPlaying(song.uri)) {
    Get.snackbar("Can't Delete", "This song is currently playing");
    return;
  }

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: _DeleteSongDialogBody(controller: controller, song: song),
    ),
  );
}

class _DeleteSongDialogBody extends StatelessWidget {
  final LibraryController controller;
  final AudioFile song;

  const _DeleteSongDialogBody({
    required this.controller,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messageColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 42,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            "Delete song?",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "“${song.title ?? "No Title"}” will be permanently removed from your library.",
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              color: messageColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await HapticFeedback.mediumImpact();
                    await controller.deleteSong(song.uri);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Delete"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
