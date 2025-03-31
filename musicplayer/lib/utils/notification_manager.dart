import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationManager {
  // singleton
  NotificationManager._internal();
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;

  final __notification = AwesomeNotifications();
  var lastNotificationTime = DateTime.now();

  void showNotificationInfo(String title, int notificationId,
      {String? body, bool? error}) {
    // show notification
    __notification.createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        customSound: "asset://assets/sound/uwu.mp3",
        category: NotificationCategory.Event,
        color: error == true || error != null ? Colors.red : Colors.blue,
      ),
    );
  }

  void notificationUpdate(String title, int progress, int notificationId) {
    // Basically update a notification after a certain time
    // to avoid spamming the notification bar
    if (lastNotificationTime.isBefore(
        lastNotificationTime.add(const Duration(milliseconds: 500)))) {
      return;
    }
    lastNotificationTime = DateTime.now();
    __notification.createNotification(
      content: NotificationContent(
          id: notificationId,
          channelKey: 'basic_channel',
          actionType: ActionType.Default,
          title: 'Downloading',
          body: title,
          notificationLayout: NotificationLayout.ProgressBar,
          category: NotificationCategory.Progress,
          progress: progress,
          locked: true,
          color: Colors.blue),
    );
  }
}
