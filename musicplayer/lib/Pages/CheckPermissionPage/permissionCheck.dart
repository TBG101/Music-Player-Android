import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/Pages/HomePage/Home.dart';
import 'package:musicplayer/controllers/MusicController.dart';
import 'package:musicplayer/controllers/youtubeController.dart';
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
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    if (int.parse(androidInfo.version.release) < 13) {
      // ANDROID 12 OR LOWER
      var x = await Permission.storage.request();
      if (x.isDenied) {
        x = await Permission.storage.request();
      }
      await Future.delayed(const Duration(milliseconds: 500))
          .then((value) async {
        if (x.isGranted) {
          Get.put<AudioHandler>(await initAudioService(), permanent: true);

          Get.put(MusicController(), permanent: true); // music GetX controller

          Get.put(YoutubeController()); // music GetX controller
          Get.off(const Home());
        } else {
          setState(() {
            hasPermission = false;
          });
        }

        return null;
      });
    } else {
      // ANDOIRD 13 OR HIGHER

      var status = await [
        Permission.audio,
        Permission.mediaLibrary,
        Permission.manageExternalStorage,
        Permission.notification
      ].request();
      print(status);
      status.forEach((key, status) {
        if (status == PermissionStatus.denied ||
            status == PermissionStatus.permanentlyDenied) {
          hasPermission = false;
        }
      });
      if (hasPermission != false) {
        hasPermission = true;
      }
      setState(() {
        hasPermission;
      });

      if (hasPermission == true) {
        Get.put<AudioHandler>(await initAudioService(), permanent: true);
        Get.put(MusicController()); // music GetX controller
        Get.put(YoutubeController()); // music GetX controller
        Get.off(const Home());
      }
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
    checkPermission();
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
