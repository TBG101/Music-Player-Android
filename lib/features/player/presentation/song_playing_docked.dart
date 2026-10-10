import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:musicplayer/core/widgets/song_image_widget.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/player/data/data_audio_position.dart';
import 'package:musicplayer/features/player/presentation/song_full_screen.dart';

class SongPlayingDocked extends GetView<LibraryController> {
  const SongPlayingDocked({super.key});

  static const _fallbackArt = "assets/img/NotFound.jpg";
  static const _radius = 16.0;
  static const _swipeVelocity = 300.0;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _artPath(Uri? uri) => (uri == null || uri.path.isEmpty)
      ? _fallbackArt
      : File.fromUri(uri).path;

  void _openPlayer() {
    // A builder (not an instance) so the screen is only constructed when the
    // route is actually pushed, and a slide-up transition so it feels like the
    // dock is expanding. The full screen's swipe-down-to-close mirrors this.
    Get.to(
      () => const SongFullScreen(),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 320),
    );
  }

  void _onHorizontalSwipe(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v <= -_swipeVelocity) {
      HapticFeedback.lightImpact();
      controller.audioHandler.skipToNext();
    } else if (v >= _swipeVelocity) {
      HapticFeedback.lightImpact();
      controller.audioHandler.skipToPrevious();
    }
  }

  void _onVerticalSwipe(DragEndDetails details) {
    // Swipe up on the dock to expand it.
    if ((details.primaryVelocity ?? 0) <= -_swipeVelocity) _openPlayer();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        // Extra bottom/side room so the dock's drop shadow isn't clipped by
        // the Stack it floats in (home_body.dart).
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
        child: StreamBuilder<MediaItem?>(
          stream: controller.audioHandler.mediaItem.stream,
          builder: (context, snapshot) {
            final item = snapshot.data;
            // Nothing loaded yet (or the stream errored): show nothing rather
            // than a "No Data" / "Error" string stuck to the bottom of the app.
            if (item == null) return const SizedBox.shrink();
            return _buildDock(context, item);
          },
        ),
      ),
    );
  }

  Widget _buildDock(BuildContext context, MediaItem item) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: scheme.onSurface,
        ) ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
        );
    final artistStyle = textTheme.bodySmall?.copyWith(
          height: 1.3,
          color: scheme.onSurfaceVariant,
        ) ??
        const TextStyle(fontSize: 12, height: 1.3);
    return GestureDetector(
      onHorizontalDragEnd: _onHorizontalSwipe,
      onVerticalDragEnd: _onVerticalSwipe,
      child: DecoratedBox(
        // Soft drop shadow so the dock reads as a separate layer floating
        // above the scrolling list instead of blending into it.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.55),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: scheme.surfaceContainerHigh,
          elevation: 0,
          shadowColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: InkWell(
            onTap: _openPlayer,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 6),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 48,
                        child: SongImageWidget(
                          path: _artPath(item.artUri),
                          raduis: 8,
                          cacheWidth: 150,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.artist ?? "Unknown Artist",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: artistStyle,
                            ),
                          ],
                        ),
                      ),
                      _buildPlayPause(context),
                      IconButton(
                        iconSize: 30,
                        tooltip: 'Next',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          controller.audioHandler.skipToNext();
                        },
                        icon: Icon(Icons.skip_next_rounded,
                            color: scheme.onSurface),
                      ),
                    ],
                  ),
                ),
                _MiniProgress(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPause(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      // `?.` instead of `!`: playbackState is null until the handler emits its
      // first state, and the old `!` would throw during that window.
      final playing = controller.playbackState.value?.playing ?? false;
      return IconButton(
        iconSize: 32,
        tooltip: playing ? 'Pause' : 'Play',
        onPressed: () {
          HapticFeedback.lightImpact();
          if (playing) {
            controller.audioHandler.pause();
          } else {
            controller.audioHandler.play();
          }
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(playing),
            color: scheme.onSurface,
          ),
        ),
      );
    });
  }
}

/// Thin progress line along the bottom edge of the dock. Lives in its own
/// widget so the frequent position updates only rebuild this 2px bar, not the
/// whole dock.
class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: StreamBuilder<DataAudioPosition>(
        stream: controller.audioHandler.audioPositionStream,
        builder: (context, snapshot) {
          final scheme = Theme.of(context).colorScheme;
          final duration =
              (snapshot.data?.duration ?? Duration.zero).inMilliseconds;
          final position =
              (snapshot.data?.position ?? Duration.zero).inMilliseconds;
          final value =
              duration == 0 ? 0.0 : (position / duration).clamp(0.0, 1.0);

          return LinearProgressIndicator(
            value: value,
            minHeight: 2,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(scheme.primary),
          );
        },
      ),
    );
  }
}