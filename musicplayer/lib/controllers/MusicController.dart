import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
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

  void initHandler() {
    audioHandler = Get.find<AudioHandler>();
  }

  Rxn<MediaItem> getSongPlaying() {
    return song;
  }

  void getSongs() {
    try {
      _audioQuery
          .querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      )
          .then((songsList) {
        for (var element in songsList) {
          if (element.duration! > 60000) {
            musicList.add(element);
            musicList.refresh();
          }
        }
        var lst = <MediaItem>[];
        for (var index = 0; index < musicList.length; index++) {
          String? _path = musicList[index].uri;
          var _item = MediaItem(
            id: _path!,
            title: musicList[index].title,
            artist: musicList[index].artist ?? " ",
            album: musicList[index].album,
            artUri: null,
            duration: Duration(milliseconds: musicList[index].duration ?? 0),
          );
          lst.add(_item);
        }
        print(lst.length);
        print(lst.first);
        audioHandler.addQueueItems(lst);
        update();
      });
    } catch (e) {
      debugPrint(e.toString());
      hasError.value = true;
    }
  }

  void filterList() {
    filteredList.value = [];
    if (textController.value.text.isNotEmpty) {
      for (var element in musicList) {
        if (element.title
                .toLowerCase()
                .contains(textController.value.text.toLowerCase()) ||
            element.artist!
                .toLowerCase()
                .contains(textController.value.text.toLowerCase())) {
          filteredList.add(element);
        }
      }
    }

    filteredList.refresh();
    update();
  }

  saveArtImage(int index) async {
    var songs = <SongModel>[];
    if (textController.value.text.isEmpty) {
      songs = musicList;
    } else {
      songs = filteredList;
    }

    Uri? art = null;

    await _audioQuery
        .queryArtwork(
            songs[index].id,
            ArtworkType
                .AUDIO, // artwork getter could be imporved for perfomance
            format: ArtworkFormat.JPEG,
            size: 350,
            quality: 350)
        .then((value) async {
      if (value == null) return;
      var savePath = await getApplicationDocumentsDirectory();

      await File("${savePath.path}${songs[index].title}.jpg")
          .writeAsBytes(value)
          .then((value) => art = (value.uri));
    });
    return art;
  }

  void playSong(int index) async {
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
      print(state.playing);
    });
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
