import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lecle_flutter_absolute_path/lecle_flutter_absolute_path.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final player = AudioPlayer();

  final _audioHandler = GetIt.instance<AudioHandler>();

  Future<bool> requestPermission() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
      return true;
    } else {
      return true;
    }
  }

  bool hasPermission = false;
  @override
  void initState() {
    requestPermission().then((value) {
      setState(() {
        hasPermission = value;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 8,
          title: const Text("data"),
        ),
        body: !hasPermission
            ? const Text("No Content Found")
            : SafeArea(
                child: FutureBuilder<List<SongModel>>(
                  // Default values:
                  future: _audioQuery.querySongs(
                    sortType: SongSortType.DATE_ADDED,
                    orderType: OrderType.DESC_OR_GREATER,
                    uriType: UriType.EXTERNAL,
                    ignoreCase: true,
                  ),
                  builder: (context, item) {
                    if (item.hasError) {
                      return Text(item.error.toString());
                    }

                    if (item.data == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (item.data!.isEmpty) return const Text("Nothing found!");

                    return ListView.builder(
                      itemCount: item.data!.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () async {
                            String? _path = item.data![index].uri;

                            // var x = File.fromUri(Uri.parse(_path!));

                            // print(x.path);

                            // String? filePath =
                            //     await LecleFlutterAbsolutePath.getAbsolutePath(
                            //             fileExtension: "mp3", uri: _path!)
                            //         .then((value) {
                            //   print(value);
                            //   return value;
                            // });

                            var _item = MediaItem(
                              id: _path!,
                              title: item.data![index].title,
                              artist: item.data![index].artist,
                              album: item.data![index].album,
                              duration: Duration(
                                  milliseconds:
                                      item.data![index].duration ?? 0),
                            );
                            _audioHandler.playMediaItem(_item);
                          },

                          title: Text(item.data![index].title),
                          subtitle:
                              Text(item.data![index].artist ?? "No Artist"),

                          dense: false,

                          // This Widget will query/load image.
                          // You can use/create your own widget/method using [queryArtwork].
                          leading: QueryArtworkWidget(
                            controller: _audioQuery,
                            id: item.data![index].id,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget:
                                Image.asset("lib/assets/img/NotFound.JPG"),
                          ),
                        );
                      },
                    );
                  },
                ),
              ));
  }
}
