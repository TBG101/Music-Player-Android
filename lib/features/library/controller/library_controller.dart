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

  final Rxn<MediaItem> song = Rxn<MediaItem>();
  final Rxn<PlaybackState> playbackState = Rxn<PlaybackState>();

  // Plain controller: the object itself is never replaced, so `.obs` only
  // adds indirection at every call site.
  final TextEditingController textController = TextEditingController();

  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;

  // Guards against overlapping cache loads (onReady + drawer rescan).
  bool _loading = false;
  // Generation counter so a stale background scan can never overwrite newer
  // library state.
  int _refreshGen = 0;
  // URIs deleted this session (or being deleted right now). Filters concurrent
  // rescan results so a scan that started before the file delete can't
  // resurrect the entry.
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

  /// Full-library refresh after a download. Optimistic and non-interrupting:
  /// update the visible list only. The playing queue is left alone; the next
  /// [playSongFromList] builds a new one from what the user taps on.
  Future<void> addNewSong() async {
    try {
      final songs = await _audioLoader.fetchSongs();
      songs.removeWhere((s) => _removedUris.contains(s.uri));
      musicList.assignAll(songs);
      if (textController.text.trim().isNotEmpty) filterList();
    } catch (e) {
      debugPrint('Library refresh after download failed: $e');
    }
  }

  /// Pushes [songs] to the handler as the default queue, but only while
  /// nothing is loaded. Once playback has started, the queue is whatever the
  /// user started from (library or search results); a background rescan must
  /// not silently swap it for the full library under Next/Previous.
  Future<void> _syncIdleQueue(List<AudioFile> songs) async {
    if (song.value != null) return;
    await audioHandler.updateQueue(
      songs.map(MediaItemMapper.fromSongModel).toList(),
    );
  }

  Future<void> getSongs({bool refreshArt = false}) async {
    if (_loading) return;
    _loading = true;
    loadingSongs.value = true;
    final gen = ++_refreshGen;
    try {
      // FAST: SQLite
      final cachedSongs = await _audioLoader.getCachedSongs();
      if (gen != _refreshGen) return;

      cachedSongs.removeWhere((s) => _removedUris.contains(s.uri));
      musicList.assignAll(cachedSongs);
      await _syncIdleQueue(cachedSongs);

      hasError.value = false;

      // A non-empty cache means a returning user: show it immediately and let
      // the background scan refresh silently. An empty cache (fresh install)
      // leaves loadingSongs true so the loader stays up until the first
      // device scan completes — otherwise the empty cache path would flash
      // "No music found" seconds before the scan populates it.
      final cacheHadSongs = cachedSongs.isNotEmpty;
      if (cacheHadSongs) {
        doneInit.value = true;
        loadingSongs.value = false;
      }

      // SLOW: device scan, in background (not awaited by callers). When the
      // cache was empty, this scan owns completing initialization.
      _refreshSongs(
        gen: gen,
        refreshArt: refreshArt,
        completesInit: !cacheHadSongs,
      );
    } catch (e) {
      debugPrint(e.toString());
      hasError.value = true;
      loadingSongs.value = false;
    } finally {
      _loading = false;
    }
  }

  Future<void> _refreshSongs({
    required int gen,
    bool refreshArt = false,
    bool completesInit = false,
  }) async {
    // Let the first frame settle before starting the device scan: the cached
    // list is already on screen and the scan competes with it for the UI.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (gen != _refreshGen) return;

    try {
      final songs = await _audioLoader.fetchSongs(overwriteArt: refreshArt);
      if (gen != _refreshGen) return;
      songs.removeWhere((s) => _removedUris.contains(s.uri));

      // Same library as what is on screen: skip the full list + queue remap.
      if (!_sameLibrary(musicList, songs)) {
        musicList.assignAll(songs);
        if (textController.text.trim().isNotEmpty) filterList();
        await _syncIdleQueue(songs);
      }
    } catch (e) {
      // A failed first scan has nothing cached to fall back on, so surface an
      // error; a background rescan must not hide the library already onscreen.
      if (completesInit) hasError.value = true;
      debugPrint('Background refresh failed: $e');
    }

    // The first scan owns completing init (empty cache): leave the loader no
    // matter the outcome — empty library or success. Guarded by gen so a stale
    // scan superseded by a newer one can't flip the flags early.
    if (completesInit && gen == _refreshGen) {
      doneInit.value = true;
      loadingSongs.value = false;
    }
  }

  /// Whether [a] and [b] render and play identically, so refreshing the list
  /// and the audio queue would be a no-op.
  static bool _sameLibrary(List<AudioFile> a, List<AudioFile> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.uri != y.uri ||
          x.title != y.title ||
          x.artist != y.artist ||
          x.album != y.album ||
          x.duration != y.duration ||
          x.cachedArtPath != y.cachedArtPath) {
        return false;
      }
    }
    return true;
  }

  /// Pure, synchronous filter over the current [musicList]. Debouncing lives
  /// in the UI (`Home._onSearchChanged`, 300ms); this method never drops a
  /// query.
  void filterList() {
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

  /// Legacy entry point: resolves the visible list at tap time and delegates.
  /// Prefer [playSongFromList] with the tile's snapshot to avoid TOCTOU
  /// between the text field and the tapped list.
  Future<void> playSong(int index) {
    final searching = textController.text.trim().isNotEmpty;
    // Copy: the observable list can change (rescan/delete) mid-await.
    final source = searching
        ? List<AudioFile>.of(filteredList)
        : List<AudioFile>.of(musicList);
    return playSongFromList(source, index);
  }

  /// Plays [index] from an explicit [source] snapshot (that snapshot becomes
  /// the playing queue). Queueing, de-duplication of rapid taps and loading
  /// are handled by [AudioPlayerHandler.playItems].
  ///
  /// [tappedUri] is the song the user actually tapped. The tile's [index] is
  /// from build time and the library can rescan between build and tap, so the
  /// uri wins whenever it resolves — otherwise a reshuffle silently plays the
  /// wrong song (or drops the tap as out-of-range).
  Future<void> playSongFromList(List<AudioFile> source, int index,
      {String? tappedUri}) async {
    // Snapshot: the observable list can change (rescan/delete) mid-await.
    var snapshot = List<AudioFile>.of(source);
    var resolved = index;
    if (tappedUri != null) {
      final byId = snapshot.indexWhere((s) => s.uri == tappedUri);
      if (byId >= 0) {
        resolved = byId;
      } else {
        // Stale list (rescan reordered it mid-tap): look the song up in the
        // current library instead of playing whatever slid into [index].
        final inLibrary = musicList.indexWhere((s) => s.uri == tappedUri);
        if (inLibrary >= 0) {
          snapshot = List<AudioFile>.of(musicList);
          resolved = inLibrary;
        } else {
          final inFiltered =
              filteredList.indexWhere((s) => s.uri == tappedUri);
          if (inFiltered >= 0) {
            snapshot = List<AudioFile>.of(filteredList);
            resolved = inFiltered;
          } else {
            debugPrint('playSongFromList: tapped song gone: $tappedUri');
            Get.snackbar(
                'Unavailable', 'That song is no longer in the library');
            return;
          }
        }
      }
    }
    if (resolved < 0 || resolved >= snapshot.length) {
      debugPrint(
          'playSongFromList: index $resolved out of range (len ${snapshot.length})');
      return;
    }

    final uri = snapshot[resolved].uri;
    try {
      await audioHandler.playItems(
        snapshot.map(MediaItemMapper.fromSongModel).toList(),
        resolved,
      );
    } catch (e) {
      debugPrint('playSongFromList: failed to play $uri: $e');
      Get.snackbar("Couldn't play", 'That file could not be loaded');
    }
  }

  void _subscribePlayback() {
    _mediaItemSub?.cancel();
    // null is a real state (stop clears it): it hides the dock, so don't
    // filter it out here.
    _mediaItemSub = audioHandler.mediaItem.listen((item) {
      song.value = item;
    });
    _playbackStateSub?.cancel();
    _playbackStateSub =
        audioHandler.playbackState.listen((PlaybackState state) {
      playbackState.value = state;
    });
  }

  Future<void> seekTime(Duration duration) => audioHandler.seek(duration);

  bool isCurrentlyPlaying(String uri) {
    return song.value?.id == uri;
  }

  /// Optimistically removes the song from the UI + SQLite cache, then deletes
  /// the underlying file. Returns true only when the file itself is gone;
  /// false means the entry was removed from screen but will self-heal back
  /// on the next rescan (file delete failed or song unknown/playing).
  Future<bool> deleteSong(String uri) async {
    final index = musicList.indexWhere((song) => song.uri == uri);
    if (index < 0) return false;

    if (isCurrentlyPlaying(uri)) {
      Get.snackbar("Can't Delete", "This song is currently playing");
      return false;
    }

    // Mark first so a rescan that completes while the file delete is still in
    // flight can't bring the entry back.
    _removedUris.add(uri);

    musicList.removeWhere((s) => s.uri == uri);
    filteredList.removeWhere((s) => s.uri == uri);

    // The handler serializes this against any in-flight play/skip and patches
    // both its queue and the loaded playlist, so Next/Prev can never land on
    // the deleted entry. It matches by id, so list index shifts are harmless.
    try {
      await audioHandler.removeQueueItemById(uri);
    } catch (e) {
      debugPrint('Failed to remove song from queue: $e');
    }

    // Drop the row from the SQLite cache first so the song stays deleted on
    // the next launch; the rescan self-heals if the file delete fails.
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