import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/CheckPermissionPage/permissionCheck.dart';
import 'package:musicplayer/services/audioHandler.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

import 'controllers/MusicController.dart';
import 'controllers/youtubeController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put<AudioHandler>(await initAudioService(), permanent: true);

  Get.put(MusicController(), permanent: true); // music GetX controller

  Get.put(YoutubeController(), permanent: true); // music GetX controller

  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
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
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      enableLog: true,
      debugShowCheckedModeBanner: false,
      title: 'Music Player',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MyHomePage(title: 'Music Player'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const PermissionCheck();
  }
}
