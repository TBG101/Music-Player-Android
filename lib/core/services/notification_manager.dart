import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import 'package:musicplayer/core/services/notification_action_handler.dart';

class _ProgressSample {
  _ProgressSample(this.bytes, this.time);

  final int bytes;
  final DateTime time;
}

class NotificationManager {
  // singleton
  NotificationManager._internal();
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;

  static const downloadChannelKey = 'download_channel';
  static const cancelActionKey = 'DOWNLOAD_CANCEL';

  /// Derives a stable, non-zero Android notification id from a [videoId].
  ///
  /// Uses FNV-1a (not Dart's [Object.hashCode], which isn't stable across
  /// runs) mapped into 1..2^31-1 so:
  /// * concurrent downloads never overwrite each other,
  /// * retries of the same video update the same notification,
  /// * ids survive app restarts (no counter reset collisions),
  /// * id 0 is avoided (treated specially on Android).
  static int notificationIdForVideo(String videoId) {
    var hash = 0x811c9dc5;
    for (var i = 0; i < videoId.length; i++) {
      hash ^= videoId.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return (hash % 2147483646) + 1;
  }

  /// Dismisses whatever notification belongs to [videoId], if present.
  static Future<void> dismissForVideo(String videoId) =>
      NotificationManager().dismissDownload(notificationIdForVideo(videoId));

  /// Registers notification channels/groups and the background action
  /// listener. Safe to call once during startup.
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
            channelGroupKey: 'download_channel_group',
            channelKey: downloadChannelKey,
            channelName: 'Downloads',
            channelDescription: 'Music download progress and results',
            importance: NotificationImportance.Default,
            enableVibration: false,
            enableLights: false,
            defaultColor: const Color(0xFF9D50DD),
            channelShowBadge: false)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'download_channel_group',
            channelGroupName: 'Downloads')
      ],
      debug: true,
    );
    await AwesomeNotifications().setListeners(
        onActionReceivedMethod:
            NotificationActionHandler.onActionReceivedMethod);
  }

  final __notification = AwesomeNotifications();
  final _lastUpdateByNotificationId = <int, DateTime>{};
  final _lastSampleByNotificationId = <int, _ProgressSample>{};

  void showDownloadProgress({
    required int notificationId,
    required String videoId,
    required String videoTitle,
    required int progress,
    int downloadedBytes = 0,
    int totalBytes = 0,
    String? thumbnailUrl,
    String? stageLabel,
  }) {
    final now = DateTime.now();
    final lastUpdate = _lastUpdateByNotificationId[notificationId];
    if (lastUpdate != null &&
        now.isBefore(lastUpdate.add(const Duration(milliseconds: 500)))) {
      return;
    }
    _lastUpdateByNotificationId[notificationId] = now;

    __notification.createNotification(
      actionButtons: [
        NotificationActionButton(
          key: cancelActionKey,
          label: 'Cancel',
          actionType: ActionType.SilentAction,
        ),
      ],
      content: NotificationContent(
        id: notificationId,
        channelKey: downloadChannelKey,
        actionType: ActionType.Default,
        title: videoTitle,
        body: _progressBody(notificationId, downloadedBytes, totalBytes, now,
            stageLabel),
        notificationLayout: NotificationLayout.ProgressBar,
        category: NotificationCategory.Progress,
        progress: progress.toDouble(),
        largeIcon: thumbnailUrl,
        locked: true,
        autoDismissible: false,
        color: Colors.blue,
        payload: {'videoId': videoId},
      ),
    );
  }

  void showConverting({
    required int notificationId,
    required String videoId,
    required String videoTitle,
    int? percent,
    String? thumbnailUrl,
  }) {
    _clearProgressState(notificationId);
    __notification.createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: downloadChannelKey,
        actionType: ActionType.Default,
        title: videoTitle,
        body: percent == null ? 'Converting to MP3' : 'Converting to MP3 · $percent%',
        notificationLayout: NotificationLayout.ProgressBar,
        category: NotificationCategory.Progress,
        progress: percent?.toDouble(),
        largeIcon: thumbnailUrl,
        locked: true,
        autoDismissible: false,
        color: Colors.blue,
        payload: {'videoId': videoId},
      ),
    );
  }

  void showDownloadFinished({
    required int notificationId,
    required String videoId,
    required String videoTitle,
    int? totalBytes,
    String? thumbnailUrl,
  }) {
    _clearProgressState(notificationId);
    __notification.createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: downloadChannelKey,
        actionType: ActionType.Default,
        title: 'Download finished',
        body: totalBytes != null && totalBytes > 0
            ? '$videoTitle · ${_formatBytes(totalBytes)}'
            : videoTitle,
        notificationLayout: NotificationLayout.BigPicture,
        category: NotificationCategory.Status,
        largeIcon: thumbnailUrl,
        bigPicture: thumbnailUrl,
        locked: false,
        color: Colors.blue,
        payload: {'videoId': videoId},
      ),
    );
  }

  void showDownloadFailed({
    required int notificationId,
    required String videoId,
    required String videoTitle,
    String? error,
    String? thumbnailUrl,
  }) {
    _clearProgressState(notificationId);
    var failureDetail = videoTitle;
    if (error != null && error.isNotEmpty) {
      final trimmed =
          error.length > 120 ? '${error.substring(0, 120)}…' : error;
      failureDetail = '$videoTitle · $trimmed';
    }
    __notification.createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: downloadChannelKey,
        actionType: ActionType.Default,
        title: 'Download failed',
        body: failureDetail,
        category: NotificationCategory.Error,
        largeIcon: thumbnailUrl,
        locked: false,
        color: Colors.red,
        payload: {'videoId': videoId},
      ),
    );
  }

  Future<void> dismissDownload(int notificationId) async {
    _clearProgressState(notificationId);
    await __notification.dismiss(notificationId);
  }

  void _clearProgressState(int notificationId) {
    _lastUpdateByNotificationId.remove(notificationId);
    _lastSampleByNotificationId.remove(notificationId);
  }

  String _progressBody(int notificationId, int downloadedBytes, int totalBytes,
      DateTime now, String? stageLabel) {
    if (totalBytes <= 0) {
      return stageLabel ?? 'Fetching stream data…';
    }
    final previous = _lastSampleByNotificationId[notificationId];
    _lastSampleByNotificationId[notificationId] =
        _ProgressSample(downloadedBytes, now);

    final ofTotal = '${_formatBytes(downloadedBytes)} of ${_formatBytes(totalBytes)}';
    if (previous == null) return ofTotal;

    final seconds = now.difference(previous.time).inMilliseconds / 1000;
    if (seconds <= 0) return ofTotal;
    final bytesPerSecond = (downloadedBytes - previous.bytes) / seconds;
    if (bytesPerSecond <= 0) return ofTotal;

    final speed = '${_formatBytes(bytesPerSecond.round())}/s';
    final remainingBytes = totalBytes - downloadedBytes;
    if (remainingBytes <= 0) return '$ofTotal · $speed';
    final eta = Duration(seconds: (remainingBytes / bytesPerSecond).round());
    return '$ofTotal · $speed · ${_formatEta(eta)} left';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  String _formatEta(Duration eta) {
    if (eta.inHours > 0) {
      return '${eta.inHours}h ${eta.inMinutes % 60}m';
    }
    if (eta.inMinutes > 0) {
      return '${eta.inMinutes}m ${eta.inSeconds % 60}s';
    }
    return '${eta.inSeconds}s';
  }
}
