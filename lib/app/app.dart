import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/app/app_theme.dart';
import 'package:musicplayer/features/permissions/presentation/permission_check.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      enableLog: true,
      debugShowCheckedModeBanner: false,
      title: 'Lowwave Music',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const PermissionCheck(),
    );
  }
}
