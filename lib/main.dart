import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:musicplayer/app/app.dart';
import 'package:musicplayer/app/app_bindings.dart';
import 'package:musicplayer/core/services/art_work_utils.dart';
import 'package:musicplayer/core/services/notification_action_handler.dart';
import 'package:musicplayer/core/services/notification_manager.dart';
import 'package:musicplayer/features/youtube/data/download_queue.dart';
import 'package:musicplayer/features/youtube/presentation/downloads_page.dart';

void main() async {
  final widgetBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetBinding);
  await AppBindings.initialize();
  if (kDebugMode) {
    // Surface youtube_explode_dart diagnostics in the console.
    Logger.root.level = Level.FINER;
    Logger.root.onRecord.listen((record) {
      debugPrint(record.toString());
      if (record.error != null) {
        debugPrint("Error: ${record.error}");
        debugPrint("StackTrace: ${record.stackTrace}");
      }
    });
  }
  final notificationActionPort = ReceivePort();
  IsolateNameServer.registerPortWithName(notificationActionPort.sendPort,
      NotificationActionHandler.portName);
  notificationActionPort.listen((message) {
    final data = Map<dynamic, dynamic>.from(message as Map);
    final buttonKey = data['buttonKey'] as String?;
    final videoId = data['videoId'] as String?;
    if (buttonKey == NotificationManager.cancelActionKey) {
      if (videoId != null) DownloadQueue().cancelTask(videoId);
    } else if (Get.context != null) {
      Get.to(() => DownloadsPage());
    }
  });

  try {
    await ArtWorkUtils.saveDefaultArt();
    MetadataGod.initialize();
    await AwesomeNotifications().initialize(
        // set the icon to null if you want to use the default app icon
        'resource://mipmap/ic_launcher',
        [
          NotificationChannel(
              channelGroupKey: 'basic_channel_group',
              channelKey: 'basic_channel',
              channelName: 'Basic notifications',
              channelDescription: 'Notification channel for basic tests',
              importance: NotificationImportance.Max,
              enableLights: true,
              enableVibration: true,
              defaultColor: const Color(0xFF9D50DD),
              ledColor: Colors.white),
          NotificationChannel(
              channelGroupKey: 'download_channel_group',
              channelKey: NotificationManager.downloadChannelKey,
              channelName: 'Downloads',
              channelDescription: 'Music download progress and results',
              importance: NotificationImportance.Default,
              enableVibration: false,
              enableLights: false,
              defaultColor: const Color(0xFF9D50DD),
              channelShowBadge: false)
        ],
        // Channel groups are only visual and are not required
        channelGroups: [
          NotificationChannelGroup(
              channelGroupKey: 'basic_channel_group',
              channelGroupName: 'Basic group'),
          NotificationChannelGroup(
              channelGroupKey: 'download_channel_group',
              channelGroupName: 'Downloads')
        ],
        debug: true);
    await AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationActionHandler.onActionReceivedMethod);
  } catch (e) {
    debugPrint('Init error: $e');
  } finally {
    runApp(const MyApp());
  }
}
