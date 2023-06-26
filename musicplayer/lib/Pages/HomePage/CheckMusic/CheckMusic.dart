import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/controllers/MusicController.dart';

class CheckMusic extends StatefulWidget {
  const CheckMusic({super.key});

  @override
  State<CheckMusic> createState() => _CheckMusicState();
}

class _CheckMusicState extends State<CheckMusic> {
  final MusicController controller = Get.put(MusicController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
