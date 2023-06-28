// ignore_for_file: dead_code

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

class MusicController extends GetxController {
  final RxBool visible = false.obs;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  final RxList<SongModel> musicList = <SongModel>[].obs;
  final RxList<SongModel> filteredList = <SongModel>[].obs;

  final RxBool hasError = false.obs;
  late AudioHandler audioHandler;

  final Rxn<MediaItem> song = Rxn<MediaItem>();
  final Rxn<PlaybackState> playbackState = Rxn<PlaybackState>();

  var textController = TextEditingController().obs;
  late Directory savePath;

  var doneInit = false.obs;

  var queeUpdated = true.obs;

  void initHandler() async {
    audioHandler = Get.find<AudioHandler>();
    savePath = await getApplicationDocumentsDirectory();
  }

  Rxn<MediaItem> getSongPlaying() {
    return song;
  }

  void addListQuee() async {
    var lst = <MediaItem>[];
    for (var index = 0; index < musicList.length; index++) {
      String art = "${savePath.path}/${musicList[index].title}.jpg";

      String? path = musicList[index].uri;
      File(art).exists().then((value) {
        if (value != true) {
          print("$index IMG DOES NOT EXIST");
          art = "${savePath.path}/NotFound.JPG";
        }
      });

      var item = MediaItem(
        id: path!,
        title: musicList[index].title,
        artist: musicList[index].artist ?? " ",
        album: musicList[index].album,
        artUri: Uri.file(art),
        duration: Duration(milliseconds: musicList[index].duration ?? 0),
      );
      lst.add(item);
    }

    audioHandler.addQueueItems(lst);
  }

  void getSongs() async {
    savePath = await getApplicationDocumentsDirectory();
    bool firstCall = await File("${savePath.path}/NotFound.JPG").exists();

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
      if (firstCall == false) {
        print("First time Running");
        saveAllArt();
      } else {
        doneInit.value = true;
      }

      addListQuee();
    } catch (e) {
      debugPrint(e.toString());
      hasError.value = true;
    }

    update();
  }

  Future<Uri> artSetter(int index, List<SongModel> songs) async {
    Uri? art;
    if (await File("${savePath.path}/${songs[index].title}.jpg").exists()) {
      art = Uri.file("${savePath.path}/${songs[index].title}.jpg");
    } else {
      art = Uri.file("${savePath.path}/NotFound.JPG");
    }
    return art;
  }

  void filterList() async {
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
          );

          lst.add(item);
        }
        await audioHandler.updateQueue(lst);
      } else {
        for (var index = 0; index < filteredList.length; index++) {
          var art = await artSetter(index, filteredList);
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
    // visible.value = true;
    // var songs = <SongModel>[];
    // if (textController.value.text.isEmpty) {
    //   songs = musicList;
    // } else {
    //   songs = filteredList;
    // }

    // String? _path = songs[index].uri;
    // Uri? art = await saveArtImage(index);
    // var _item = MediaItem(
    //   id: _path!,
    //   title: songs[index].title,
    //   artist: songs[index].artist ?? " ",
    //   album: songs[index].album,
    //   artUri: art,
    //   duration: Duration(milliseconds: songs[index].duration ?? 0),
    // );

    // audioHandler.playMediaItem(_item); // play the song
  }

  itemPlaying() {
    audioHandler.mediaItem.listen((item) {
      song.value = item;
    });
  }

  getState() {
    audioHandler.playbackState.listen((PlaybackState state) {
      playbackState.value = state;
    });
  }

  saveAllArt() async {
    print(musicList.length);
    final ByteData bytes = await rootBundle.load('lib/assets/img/NotFound.JPG');
    final Uint8List list = bytes.buffer.asUint8List();
    File("${savePath.path}/NotFound.JPG").writeAsBytes(list);

    for (int index = 0; index < musicList.length; index++) {
      var img = await _audioQuery.queryArtwork(
          musicList[index].id, ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG, size: 300, quality: 300);

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
    doneInit.value = true;
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
      nullArtworkWidget: Image.asset("lib/assets/img/NotFound.JPG"),
    );
  }
}
