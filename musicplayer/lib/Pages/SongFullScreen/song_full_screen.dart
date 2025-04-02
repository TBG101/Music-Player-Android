import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/song_image_widget.dart';
import 'package:musicplayer/controllers/music_controller.dart';
import 'package:musicplayer/models/data_audio_position.dart';
import 'package:musicplayer/utils/utils.dart';
import 'dart:ui';

class SongFullScreen extends StatefulWidget {
  const SongFullScreen({super.key});

  @override
  State<SongFullScreen> createState() => _SongFullScreenState();
}

class _SongFullScreenState extends State<SongFullScreen> {
  final controller = Get.find<MusicController>();
  bool moving = false;
  double sliderValue = 0;

  String getPath() {
    final artUri = controller.song.value?.artUri;
    return (artUri == null || artUri.path.isEmpty)
        ? "lib/assets/img/NotFound.jpg"
        : File.fromUri(artUri).path;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            _buildBlurredBackground(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return StreamBuilder(
        stream: controller.audioHandler.mediaItem.stream,
        builder: (context, snapshot) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(File.fromUri(snapshot.data?.artUri ?? Uri())),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 28),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(context),
          const SizedBox(height: 30),
          _buildSongImage(),
          const SizedBox(height: 30),
          _buildSongInfo(),
          const SizedBox(height: 20),
          _buildSlider(),
          const SizedBox(height: 20),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          iconSize: 30,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white),
        ),
        const Text(
          "Now Playing",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(width: 30),
      ],
    );
  }

  Widget _buildSongImage() {
    return AspectRatio(
      aspectRatio: 1,
      child: Obx(() => SongImageWidget(
            path: getPath(),
            raduis: 15,
            cacheWidth: 250,
            width: 250,
          )),
    );
  }

  Widget _buildSongInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Obx(() => Text(
              controller.song.value?.title ?? "No Title",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )),
        const SizedBox(height: 5),
        Obx(() => Text(
              controller.song.value?.artist ?? "Unknown Artist",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            )),
      ],
    );
  }

  Widget _buildSlider() {
    return StreamBuilder<dataAudioPosition>(
      initialData:
          dataAudioPosition(duration: Duration.zero, position: Duration.zero),
      stream: controller.audioHandler.audioPositionStream,
      builder: (context, snapshot) {
        final songDuration = snapshot.data?.duration ?? Duration.zero;
        final songPosition = snapshot.data?.position ?? Duration.zero;

        bool disabled = songDuration.inMilliseconds == 0;
        double progress = disabled
            ? 0
            : songPosition.inMilliseconds / songDuration.inMilliseconds;

        return Column(
          children: [
            Slider(
              activeColor: Colors.white,
              value: moving ? sliderValue : progress,
              onChangeStart: (value) {
                if (disabled) return;
                setState(() {
                  moving = true;
                  sliderValue = value;
                });
              },
              onChanged: (value) {
                if (disabled) return;
                setState(() => sliderValue = value);
              },
              onChangeEnd: (value) {
                if (disabled) return;
                setState(() => moving = false);
                controller.seekTime(Duration(
                    milliseconds:
                        (value * songDuration.inMilliseconds).toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(Utils.formatDurationToMinutesAndSeconds(songPosition),
                      style: const TextStyle(color: Colors.white)),
                  Text(Utils.formatDurationToMinutesAndSeconds(songDuration),
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: controller.audioHandler.switchShuffle,
          icon: StreamBuilder(
            stream: controller.audioHandler.shuffleModeStream,
            builder: (context, snapshot) {
              final isShuffling = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: isShuffling ? Colors.blue : Colors.white,
                ),
                onPressed: () {
                  controller.audioHandler.switchShuffle();
                },
              );
            },
          ),
        ),
        IconButton(
          iconSize: 40,
          onPressed: controller.audioHandler.skipToPrevious,
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
        ),
        Obx(() => IconButton(
              iconSize: 50,
              onPressed: () {
                controller.playbackState.value!.playing
                    ? controller.audioHandler.pause()
                    : controller.audioHandler.play();
              },
              icon: Icon(
                controller.playbackState.value!.playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white,
              ),
            )),
        IconButton(
          iconSize: 40,
          onPressed: controller.audioHandler.skipToNext,
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            controller.audioHandler.switchReapeat();
          },
          icon: StreamBuilder(
              stream: controller.audioHandler.repeatModeStream,
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Icon(Icons.repeat_rounded, color: Colors.white);
                }
                final repeatMode = snapshot.data!;
                if (repeatMode == LoopMode.off) {
                  return const Icon(Icons.repeat_rounded, color: Colors.white);
                } else if (repeatMode == LoopMode.one) {
                  return const Icon(Icons.repeat_one_rounded,
                      color: Colors.blue);
                } else if (repeatMode == LoopMode.all) {
                  return const Icon(Icons.repeat_rounded, color: Colors.blue);
                }
                return const Icon(Icons.repeat_rounded, color: Colors.white);
              }),
        ),
      ],
    );
  }
}
