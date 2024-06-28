import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:musicplayer/controllers/youtubeController.dart';
import 'package:musicplayer/services/audioHandler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

class MusicController extends GetxController {
  final RxBool visible = false.obs;
  final RxInt musicCountcurrent = 0.obs;
  final RxInt musicCount = 0.obs;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  final RxList<SongModel> musicList = <SongModel>[].obs;
  final RxList<SongModel> filteredList = <SongModel>[].obs;

  final RxBool hasError = false.obs;
  late AudioPlayerHandler audioHandler;

  final Rxn<MediaItem> song = Rxn<MediaItem>();
  final Rxn<PlaybackState> playbackState = Rxn<PlaybackState>();

  var textController = TextEditingController().obs;
  late Directory savePath;

  var doneInit = false.obs;

  var queeUpdated = true.obs;

  @override
  void onInit() async {
    super.onInit();
    await initAudioHandler();
  }

  @override
  void onReady() async {
    super.onReady();
    await initSavePath();
    getSongs().then((value) => update());
    getState();
    itemPlaying();
  }

  void initFalse() {
    doneInit.value = false;
    update();
  }

  @override
  void dispose() {
    Get.delete<YoutubeController>();
    super.dispose();
  }

  Future<void> initAudioHandler() async {
    audioHandler = Get.find<AudioPlayerHandler>();
  }

  Future<void> initSavePath() async {
    savePath = await getApplicationDocumentsDirectory();
  }

  Rxn<MediaItem> getSongPlaying() {
    return song;
  }

  Future<void> addListQuee() async {
    var lst = <MediaItem>[];
    for (var index = 0; index < musicList.length; index++) {
      String? art = "${savePath.path}/${musicList[index].title}.jpg";
      String? path = musicList[index].uri;

      await File(art).exists().then((value) {
        if (value != true) {
          print("$index IMG DOES NOT EXIST");
          art = null;
        }
        var item = MediaItem(
          id: path!,
          title: musicList[index].title,
          artist: musicList[index].artist ?? " ",
          album: musicList[index].album,
          artUri: art != null ? Uri.file(art!) : null,
          duration: Duration(milliseconds: musicList[index].duration ?? 0),
        );
        lst.add(item);
        print(item);
      });
    }
    // updateQueue
    await audioHandler.updateQueue(lst);
  }

  void addNewSong(String path) {
    _audioQuery.scanMedia(path).then((value) {
      if (value == true) {
        queeUpdated.value = false;
      }
    });
    getSongs();
  }

  Future<void> getSongs() async {
    bool firstCall = await File("${savePath.path}/NotFound.jpg").exists();
    print(firstCall);
    try {
      List<SongModel> x = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      for (var element in x) {
        if (element.duration! > 60000) {
          musicList.add(element);
        }
      }

      if (firstCall == false) {
        print("First time Running");
        await saveAllArt();
      }

      await addListQuee();
      doneInit.value = true;
    } catch (e) {
      debugPrint(e.toString());
      hasError.value = true;
    }
    musicList.refresh();
  }

  Future<Uri> artSetter(int index, List<SongModel> songs) async {
    return await File("${savePath.path}/${songs[index].title}.jpg")
        .exists()
        .then((value) {
      Uri? art;
      if (value) {
        art = Uri.file("${savePath.path}/${songs[index].title}.jpg");
      } else {
        art = Uri.file("${savePath.path}/NotFound.jpg");
      }
      return art;
    });
  }

  Future<void> filterList() async {
    filteredList.clear();

    var text = textController.value.text;

    if (text.isNotEmpty) {
      for (var index = 0; index < musicList.length; index++) {
        if (musicList[index].title.toLowerCase().contains(text) ||
            musicList[index].artist!.toLowerCase().contains(text)) {
          filteredList.add(musicList[index]);
        }
      }
    }
    filteredList.refresh();
    update();
  }

  void queeUpdate() {
    queeUpdated.value = false;
  }

  void playSong(int index) async {
    visible.value = true;
    var lst = <MediaItem>[];
    var text = textController.value.text;
    if (queeUpdated.isFalse) {
      queeUpdated.value = true;
      if (text.isEmpty) {
        for (var index = 0; index < musicList.length; index++) {
          var art = await artSetter(index, musicList);
          var item = MediaItem(
              id: musicList[index].uri!,
              title: musicList[index].title,
              artist: musicList[index].artist ?? " ",
              album: musicList[index].album,
              artUri: art,
              duration: Duration(milliseconds: musicList[index].duration ?? 0),
              extras: {"loadThumbnailUri": true});

          lst.add(item);
        }
        await audioHandler.updateQueue(lst);
      } else {
        for (var index = 0; index < filteredList.length; index++) {
          var art = await artSetter(index, filteredList);
          print(art.toString() +
              " ------------------------------------------------------------");
          var item = MediaItem(
            id: filteredList[index].uri!,
            title: filteredList[index].title,
            artist: filteredList[index].artist ?? " ",
            album: filteredList[index].album,
            artUri: art,
            duration: Duration(milliseconds: filteredList[index].duration ?? 0),
          );

          lst.add(item);
        }
        await audioHandler.updateQueue(lst);
      }
    }

    audioHandler.skipToQueueItem(index);
  }

  void itemPlaying() {
    audioHandler.mediaItem.listen((item) {
      song.value = item;
    });
  }

  void getState() {
    audioHandler.playbackState.listen((PlaybackState state) {
      playbackState.value = state;
    });
  }

  Future<void> saveAllArt() async {
    print(musicList.length);
    final ByteData bytes = await rootBundle.load('lib/assets/img/NotFound.jpg');
    final Uint8List list = bytes.buffer.asUint8List();
    await File("${savePath.path}/NotFound.jpg").writeAsBytes(list);
    musicCount.value = musicList.length;
    print(savePath.path);

    for (int index = 0; index < musicList.length; index++) {
      musicCountcurrent.value = index;
      print(index);
      var img = await _audioQuery.queryArtwork(
          musicList[index].id, ArtworkType.AUDIO,
          format: ArtworkFormat.PNG, size: 200, quality: 300);

      if (img == null || img.isEmpty) {
        continue;
      }

      try {
        if (await File("${savePath.path}/${musicList[index].title}.jpg")
                .exists() ==
            false) {
          debugPrint("SAVING IMG");
          File fileUri =
              await File("${savePath.path}/${musicList[index].title}.jpg")
                  .writeAsBytes(img);
          debugPrint(fileUri.toString());
        }
      } catch (e) {
        print(e.toString());
      }
    }
    musicCountcurrent.value = 0;
    doneInit.value = true;
    refresh();
    update();
    debugPrint("done");
  }

  Widget artWorkGetter(int index) {
    var songs = <SongModel>[];
    if (textController.value.text.isEmpty) {
      songs = musicList;
    } else {
      songs = filteredList;
    }

    // artwork widget in Home Page
    return QueryArtworkWidget(
      controller: _audioQuery,
      id: songs[index].id,
      type: ArtworkType.AUDIO,
      nullArtworkWidget: ClipRRect(
        borderRadius: BorderRadius.circular(90),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.asset(
            "lib/assets/img/NotFound.jpg",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Future<void> rescanFiles() async {
    savePath = await getApplicationDocumentsDirectory();

    musicList.clear();
    filteredList.clear();

    try {
      List<SongModel> x = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      for (var element in x) {
        if (element.duration! > 60000) {
          musicList.add(element);
        }
      }
      musicList.refresh();
      await addListQuee();
    } catch (e) {
      debugPrint(e.toString());
      hasError.value = true;
    }
    await saveAllArt();
  }
}
