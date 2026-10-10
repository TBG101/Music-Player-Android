import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppPaths {
  static Future<Directory> get base async =>
      await getApplicationDocumentsDirectory();

  static Future<Directory> get artworkDir async {
    final dir = Directory("${(await base).path}/artwork");
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}