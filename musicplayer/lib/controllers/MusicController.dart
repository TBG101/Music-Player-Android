import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

class MusicController extends GetxController {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  final RxList<SongModel> musicList = <SongModel>[].obs;

  final RxBool hasError = false.obs;
  late AudioHandler audioHandler;

  final Rxn<MediaItem> song = Rxn<MediaItem>();

  initHandler() {
    audioHandler = Get.find<AudioHandler>();
  }

  GetSongPlaying() {
    return song;
  }

  // var audioHandler =
  //     GetIt.instance<AudioHandler>(); // could be changed with getx

  void getSongs() async {
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
      });
    } catch (e) {
      debugPrint(e.toString());
      hasError.value = true;
    }
  }

  saveArtImage(int index) async {
    Uri? art = null;
    await _audioQuery
        .queryArtwork(
            musicList[index].id,
            ArtworkType
                .AUDIO, // artwork getter could be imporved for perfomance
            format: ArtworkFormat.JPEG,
            size: 500,
            quality: 500)
        .then((value) async {
      if (value == null) return;
      var savePath = await getApplicationDocumentsDirectory();

      await File("${savePath.path}${musicList[index].title}.jpg")
          .writeAsBytes(value)
          .then((value) => art = (value.uri));
    });
    return art;
  }

  void playSong(int index) async {
    String? _path = musicList[index].uri;
    Uri? art = await saveArtImage(index);
    var _item = MediaItem(
      id: _path!,
      title: musicList[index].title,
      artist: musicList[index].artist,
      album: musicList[index].album,
      artUri: art,
      duration: Duration(milliseconds: musicList[index].duration ?? 0),
    );

    audioHandler.playMediaItem(_item); // play the song
  }

  itemPlaying() {
    audioHandler.mediaItem.listen((item) {
      song.value = item;
    });
  }
  

  Widget artWorkGetter(int index) {
    // artwork widget in Home Page
    return QueryArtworkWidget(
      controller: _audioQuery,
      id: musicList[index].id,
      type: ArtworkType.AUDIO,
      nullArtworkWidget: Image.asset("lib/assets/img/NotFound.JPG"),
    );
  }
}
