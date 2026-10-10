import 'package:flutter/material.dart';

import 'package:musicplayer/features/youtube/data/download_queue.dart';
import 'package:musicplayer/features/youtube/data/download_task.dart';

class DownloadTile extends StatelessWidget {
  const DownloadTile({required this.task, super.key});

  final DownloadTask task;

  bool get _isActive =>
      task.status == DownloadStatus.queued ||
      task.status == DownloadStatus.downloading ||
      task.status == DownloadStatus.converting;

  String get _statusText {
    switch (task.status) {
      case DownloadStatus.queued:
        return "Waiting…";
      case DownloadStatus.downloading:
        return "Downloading ${task.progress}%";
      case DownloadStatus.converting:
        return "Converting to MP3";
      case DownloadStatus.completed:
        return "Completed";
      case DownloadStatus.failed:
        return "Failed";
      case DownloadStatus.cancelled:
        return "Cancelled";
    }
  }

  Widget _statusWidget() {
    switch (task.status) {
      case DownloadStatus.queued:
        return const Text(
          "Waiting",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        );
      case DownloadStatus.downloading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${task.progress}%",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(value: task.progress / 100),
            ),
          ],
        );
      case DownloadStatus.converting:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return const Icon(Icons.error_outline, color: Colors.redAccent);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel_outlined, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Card(
        margin: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Container(color: Colors.black),
                    Image.network(
                      task.thumbnailUrl,
                      fit: BoxFit.fitHeight,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusWidget(),
                  if (_isActive)
                    IconButton(
                      tooltip: 'Cancel download',
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          DownloadQueue().cancelTask(task.videoId),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
