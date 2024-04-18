import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  var yt = YoutubeExplode();
  // var x = yt.search("youtbe videos");
  // VideoSearchList first = await x.asStream().first;
  // print(first.first.title);

  // Completer c = Completer();

  // var id = first.first.id;

  // var vid = await yt.videos.get(id);

  // var manifest = (await yt.videos.streamsClient.getManifest(id)).streams.first;

  // var stream = yt.videos.streamsClient.get(manifest);
  // print(stream.first);
  // await c.future;
  var val = await yt.search("music").asStream().first;
  print(val);
}
