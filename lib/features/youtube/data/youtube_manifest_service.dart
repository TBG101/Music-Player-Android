import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeManifestService {
  List<StreamInfo> selectAudioSources(StreamManifest manifest) {
    final candidates = <StreamInfo>[];

    // Prefer audio-only streams (smaller download), webm/opus first.
    final audioOnly = manifest.audioOnly.toList();
    final webmOnly =
        audioOnly.where((stream) => stream.container.name == "webm").toList();
    final bestAudioOnly =
        _highestBitrate(webmOnly.isNotEmpty ? webmOnly : audioOnly);
    if (bestAudioOnly != null) candidates.add(bestAudioOnly);

    // Muxed streams (video+audio, e.g. itag 18) still serve bytes even when
    // googlevideo blocks audio-only streams without PO tokens; ffmpeg extracts
    // the audio track, so use the best muxed stream as fallback.
    final bestMuxed = _highestBitrate(manifest.muxed.toList());
    if (bestMuxed != null) candidates.add(bestMuxed);

    if (candidates.isEmpty) {
      throw Exception("No audio or muxed streams found");
    }
    return candidates;
  }

  T? _highestBitrate<T extends StreamInfo>(List<T> streams) {
    if (streams.isEmpty) return null;
    return streams.reduce((a, b) =>
        a.bitrate.kiloBitsPerSecond > b.bitrate.kiloBitsPerSecond ? a : b);
  }
}
