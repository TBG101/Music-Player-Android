import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:musicplayer/app/app.dart';
import 'package:musicplayer/app/bootstrap.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await AppBootstrap.initialize();
  runApp(const MyApp());
}
