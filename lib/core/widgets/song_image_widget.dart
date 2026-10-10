import 'dart:io';
import 'package:flutter/material.dart';

class SongImageWidget extends StatelessWidget {
  final String path;
  final double raduis, height, width;
  final int cacheWidth;
  final Uri? uri;
  const SongImageWidget({
    super.key,
    this.path = "",
    this.raduis = 90,
    this.height = 30,
    this.width = 30,
    this.cacheWidth = 30,
    this.uri,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(raduis),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (uri != null) {
      return _fileImage(File.fromUri(uri!));
    }

    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        gaplessPlayback: true,
        cacheWidth: cacheWidth,
      );
    }

    return _fileImage(File(path));
  }

  Widget _fileImage(File file) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      isAntiAlias: true,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      cacheWidth: cacheWidth * 2, // Increase cache width for higher quality
    );
  }
}
