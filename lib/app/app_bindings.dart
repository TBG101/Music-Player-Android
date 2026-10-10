import 'package:get/get.dart';
import 'package:musicplayer/features/library/data/audio_library_cache.dart';
import 'package:musicplayer/features/library/data/audio_library_repository.dart';

/// Registers the long-lived data-layer dependencies before `runApp`.
class AppBindings {
  const AppBindings._();

  static Future<void> initialize() async {
    final database = await AudioLibraryCache.create();
    Get.put<AudioLibraryCache>(database);
    Get.put<AudioLibraryRepository>(
      AudioLibraryRepository(database),
    );
  }
}
