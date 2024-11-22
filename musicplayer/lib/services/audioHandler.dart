import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicplayer/models/data_audio_position.dart';
import 'package:rxdart/rxdart.dart';

Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio Service Demo',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      notificationColor: Colors.purple,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  late AudioPlayer _player;
  late AndroidLoudnessEnhancer _loudnessEnhancer;
  final _playlist = ConcatenatingAudioSource(children: []);

  bool isShuffle = false;

  AudioPlayerHandler() {
    initPlayer();
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play],
      processingState: AudioProcessingState.loading,
    ));

    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _loadEmptyPlaylist();
  }

  void initPlayer() {
    _loudnessEnhancer = AndroidLoudnessEnhancer();
    _loudnessEnhancer.setEnabled(true);
    // _loudnessEnhancer.setTargetGain(0.5);
    _player = AudioPlayer(
      handleInterruptions: true,
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          _loudnessEnhancer,
        ],
      ),
    );
  }

  int? getCurrentIndex() {
    return _player.currentIndex;
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // TODO: implement addQueueItems

    final audioSource = mediaItems.map(
      (e) {
        return AudioSource.uri(Uri.parse(e.id), tag: e);
      },
    );
    _playlist.addAll(audioSource.toList());

    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> mediaItems) async {
    final audioSource = mediaItems.map(
      (e) {
        return AudioSource.uri(Uri.parse(e.id), tag: e);
      },
    );
    _playlist.clear();
    _playlist.addAll(audioSource.toList());
    queue.value.clear();
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> skipToPrevious() async {
    _player.seekToPrevious();
    _player.play();
  }

  @override
  Future<void> skipToNext() async {
    _player.seekToNext();
    _player.play();
  }

  @override
  Future<void> play() async {
    _player.play();
  }

  @override
  Future<void> pause() async {
    _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    _player.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> playMediaItem(MediaItem _mediaItem) async {
    mediaItem.add(_mediaItem);

    _player.setAudioSource(
        AudioSource.uri(Uri.parse(_mediaItem.id), tag: _mediaItem));
    _player.play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    _player.seek(Duration.zero, index: index);
    _player.play();
  }

  void switchShuffle() {
    isShuffle = !isShuffle;
    _player.setShuffleModeEnabled(isShuffle);
  }

  Stream<dataAudioPosition> get audioPositionStream =>
      Rx.combineLatest2<Duration, Duration?, dataAudioPosition>(
          _player.positionStream, _player.durationStream, (position, duration) {
        return dataAudioPosition(
          duration: duration ?? Duration.zero,
          position: position,
        );
      });

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.play : MediaControl.pause,
          MediaControl.stop,
          MediaControl.skipToNext,
          MediaControl.skipToPrevious
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }
}
