import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicplayer/core/utils/utils.dart';
import 'package:musicplayer/core/widgets/song_image_widget.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/player/data/data_audio_position.dart';

class SongFullScreen extends StatefulWidget {
  const SongFullScreen({super.key});

  @override
  State<SongFullScreen> createState() => _SongFullScreenState();
}

class _SongFullScreenState extends State<SongFullScreen>
    with SingleTickerProviderStateMixin {
  final controller = Get.find<LibraryController>();

  static const _fallbackArt = "assets/img/NotFound.jpg";

  TextStyle _titleStyle(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: Theme.of(context).colorScheme.onSurface,
          ) ??
      const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  TextStyle _artistStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
            height: 1.3,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ) ??
      const TextStyle(fontSize: 15, height: 1.3);

  TextStyle _timeStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ) ??
      const TextStyle(
        fontSize: 12,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  /// Play/pause morph animation, driven by the playback state.
  late final AnimationController _playPause;
  Worker? _playingWorker;

  /// Slider position (0..1) while the user is dragging / waiting for a seek
  /// to land. `null` means "follow the real playback position". A
  /// ValueNotifier is used so only the slider rebuilds while dragging, not
  /// the whole screen.
  final ValueNotifier<double?> _dragValue = ValueNotifier<double?>(null);

  /// Seek target the thumb is pinned to until the playback position catches
  /// up. Cleared together with [_dragValue] once the seek lands, fails, or
  /// times out — otherwise the thumb snaps back to the stale position while
  /// just_audio is still seeking.
  Duration? _seekTarget;
  Timer? _seekClearTimer;

  /// Close enough to count as "seek landed" (position stream ticks rarely hit
  /// the exact millisecond).
  static const _seekTolerance = Duration(milliseconds: 800);

  /// Safety net so a seek that never lands (error, track change, unseekable
  /// source) doesn't pin the thumb forever.
  static const _seekTimeout = Duration(seconds: 2);

  /// Vertical offset used for the swipe-down-to-close gesture.
  final ValueNotifier<double> _dismissOffset = ValueNotifier<double>(0);

  bool get _isPlaying => controller.playbackState.value?.playing ?? false;

  @override
  void initState() {
    super.initState();
    _playPause = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _isPlaying ? 1 : 0,
    );
    _playingWorker = ever(controller.playbackState, (_) {
      if (!mounted) return;
      _isPlaying ? _playPause.forward() : _playPause.reverse();
    });
  }

  @override
  void dispose() {
    _playingWorker?.dispose();
    _playPause.dispose();
    _seekClearTimer?.cancel();
    _dragValue.dispose();
    _dismissOffset.dispose();
    super.dispose();
  }

  void _clearSeekHold() {
    _seekClearTimer?.cancel();
    _seekClearTimer = null;
    _seekTarget = null;
    if (mounted) _dragValue.value = null;
  }

  String _artPath() {
    final artUri = controller.song.value?.artUri;
    return (artUri == null || artUri.path.isEmpty)
        ? _fallbackArt
        : File.fromUri(artUri).path;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) {
          // Only follow downward drags.
          _dismissOffset.value =
              (_dismissOffset.value + d.delta.dy).clamp(0.0, 400.0);
        },
        onVerticalDragEnd: (d) {
          final fling = (d.primaryVelocity ?? 0) > 700;
          if (fling || _dismissOffset.value > 140) {
            Navigator.maybePop(context);
          } else {
            _dismissOffset.value = 0;
          }
        },
        onVerticalDragCancel: () => _dismissOffset.value = 0,
        child: ValueListenableBuilder<double>(
          valueListenable: _dismissOffset,
          builder: (context, offset, child) => AnimatedContainer(
            duration: offset == 0
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, offset, 0),
            child: child,
          ),
          // The background lives *outside* SafeArea so it paints behind the
          // status and navigation bars instead of leaving black strips.
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBlurredBackground(context),
              SafeArea(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  // A tiny (128px) decode is blurred instead of the full-res artwork, and
  // ImageFiltered is used instead of BackdropFilter so the blur only
  // recomputes when the artwork changes. The result cross-fades between
  // songs and sits in its own RepaintBoundary.
  Widget _buildBlurredBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Obx(() {
        final artUri = controller.song.value?.artUri;
        final hasArt = artUri != null && artUri.path.isNotEmpty;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surfaceContainerLowest),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: hasArt
                  ? SizedBox.expand(
                      key: ValueKey(artUri.toString()),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 30,
                          sigmaY: 30,
                          tileMode: TileMode.decal,
                        ),
                        child: Image(
                          image: ResizeImage(
                            FileImage(File.fromUri(artUri)),
                            width: 128,
                          ),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    )
                  : const SizedBox.expand(key: ValueKey('no-art')),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black38, Colors.black45, Colors.black87],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildContent(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: landscape
                ? Row(
                    children: [
                      Expanded(child: Center(child: _buildSongImage(context))),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSongInfo(context),
                            const SizedBox(height: 8),
                            _buildSlider(),
                            const SizedBox(height: 4),
                            _buildControls(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: Center(child: _buildSongImage(context))),
                      const SizedBox(height: 16),
                      _buildSongInfo(context),
                      const SizedBox(height: 12),
                      _buildSlider(),
                      const SizedBox(height: 8),
                      _buildControls(),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton(
          iconSize: 32,
          tooltip: 'Close',
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: scheme.onSurface),
        ),
        Expanded(
          child: Text(
            "NOW PLAYING",
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: scheme.onSurfaceVariant,
                ) ??
                TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        // Keeps the title optically centered against the close button.
        const SizedBox(width: 48),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Artwork
  // ---------------------------------------------------------------------------

  Widget _buildSongImage(BuildContext context) {
    // Decode at (displayed size x device pixel ratio) so the art stays sharp
    // on high-DPI screens without decoding a huge bitmap.
    final size = MediaQuery.sizeOf(context);
    final side = (size.shortestSide - 40).clamp(0.0, 480.0);
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final cacheWidth = (side * dpr).round().clamp(64, 1024);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 480),
      child: AspectRatio(
        aspectRatio: 1,
        child: Obx(() {
          final path = _artPath();
          // Art "breathes": full size while playing, slightly smaller when
          // paused, which gives instant visual feedback on the state.
          return AnimatedScale(
            scale: _isPlaying ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isPlaying ? 0.55 : 0.3),
                    blurRadius: _isPlaying ? 40 : 20,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: KeyedSubtree(
                  key: ValueKey(path),
                  child: SongImageWidget(
                    path: path,
                    raduis: 24,
                    cacheWidth: cacheWidth,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Title / artist
  // ---------------------------------------------------------------------------

  Widget _buildSongInfo(BuildContext context) {
    // Reserve space for 2 title lines at all times so the artwork above
    // (inside an Expanded) never shifts when the title wraps to 1 vs 2
    // lines. Heights scale with the system text scaler.
    final scaler = MediaQuery.textScalerOf(context);
    final titleStyle = _titleStyle(context);
    final artistStyle = _artistStyle(context);
    final titleBoxHeight =
        scaler.scale(titleStyle.fontSize! * titleStyle.height!) * 2;
    final artistBoxHeight =
        scaler.scale(artistStyle.fontSize! * artistStyle.height!);

    return SizedBox(
      height: titleBoxHeight + 6 + artistBoxHeight,
      child: Obx(() {
        final song = controller.song.value;
        return Column(
          children: [
            SizedBox(
              height: titleBoxHeight,
              width: double.infinity,
              child: Center(
                child: Text(
                  song?.title ?? "No Title",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: artistBoxHeight,
              width: double.infinity,
              child: Center(
                child: Text(
                  song?.artist ?? "Unknown Artist",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: artistStyle,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Seek bar
  // ---------------------------------------------------------------------------

  Widget _buildSlider() {
    return StreamBuilder<DataAudioPosition>(
      initialData:
          DataAudioPosition(duration: Duration.zero, position: Duration.zero),
      stream: controller.audioHandler.audioPositionStream,
      builder: (context, snapshot) {
        final scheme = Theme.of(context).colorScheme;
        final duration = snapshot.data?.duration ?? Duration.zero;
        final position = snapshot.data?.position ?? Duration.zero;
        final disabled = duration.inMilliseconds == 0;

        // A pending seek has landed once the real position catches up to the
        // target: release the thumb so it follows playback again. Clearing
        // here (instead of when the seek future completes) avoids the
        // snap-back to the stale position while just_audio is still seeking.
        final pendingTarget = _seekTarget;
        if (_dragValue.value != null &&
            pendingTarget != null &&
            !disabled) {
          final landed = (position.inMilliseconds -
                      pendingTarget.inMilliseconds)
                  .abs() <=
              _seekTolerance.inMilliseconds;
          // The seek future completing early while the position is already
          // (almost) there — e.g. tiny seeks — also counts as landed.
          if (landed) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _clearSeekHold());
          }
        }

        // Position and duration can race during transitions; an unclamped
        // ratio makes Slider throw.
        final progress = disabled
            ? 0.0
            : (position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0);

        return ValueListenableBuilder<double?>(
          valueListenable: _dragValue,
          builder: (context, drag, _) {
            final value = (drag ?? progress).clamp(0.0, 1.0);
            // While dragging, the left label previews the target time.
            final shownPosition = drag == null
                ? position
                : Duration(
                    milliseconds: (drag * duration.inMilliseconds).round());

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.surfaceContainerHigh,
                    thumbColor: scheme.primary,
                    overlayColor: scheme.primary.withValues(alpha: 0.12),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: drag == null ? 5 : 8,
                      disabledThumbRadius: 5,
                      elevation: 0,
                      pressedElevation: 0,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: value,
                    onChangeStart: disabled
                        ? null
                        : (v) {
                            HapticFeedback.selectionClick();
                            // A fresh drag supersedes any pending seek hold.
                            _seekClearTimer?.cancel();
                            _seekClearTimer = null;
                            _seekTarget = null;
                            _dragValue.value = v;
                          },
                    onChanged: disabled ? null : (v) => _dragValue.value = v,
                    onChangeEnd: disabled
                        ? null
                        : (v) async {
                            final target = Duration(
                                milliseconds:
                                    (v * duration.inMilliseconds).round());
                            // Pin the thumb at the drop point until the
                            // position stream lands on the target.
                            _dragValue.value = v;
                            _seekTarget = target;
                            _seekClearTimer?.cancel();
                            _seekClearTimer = Timer(_seekTimeout, () {
                              // Seek never landed (error, track change,
                              // unseekable source): release instead of pinning
                              // the thumb forever.
                              _seekTarget = null;
                              if (mounted) _dragValue.value = null;
                            });
                            try {
                              await controller.seekTime(target);
                            } catch (e) {
                              debugPrint('Seek to $target failed: $e');
                              if (mounted) _clearSeekHold();
                            }
                            // On success: do NOT clear here — the StreamBuilder
                            // above releases the thumb once position lands
                            // (or the timeout fires).
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Utils.formatDurationToMinutesAndSeconds(shownPosition),
                        style: _timeStyle(context),
                      ),
                      Text(
                        Utils.formatDurationToMinutesAndSeconds(duration),
                        style: _timeStyle(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Transport controls
  // ---------------------------------------------------------------------------

  Widget _buildControls() {
    final handler = controller.audioHandler;

    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StreamBuilder<bool>(
            stream: handler.shuffleModeStream,
            initialData: false,
            builder: (context, snapshot) {
              final active = snapshot.data ?? false;
              return _ToggleButton(
                icon: Icons.shuffle_rounded,
                tooltip: active ? 'Shuffle on' : 'Shuffle off',
                active: active,
                accent: scheme.primary,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  handler.switchShuffle();
                },
              );
            },
          ),
          IconButton(
            iconSize: 44,
            tooltip: 'Previous',
            onPressed: () {
              HapticFeedback.lightImpact();
              handler.skipToPrevious();
            },
            icon: Icon(Icons.skip_previous_rounded, color: scheme.onSurface),
          ),
          _buildPlayPauseButton(),
          IconButton(
            iconSize: 44,
            tooltip: 'Next',
            onPressed: () {
              HapticFeedback.lightImpact();
              handler.skipToNext();
            },
            icon: Icon(Icons.skip_next_rounded, color: scheme.onSurface),
          ),
          StreamBuilder<LoopMode>(
            stream: handler.repeatModeStream,
            initialData: LoopMode.off,
            builder: (context, snapshot) {
              final mode = snapshot.data ?? LoopMode.off;
              return _ToggleButton(
                icon: mode == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                tooltip: switch (mode) {
                  LoopMode.off => 'Repeat off',
                  LoopMode.all => 'Repeat all',
                  LoopMode.one => 'Repeat one',
                },
                active: mode != LoopMode.off,
                accent: scheme.primary,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  handler.switchRepeat();
                },
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildPlayPauseButton() {
    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Obx(() {
        final playing = _isPlaying;
        return Tooltip(
          message: playing ? 'Pause' : 'Play',
          child: Material(
            color: scheme.primary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shadowColor: Colors.black54,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                playing
                    ? controller.audioHandler.pause()
                    : controller.audioHandler.play();
              },
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: _playPause,
                    size: 34,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      });
    });
  }
}

/// Shuffle / repeat button: tinted with the accent colour and marked with a
/// small dot when active, so state is readable without relying on colour alone.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.accent,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 28,
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon,
              color: active ? accent : scheme.onSurfaceVariant),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? accent : Colors.transparent,
          ),
        ),
      ],
    );
  }
}