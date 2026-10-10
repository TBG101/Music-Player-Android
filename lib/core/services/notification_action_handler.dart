import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:musicplayer/core/services/notification_manager.dart';
import 'package:musicplayer/features/youtube/data/download_queue.dart';
import 'package:musicplayer/features/youtube/presentation/downloads_page.dart';

class NotificationActionHandler {
  static const portName = 'musicplayer.notification_actions';

  // Kept alive for the app lifetime so the isolate port is never GC'd.
  static ReceivePort? _port;

  /// Registers the main-isolate port that receives notification actions
  /// forwarded from [onActionReceivedMethod] and routes them (cancel download
  /// vs. open the downloads page). Safe to call once during startup.
  static void bindMainIsolate() {
    if (_port != null) return;
    final port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, portName);
    port.listen((message) {
      final data = Map<dynamic, dynamic>.from(message as Map);
      final buttonKey = data['buttonKey'] as String?;
      final videoId = data['videoId'] as String?;
      if (buttonKey == NotificationManager.cancelActionKey) {
        if (videoId != null) {
          DownloadQueue().cancelTask(videoId);
          // Covers the restart case where no download loop is running to
          // dismiss its own notification — the id is deterministic so we
          // can resolve it from the payload alone.
          NotificationManager.dismissForVideo(videoId);
        }
      } else if (Get.context != null) {
        Get.to(() => const DownloadsPage());
      }
    });
    _port = port;
  }

  /// awesome_notifications delivers actions from its own isolate, so forward
  /// them to the main isolate over the port registered in [bindMainIsolate].
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    IsolateNameServer.lookupPortByName(portName)?.send({
      'buttonKey': action.buttonKeyPressed,
      'videoId': action.payload?['videoId'],
    });
  }
}
