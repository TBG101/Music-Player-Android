import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'download_task.dart';

class DownloadQueue {
  // singleton
  DownloadQueue._privateConstructor();
  static final DownloadQueue _instance = DownloadQueue._privateConstructor();
  factory DownloadQueue() {
    return _instance;
  }

  final RxList<DownloadTask> tasks = <DownloadTask>[].obs;
  final List<(String videoId, Future<void> Function() action)> _pending = [];
  final Set<String> _cancelRequested = {};
  bool downloading = false;

  void addTask(DownloadTask task, Future<void> Function() action) {
    tasks.removeWhere((t) => t.videoId == task.videoId);
    tasks.add(task);
    _pending.add((task.videoId, action));
    startQuee();
  }

  Future<void> startQuee() async {
    if (downloading == true) return;
    downloading = true;
    while (_pending.isNotEmpty) {
      final (videoId, action) = _pending.removeAt(0);
      try {
        await action();
      } catch (e) {
        debugPrint('Download task crashed: $e');
      } finally {
        _cancelRequested.remove(videoId);
      }
    }
    downloading = false;
  }

  bool isCancelled(String videoId) => _cancelRequested.contains(videoId);

  void cancelTask(String videoId) {
    _pending.removeWhere((entry) => entry.$1 == videoId);
    final task = byVideoId(videoId);
    if (task == null) return;
    final activeStatuses = {
      DownloadStatus.queued,
      DownloadStatus.downloading,
      DownloadStatus.converting,
    };
    if (!activeStatuses.contains(task.status)) return;
    if (task.status != DownloadStatus.queued) {
      _cancelRequested.add(videoId);
    }
    task.status = DownloadStatus.cancelled;
    tasks.refresh();
  }

  DownloadTask? byVideoId(String videoId) {
    for (final task in tasks) {
      if (task.videoId == videoId) return task;
    }
    return null;
  }

  void setStatus(String videoId, DownloadStatus status) {
    final task = byVideoId(videoId);
    if (task == null) return;
    task.status = status;
    tasks.refresh();
  }

  void updateProgress(String videoId,
      {int? percent, int? downloadedBytes, int? totalBytes}) {
    final task = byVideoId(videoId);
    if (task == null) return;
    var changed = false;
    if (percent != null && task.progress != percent) {
      task.progress = percent;
      changed = true;
    }
    if (downloadedBytes != null && task.downloadedBytes != downloadedBytes) {
      task.downloadedBytes = downloadedBytes;
      changed = true;
    }
    if (totalBytes != null && task.totalBytes != totalBytes) {
      task.totalBytes = totalBytes;
      changed = true;
    }
    if (changed) tasks.refresh();
  }

  void clearFinished() {
    tasks.removeWhere((t) =>
        t.status == DownloadStatus.completed ||
        t.status == DownloadStatus.failed ||
        t.status == DownloadStatus.cancelled);
  }
}
