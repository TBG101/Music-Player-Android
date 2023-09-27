// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:musicplayer/Pages/HomePage/Home.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionCheck extends StatefulWidget {
  const PermissionCheck({super.key});

  @override
  State<PermissionCheck> createState() => _PermissionCheckState();
}

class _PermissionCheckState extends State<PermissionCheck> {
  bool? hasPermission;

  checkPermission() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    if (int.parse(androidInfo.version.release) < 13) {
      // ANDROID 12 OR LOWER
      var x = await Permission.storage.request();
      if (x.isDenied) {
        x = await Permission.storage.request();
      }
      await Future.delayed(const Duration(milliseconds: 500)).then((value) {
        if (x.isGranted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (Route<dynamic> route) => false,
          );
        } else {
          setState(() {
            hasPermission = false;
          });
        }

        return null;
      });
    } else {
      // ANDOIRD 13 OR HIGHER
      var x = await Permission.audio.request();
      await Permission.mediaLibrary.request();
      await Permission.manageExternalStorage.request();
      await Permission.storage.request();

      await Future.delayed(const Duration(milliseconds: 2500)).then((value) {
        if (x.isGranted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (Route<dynamic> route) => false,
          );
        } else {
          setState(() {
            hasPermission = false;
          });
        }

        return null;
      });
    }
  }

  String waitingForPemission() {
    if (hasPermission == null) {
      return "Waiting For Permission";
    } else if (hasPermission == false) {
      return "Permission Denied";
    } else {
      return "Accept Permission to continue";
    }
  }

  @override
  void initState() {
    checkPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(waitingForPemission()),
      ),
    );
  }
}
