import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of a storage permission request.
///
/// [storageGranted] gates entry to the app. [notificationGranted] is
/// best-effort only — denial shows a warning and continues.
class PermissionResult {
  const PermissionResult({
    required this.storageGranted,
    required this.notificationGranted,
    required this.permanentlyDenied,
  });

  final bool storageGranted;
  final bool notificationGranted;
  final bool permanentlyDenied;
}

/// Pure platform logic for storage access. No GetX, no UI — easy to mock.
class PermissionService {
  PermissionService({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  Future<PermissionResult> requestStoragePermissions() async {
    if (!Platform.isAndroid) {
      return const PermissionResult(
        storageGranted: true,
        notificationGranted: true,
        permanentlyDenied: false,
      );
    }

    final androidInfo = await _deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      return _requestAndroid13Plus();
    }
    return _requestAndroid12Below();
  }

  /// Android 13+: [Permission.audio] + [Permission.manageExternalStorage].
  /// Notification is requested separately and never blocks.
  Future<PermissionResult> _requestAndroid13Plus() async {
    final audioStatus = await Permission.audio.request();

    // Fire-and-forget: warn and continue on denial (per user choice).
    final notificationGranted =
        (await Permission.notification.request()).isGranted;

    // MANAGE_EXTERNAL_STORAGE opens a system settings screen, not a dialog,
    // so it must be requested separately.
    bool manageGranted = await Permission.manageExternalStorage.isGranted;
    if (!manageGranted) {
      manageGranted =
          (await Permission.manageExternalStorage.request()).isGranted;
    }

    final storageGranted = audioStatus.isGranted && manageGranted;
    final managePermanentlyDenied =
        !manageGranted && await Permission.manageExternalStorage.isPermanentlyDenied;
    return PermissionResult(
      storageGranted: storageGranted,
      notificationGranted: notificationGranted,
      permanentlyDenied:
          !storageGranted && (audioStatus.isPermanentlyDenied || managePermanentlyDenied),
    );
  }

  Future<PermissionResult> _requestAndroid12Below() async {
    final status = await Permission.storage.request();
    return PermissionResult(
      storageGranted: status.isGranted,
      notificationGranted: true,
      permanentlyDenied: status.isPermanentlyDenied,
    );
  }

  Future<void> openSettings() => openAppSettings();
}
