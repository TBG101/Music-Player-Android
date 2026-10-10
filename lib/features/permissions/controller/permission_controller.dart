import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/library/presentation/home_page.dart';
import 'package:musicplayer/features/permissions/data/permission_service.dart';
import 'package:musicplayer/features/player/data/audio_handler.dart';
import 'package:musicplayer/features/youtube/controller/youtube_controller.dart';

enum PermissionState { checking, denied, initializing, initFailed }

/// Owns the startup gate: storage permission -> heavy services -> Home.
///
/// Heavy dependencies ([AudioPlayerHandler], [LibraryController],
/// [YoutubeController]) are registered lazily here with
/// `permanent: true`, only after the grant. That keeps the permission
/// screen cheap and cold start fast — moving them to `AppBindings.initialize`
/// would pay the `AudioService.init` cost before it can ever be used.
class PermissionController extends GetxController {
  PermissionController([PermissionService? service])
      : _service = service ?? PermissionService();

  final PermissionService _service;

  final Rx<PermissionState> state = PermissionState.checking.obs;
  final RxBool permanentlyDenied = false.obs;
  final RxnString error = RxnString();

  @override
  void onReady() {
    super.onReady();
    checkAndInit();
  }

  Future<void> retry() => checkAndInit();

  Future<void> openSettings() => _service.openSettings();

  Future<void> checkAndInit() async {
    state.value = PermissionState.checking;
    error.value = null;
    permanentlyDenied.value = false;

    late final PermissionResult result;
    try {
      result = await _service.requestStoragePermissions();
    } catch (e) {
      debugPrint('Permission check failed: $e');
      error.value = e.toString();
      state.value = PermissionState.denied;
      FlutterNativeSplash.remove();
      return;
    }

    if (!result.storageGranted) {
      permanentlyDenied.value = result.permanentlyDenied;
      state.value = PermissionState.denied;
      FlutterNativeSplash.remove();
      return;
    }

    state.value = PermissionState.initializing;
    try {
      await _initServices();
      // Splash is removed by LibraryController.onReady on Home.
      if (!result.notificationGranted) {
        _warnNotificationDenied();
      }
    } catch (e) {
      debugPrint('Audio service init failed: $e');
      error.value = e.toString();
      state.value = PermissionState.initFailed;
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _initServices() async {
    if (!Get.isRegistered<AudioPlayerHandler>()) {
      Get.put<AudioPlayerHandler>(
        await initAudioService(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<LibraryController>()) {
      Get.put(LibraryController(), permanent: true);
    }
    if (!Get.isRegistered<YoutubeController>()) {
      Get.put(YoutubeController(), permanent: true);
    }
    Get.off(() => const Home());
  }

  void _warnNotificationDenied() {
    // Post-navigation so the snackbar lands on Home, not the dying page.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.context == null) return;
      Get.snackbar(
        'Notifications off',
        'Download progress will not show. Enable them in Settings.',
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }
}
