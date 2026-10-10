import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/features/permissions/controller/permission_controller.dart';

/// Pure UI for the startup permission gate. All logic lives in
/// [PermissionController]; this widget only renders its [PermissionState].
class PermissionCheck extends StatelessWidget {
  const PermissionCheck({super.key});

  PermissionController get _controller =>
      Get.isRegistered<PermissionController>()
          ? Get.find<PermissionController>()
          : Get.put(PermissionController());

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      body: Center(
        child: Obx(() {
          switch (controller.state.value) {
            case PermissionState.checking:
              return const CircularProgressIndicator();
            case PermissionState.initializing:
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing your library…'),
                ],
              );
            case PermissionState.denied:
              return _DeniedView(controller: controller);
            case PermissionState.initFailed:
              return _InitFailedView(controller: controller);
          }
        }),
      ),
    );
  }
}

class _DeniedView extends StatelessWidget {
  const _DeniedView({required this.controller});

  final PermissionController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Storage permission is required'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.retry,
            child: const Text('Grant Permission'),
          ),
          Obx(() => controller.permanentlyDenied.value
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: controller.openSettings,
                    child: const Text('Open Settings'),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _InitFailedView extends StatelessWidget {
  const _InitFailedView({required this.controller});

  final PermissionController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Failed to start the audio service'),
          const SizedBox(height: 8),
          Obx(() => Text(
                controller.error.value ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.retry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
