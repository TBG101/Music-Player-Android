import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:musicplayer/features/library/domain/audio_file.dart';
import 'package:musicplayer/features/player/data/audio_handler.dart';
import 'package:musicplayer/features/library/data/local_audio_loader.dart';
import 'package:musicplayer/core/utils/media_item_mapper.dart';
import 'package:musicplayer/core/utils/utils.dart';

/// Owns the library (what songs exist, search, delete). Everything about
/// *how* playback is queued and sequenced lives in [AudioPlayerHandler].
class LibraryController extends GetxController {
  late AudioPlayerHandler audioHandler;
  final LocalAudioLoader _audioLoader = LocalAudioLoader();

  final RxList<AudioFile> musicList = <AudioFile>[].obs;
  final RxList<AudioFile> filteredList = <AudioFile>[].obs;

  final RxBool hasError = false.obs;
  final RxBool doneInit = false.obs;
  final RxBool loadingSongs = false.obs;

  /// True only while the handler's queue is exactly the list the UI is
  /// showing, so a tile's index is also its queue index. Anything that
  /// changes the visible list or the queue behind the other's back must
  /// set this to false so the next tap rebuilds the queue.
  bool isQueeSynced = false;

  final Rxn<MediaItem> song = Rxn<MediaItem>();
  final Rxn<PlaybackState> playbackState = Rxn<PlaybackState>();

  final TextEditingController textController = TextEditingController();

  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;

  // Generation counter: a newer getSongs() call supersedes any older one, so
  // a stale scan can never overwrite newer library state.
  int _refreshGen = 0;

  // URIs deleted this session (or being deleted right now). Filters rescan
  // results so a scan that started before the file delete can't resurrect
  // the entry.
  final Set<String> _removedUris = <String>{};

  @override
  void onInit() {
    super.onInit();
    audioHandler = Get.find<AudioPlayerHandler>();
  }

  @override
  void onReady() {
    super.onReady();
    FlutterNativeSplash.remove();
    _subscribePlayback();
    // Fire-and-forget: lifecycle hooks are synchronous by contract.
    getSongs();
  }

  @override
  void onClose() {
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    textController.dispose();
    super.onClose();
  }

  void initFalse() {
    doneInit.value = false;
  }

  /// Scans the device and drops anything deleted this session.
  Future<List<AudioFile>> _scanDevice({bool overwriteArt = false}) async {
    final songs = await _audioLoader.fetchSongs(overwriteArt: overwriteArt);
    songs.removeWhere((s) => _removedUris.contains(s.uri));
    return songs;
  }

  /// Full-library refresh after a download. Updates the visible list only;
  /// the playing queue is left alone.
  Future<void> addNewSong() async {
    try {
      musicList.assignAll(await _scanDevice());
      // Visible list may be reordered; queue keeps its old order.
      isQueeSynced = false;
      if (textController.text.trim().isNotEmpty) filterList();
    } catch (e) {
      debugPrint('Library refresh after download failed: $e');
    }
  }

  /// Pushes [songs] to the handler as the default queue, but only while
  /// nothing is loaded. Once playback has started, a background rescan must
  /// not swap the user's queue for the full library.
  Future<void> _syncIdleQueue(List<AudioFile> songs) async {
    if (song.value != null) return;
    await audioHandler.updateQueue(
      songs.map(MediaItemMapper.fromSongModel).toList(),
    );
    // The queue was replaced behind any earlier "synced" state.
    isQueeSynced = false;
  }

  Future<void> getSongs({bool refreshArt = false}) async {
    loadingSongs.value = true;
    final gen = ++_refreshGen;
    try {
      // FAST: SQLite
      final cachedSongs = await _audioLoader.getCachedSongs();
      if (gen != _refreshGen) return;

      cachedSongs.removeWhere((s) => _removedUris.contains(s.uri));
      musicList.assignAll(cachedSongs);
      isQueeSynced = false;
      await _syncIdleQueue(cachedSongs);

      hasError.value = false;

      // Non-empty cache: show it immediately, refresh silently. Empty cache
      // (fresh install): keep the loader up until the first scan finishes.
      final cacheHadSongs = cachedSongs.isNotEmpty;
      if (cacheHadSongs) {
        doneInit.value = true;
        loadingSongs.value = false;
      }

      // SLOW: device scan, in background (not awaited by callers).
      _refreshSongs(
        gen: gen,
        refreshArt: refreshArt,
        completesInit: !cacheHadSongs,
      );
    } catch (e) {
      debugPrint(e.toString());
      if (gen == _refreshGen) {
        hasError.value = true;
        loadingSongs.value = false;
      }
    }
  }

  Future<void> _refreshSongs({
    required int gen,
    bool refreshArt = false,
    bool completesInit = false,
  }) async {
    // Let the first frame settle: the cached list is already on screen and
    // the scan competes with it for the UI.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (gen != _refreshGen) return;

    try {
      final songs = await _scanDevice(overwriteArt: refreshArt);
      if (gen != _refreshGen) return;

      musicList.assignAll(songs);
      isQueeSynced = false;
      if (textController.text.trim().isNotEmpty) filterList();
      await _syncIdleQueue(songs);
    } catch (e) {
      // A failed first scan has nothing cached to fall back on, so surface an
      // error; a background rescan must not hide the library on screen.
      if (completesInit) hasError.value = true;
      debugPrint('Background refresh failed: $e');
    }

    // The first scan (empty cache) owns completing init, whatever the outcome.
    if (completesInit && gen == _refreshGen) {
      doneInit.value = true;
      loadingSongs.value = false;
    }
  }

  /// Pure, synchronous filter over [musicList]. Debouncing lives in the UI.
  void filterList() {
    // The UI switches between the filtered list and the full list, so the
    // queue can no longer be assumed to match what is shown.
    isQueeSynced = false;

    final text = textController.text.toLowerCase().trim();
    if (text.isEmpty) {
      filteredList.clear();
      return;
    }
    filteredList.assignAll(
      musicList.where((s) {
        final title = (s.title ?? '').toLowerCase();
        final artist = (s.artist ?? '').toLowerCase();
        return title.contains(text) || artist.contains(text);
      }),
    );
  }

  /// Plays [index] from [source] (that snapshot becomes the playing queue).
  ///
  /// [tappedUri] is the song the user actually tapped. The tile's [index] is
  /// from build time and a rescan can reorder the list before the tap lands,
  /// so the uri wins whenever it resolves.
  Future<void> playSongFromList(List<AudioFile> source, int index,
      {String? tappedUri}) async {
    // Snapshot: the observable list can change mid-await.
    var snapshot = List<AudioFile>.of(source);
    var resolved = index;

    if (tappedUri != null) {
      final byUri = snapshot.indexWhere((s) => s.uri == tappedUri);
      if (byUri >= 0) {
        resolved = byUri;
      } else {
        final inLibrary = musicList.indexWhere((s) => s.uri == tappedUri);
        if (inLibrary < 0) {
          Get.snackbar('Unavailable', 'That song is no longer in the library');
          return;
        }
        // Falling back to the full library: the queue must be rebuilt from it.
        snapshot = List<AudioFile>.of(musicList);
        resolved = inLibrary;
        isQueeSynced = false;
      }
    }

    if (resolved < 0 || resolved >= snapshot.length) return;

    try {
      if (isQueeSynced) {
        await audioHandler.skipToQueueItem(resolved);
        return;
      }

      await audioHandler.playItems(
        snapshot.map(MediaItemMapper.fromSongModel).toList(),
        resolved,
      );
      // Only after success: the queue now matches this snapshot.
      isQueeSynced = true;
    } catch (e) {
      isQueeSynced = false;
      debugPrint(
          'playSongFromList: failed to play ${snapshot[resolved].uri}: $e');
      Get.snackbar("Couldn't play", 'That file could not be loaded');
    }
  }

  void _subscribePlayback() {
    _mediaItemSub?.cancel();
    // null is a real state (stop clears it): it hides the dock.
    _mediaItemSub = audioHandler.mediaItem.listen((item) {
      song.value = item;
      // Stop clears the queue; the next tap must rebuild it.
      if (item == null) isQueeSynced = false;
    });
    _playbackStateSub?.cancel();
    _playbackStateSub =
        audioHandler.playbackState.listen((PlaybackState state) {
      playbackState.value = state;
    });
  }

  Future<void> seekTime(Duration duration) => audioHandler.seek(duration);

  bool isCurrentlyPlaying(String uri) => song.value?.id == uri;

  /// Optimistically removes the song from the UI + SQLite cache, then deletes
  /// the underlying file. Returns true only when the file itself is gone;
  /// false means the entry was removed from screen but will self-heal back
  /// on the next rescan (file delete failed or song unknown/playing).
  Future<bool> deleteSong(String uri) async {
    if (!musicList.any((s) => s.uri == uri)) return false;

    if (isCurrentlyPlaying(uri)) {
      Get.snackbar("Can't Delete", "This song is currently playing");
      return false;
    }

    // Mark first so a rescan finishing mid-delete can't bring the entry back.
    _removedUris.add(uri);
    musicList.removeWhere((s) => s.uri == uri);
    filteredList.removeWhere((s) => s.uri == uri);

    try {
      await audioHandler.removeQueueItemById(uri);
    } catch (e) {
      // Queue and UI now disagree; force a rebuild on the next tap.
      isQueeSynced = false;
      debugPrint('Failed to remove song from queue: $e');
    }

    try {
      await _audioLoader.deleteCachedSong(uri);
    } catch (e) {
      debugPrint('Failed to remove song from cache: $e');
    }

    try {
      await Utils.deleteMusicUri(Uri.parse(uri));
    } catch (error) {
      // File is still there: let the next rescan restore the entry.
      _removedUris.remove(uri);
      Get.snackbar("Error", error.toString());
      return false;
    }

    return true;
  }
}
