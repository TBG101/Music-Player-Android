import 'package:flutter/material.dart';


class LocalNotificationService {
  // Instance of Flutternotification plugin
  // static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  // static void initialize() {
  //   // Initialization  setting for android
  //   const InitializationSettings initializationSettingsAndroid =
  //       InitializationSettings(
  //           android: AndroidInitializationSettings("@drawable/ic_launcher"));
  //   _notificationsPlugin.initialize(
  //     initializationSettingsAndroid,
  //     // to handle event when we receive notification
  //     onDidReceiveNotificationResponse: (details) {
  //       if (details.input != null) {}
  //     },
  //   );
  // }

  // static Future<void> display() async {
  //   // To display the notification in device
  //   try {
  //     final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  //     // ignore: prefer_const_constructors
  //     NotificationDetails notificationDetails = NotificationDetails(
  //       android: const AndroidNotificationDetails(
  //         "Channel_Id 1", "Main Channel",
  //         groupKey: "gfg",
  //         color: Colors.green,
  //         importance: Importance.max,
  //         priority: Priority.max, playSound: false,
  //         // different sound for
  //         // different notification
  //         showProgress: true,
  //         progress: 20,
  //       ),
  //     );
  //     await _notificationsPlugin.show(id, " message.notification?.title",
  //         "message.notification?.body", notificationDetails);
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  // }
}
