import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Configures third-party package diagnostics (e.g. youtube_explode_dart)
/// for debug builds. No-op in release/profile.
void setupDebugLogging() {
  if (!kDebugMode) return;
  Logger.root.level = Level.FINER;
  Logger.root.onRecord.listen((record) {
    debugPrint(record.toString());
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
      debugPrint('StackTrace: ${record.stackTrace}');
    }
  });
}
