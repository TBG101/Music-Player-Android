import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:musicplayer/Pages/home.dart';

Future<void> main() async {
  await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidNotificationChannelDescription: "zaefazefzae",
      notificationColor: Colors.amber);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    return const Home();
  }
}
