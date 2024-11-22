import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/HomePage/Home.dart';
import 'package:musicplayer/controllers/music_controller.dart';
import 'package:musicplayer/controllers/youtube_controller.dart';
import 'package:musicplayer/services/audioHandler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionCheck extends StatefulWidget {
  const PermissionCheck({super.key});

  @override
  State<PermissionCheck> createState() => _PermissionCheckState();
}

class _PermissionCheckState extends State<PermissionCheck> {
  bool? hasPermission;

  Future<void> checkPermission() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    bool permissionGranted = false;

    if (int.parse(androidInfo.version.release) < 13) {
      // ANDROID 12 OR LOWER
      var storagePermission = await Permission.storage.request();
      if (storagePermission.isGranted) {
        permissionGranted = true;
      } else {
        permissionGranted = false;
      }
    } else {
      // ANDROID 13 OR HIGHER
      final statuses = await [
        Permission.audio,
        Permission.mediaLibrary,
        Permission.manageExternalStorage,
        Permission.notification
      ].request();

      permissionGranted = statuses.values.every((status) => status.isGranted);
    }

    setState(() {
      hasPermission = permissionGranted;
    });

    if (permissionGranted) {
      // Initialize services and navigate to Home
      Get.put<AudioPlayerHandler>(await initAudioService(), permanent: true);
      Get.put(MusicController(), permanent: true); // music GetX controller
      Get.put(YoutubeController()); // youtube GetX controller
      Get.off(const Home());
    }
  }

  Widget waitingForPemission() {
    if (hasPermission == null) {
      return const CircularProgressIndicator();
    } else if (hasPermission == false) {
      return const Text("Permission Denied");
    } else {
      return const Text("Accept Permission to continue");
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, checkPermission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: waitingForPemission(),
      ),
    );
  }
}
