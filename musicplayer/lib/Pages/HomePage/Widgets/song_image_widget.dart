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
      child: path.contains("lib")
          ? Image.asset(
              path,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              gaplessPlayback: true,
              cacheWidth: cacheWidth,
            )
          : Image.file(
              File.fromUri(uri ?? Uri.parse(path)),
              fit: BoxFit.cover,
              isAntiAlias: true,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              cacheWidth:
                  cacheWidth * 2, // Increase cache width for higher quality
            ),
    );
  }
}
