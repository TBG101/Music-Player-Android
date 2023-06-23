import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

class MusicController extends GetxController {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  RxList<SongModel> musicList = <SongModel>[].obs;
  final RxBool _hasError = false.obs;

  final _audioHandler =
      GetIt.instance<AudioHandler>(); // could be changed with getx

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
        musicList.value = songsList;
        musicList.refresh();
      });
    } on Exception catch (e) {
      debugPrint(e.toString());
      _hasError.value = true;
    }
  }

  void playSong(int index) async {
    Uri? art = null;
    await _audioQuery
        .queryArtwork(musicList[index].id, ArtworkType.AUDIO,
            format: ArtworkFormat.JPEG, size: 500, quality: 500)
        .then((value) async {
      if (value == null) return;
      var savePath = await getApplicationDocumentsDirectory();

      await File("${savePath.path}${musicList[index].title}.jpg")
          .writeAsBytes(value)
          .then((value) => art = (value.uri));
    });
    String? _path = musicList[index].uri;

    var _item = MediaItem(
      id: _path!,
      title: musicList[index].title,
      artist: musicList[index].artist,
      album: musicList[index].album,
      artUri: art,
      duration: Duration(milliseconds: musicList[index].duration ?? 0),
    );

    _audioHandler.playMediaItem(_item);
  }
}
