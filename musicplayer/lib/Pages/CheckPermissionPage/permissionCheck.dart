// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:musicplayer/Pages/HomePage/Home.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionCheck extends StatefulWidget {
  const PermissionCheck({super.key});

  @override
  State<PermissionCheck> createState() => _PermissionCheckState();
}

class _PermissionCheckState extends State<PermissionCheck> {
  bool? hasPermission;
  checkPermission() async {
    var x = await Permission.storage.status;
    if (x.isDenied) x = await Permission.storage.request();

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
