import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Sends the Android YouTube user agent for googlevideo requests.
///
/// Stream URLs obtained from the `c=ANDROID` clients are served with 403 when
/// downloaded using a browser user agent. The library then refetches the
/// manifest and retries the identical request in a silent loop, so the
/// download never progresses. Matching the user agent of the client that
/// produced the manifest makes googlevideo serve the bytes.
class AndroidStreamHttpClient extends YoutubeHttpClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host.endsWith('googlevideo.com')) {
      request.headers['user-agent'] =
          'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip';
    }
    return super.send(request);
  }
}
