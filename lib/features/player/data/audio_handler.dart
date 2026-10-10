import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicplayer/features/player/data/data_audio_position.dart';
import 'package:rxdart/rxdart.dart';

Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.tbg101.musicplayer.audio',
      androidNotificationChannelName: 'Lowwave playback',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      notificationColor: Colors.purple,
    ),
  );
}

/// Single source of truth for playback.
///
/// Model: [queue] is the logical queue. When [_loaded] is true, the just_audio
/// playlist is exactly that queue (same order, so playlist index == queue
/// index). When false, nothing is loaded and the next play loads the queue.
/// [mediaItem] always follows the source the player is really on.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  late final AudioPlayer _player;

  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;
  Stream<LoopMode> get repeatModeStream => _player.loopModeStream;

  AudioPlayerHandler() {
    _player = AudioPlayer(handleInterruptions: true);

    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play],
      processingState: AudioProcessingState.loading,
    ));

    Rx.merge<Object?>([
      _player.playbackEventStream,
      _player.playingStream,
      _player.loopModeStream,
      _player.shuffleModeEnabledStream,
    ]).listen((_) => _broadcastState());

    _player.currentIndexStream.listen(_syncMediaItem);
    _listenForDurationChanges();
  }

  // ---------------------------------------------------------------------------
  // Queue
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateQueue(List<MediaItem> mediaItems) async {
    final items = List<MediaItem>.of(mediaItems);
    final wasPlaying = _player.playing;

    if (items.isEmpty) {
      await stop();
      queue.value = [];
      return;
    }

    await _player.setAudioSources(
      items
          .map(
            (item) => AudioSource.uri(Uri.parse(item.id), tag: item),
          )
          .toList(),
    );

    queue.value = items;

    if (wasPlaying) {
      unawaited(_player.play());
    }
  }

  /// Makes [items] the queue and plays [index].
  Future<void> playItems(List<MediaItem> items, int index) async {
    if (index < 0 || index >= items.length) return;
    final newQueue = List<MediaItem>.of(items);

    await _player.setAudioSources(
      newQueue
          .map((item) => AudioSource.uri(Uri.parse(item.id), tag: item))
          .toList(),
      initialIndex: index,
    );

    queue.value = items;
    _player.seek(Duration.zero, index: index);
  }

  /// Removes [id] from the queue and the loaded playlist. Callers must not
  /// remove the currently playing song.
  Future<void> removeQueueItemById(String id) async {
    final index = queue.value.indexWhere((m) => m.id == id);
    if (index < 0 || mediaItem.value?.id == id) return;

    final next = List<MediaItem>.of(queue.value)..removeAt(index);
    if (next.isEmpty) {
      queue.add(next);
      await stop();
      return;
    }
    await _player.removeAudioSourceAt(index);

    queue.add(next);
  }

  // ---------------------------------------------------------------------------
  // Transport
  // ---------------------------------------------------------------------------

  @override
  Future<void> skipToQueueItem(int index) async {
    _player.seek(Duration.zero, index: index);
    play();
  }

  @override
  Future<void> skipToNext() async {
    _player.seekToNext();
    play();
  }

  @override
  Future<void> skipToPrevious() async {
    _player.seekToPrevious();
    play();
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> seek(Duration position) async => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.clearAudioSources();
    mediaItem.add(null);
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        queueIndex: null,
      ),
    );
  }

  Future<void> switchShuffle() async {
    await _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
  }

  /// Cycles repeat: off → all → one → off.
  Future<void> switchRepeat() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
    }
  }

  /// Memoized + shared: the dock and full screen rebuild their StreamBuilder
  /// often, and a fresh combine stream per access would resubscribe the
  /// position/duration listeners every time.
  late final Stream<DataAudioPosition> audioPositionStream =
      Rx.combineLatest2<Duration, Duration?, DataAudioPosition>(
    _player.positionStream,
    _player.durationStream,
    (position, duration) => DataAudioPosition(
      position: position,
      duration: duration ?? Duration.zero,
    ),
  ).shareValue();

  // ---------------------------------------------------------------------------
  // Player → audio_service sync
  // ---------------------------------------------------------------------------

  void _broadcastState() {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
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
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      // Playlist index == queue index while loaded.
      queueIndex: _player.currentIndex,
    ));
  }

  /// Keeps [mediaItem] on the source the player is really playing, so
  /// auto-advance, notification and headset buttons never leave the UI stale.
  void _syncMediaItem(int? index) {
    if (index == null || _player.processingState == ProcessingState.idle) {
      return;
    }
    final sequence = _player.sequence;
    if (index < 0 || index >= sequence.length) return;
    final tag = sequence[index].tag;
    if (tag is! MediaItem || mediaItem.value?.id == tag.id) return;

    // Prefer the queue's copy: it has the freshest metadata and duration.
    final i = queue.value.indexWhere((m) => m.id == tag.id);
    mediaItem.add(i >= 0 ? queue.value[i] : tag);
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      final index = _player.currentIndex;

      if (duration == null ||
          current == null ||
          index == null ||
          index < 0 ||
          index >= _player.sequence.length) {
        return;
      }

      final tag = _player.sequence[index].tag;
      if (tag is! MediaItem ||
          tag.id != current.id ||
          current.duration == duration) {
        return;
      }

      final updated = current.copyWith(duration: duration);
      mediaItem.add(updated);

      final queueIndex = queue.value.indexWhere((m) => m.id == current.id);
      if (queueIndex != -1) {
        queue.add(List<MediaItem>.of(queue.value)..[queueIndex] = updated);
      }
    });
  }
}
