import 'dart:io';
import 'package:flutter/material.dart';

class SongImageWidget extends StatelessWidget {
  final String path;
  final double raduis, height, width;

  const SongImageWidget(
      {super.key,
      required this.path,
      this.raduis = 90,
      this.height = 30,
      this.width = 30});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(raduis),
      child: path.contains("lib")
          ? Image.asset(
              path,
              width: width,
              height: height,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            )
          : Image.file(
              File(path),
              width: height,
              height: width,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
    );
  }
}
