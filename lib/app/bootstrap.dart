import 'package:flutter/foundation.dart';
import 'package:musicplayer/app/app_bindings.dart';
import 'package:musicplayer/core/services/app_logger.dart';
import 'package:musicplayer/core/services/art_work_utils.dart';
import 'package:musicplayer/core/services/notification_action_handler.dart';
import 'package:musicplayer/core/services/notification_manager.dart';

/// Runs all pre-[runApp] startup work: DI, logging, media infra, and
/// notifications. Notification/media failures are logged but never prevent
/// the app from launching.
class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {
    await AppBindings.initialize();
    setupDebugLogging();

    NotificationActionHandler.bindMainIsolate();
    try {
      await ArtWorkUtils.saveDefaultArt();
      await NotificationManager.initialize();
    } catch (e) {
      debugPrint('Init error: $e');
    }
  }
}
