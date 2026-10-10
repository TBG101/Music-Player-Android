import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/features/library/presentation/widgets/home_delete_dialog.dart';
import 'package:musicplayer/core/widgets/song_image_widget.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';

class HomeSongTile extends StatelessWidget {
  final LibraryController controller;
  final AudioFile song;
  final int index;
  final List<AudioFile> queueSource;

  const HomeSongTile({
    super.key,
    required this.controller,
    required this.song,
    required this.index,
    required this.queueSource,
  });

  String _artistName(AudioFile song) {
    final artist = song.artist;
    return (artist == "<unknown>" || artist == null) ? "No Artist" : artist;
  }

  Widget _buildLeadingImage() {
    final artPath = song.cachedArtPath;

    if (artPath == null || artPath.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(90),
        child: const AspectRatio(
          aspectRatio: 1,
          child: _DefaultArtwork(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: SongImageWidget(
        uri: Uri.parse(artPath),
        raduis: 8,
        cacheWidth: 100,
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Obx(() {
      final isPlaying = controller.isCurrentlyPlaying(song.uri);
      final image = _buildLeadingImage();

      if (!isPlaying) return image;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Custom radius)
          border: Border.all(
              color: Theme.of(context).colorScheme.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withAlpha(50),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.5),
        child: image,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () =>
          controller.playSongFromList(queueSource, index, tappedUri: song.uri),
      onLongPress: () => showDeleteSongDialog(
        controller: controller,
        song: song,
      ),
      title: Text(
        song.title ?? "No Title",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _artistName(song),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: _buildLeading(context),
    );
  }
}

class _DefaultArtwork extends StatelessWidget {
  const _DefaultArtwork();

  @override
  Widget build(BuildContext context) {
    return const SongImageWidget(path: "assets/img/NotFound.jpg");
  }
}
