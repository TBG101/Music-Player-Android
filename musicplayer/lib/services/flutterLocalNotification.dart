import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  // Instance of Flutternotification plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() {
    // Initialization setting for android
    const InitializationSettings initializationSettingsAndroid =
        InitializationSettings(
            android: AndroidInitializationSettings("@drawable/ic_launcher"));
    _notificationsPlugin.initialize(
      initializationSettingsAndroid,
      // to handle event when we receive notification
      onDidReceiveNotificationResponse: (details) {
        if (details.input != null) {}
      },
    );
  }

  static Future<void> display(String id) async {
    NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(id, "azf",
          groupKey: "gfg",
          color: Colors.green,
          importance: Importance.max,
          showProgress: true,
          progress: 0),
    );
    await _notificationsPlugin.show(
      int.parse(id),
      "download Started",
      "message.notification?.body",
      notificationDetails,
      payload: "message.data['route']",
    );
  }
}
