import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MusicController extends GetxController {
  var musicList = [].obs;

  getSongs() {
    final OnAudioQuery _audioQuery = OnAudioQuery();
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
    
  }
}
