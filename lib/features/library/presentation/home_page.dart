import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musicplayer/core/widgets/drawer/app_drawer.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';
import 'package:musicplayer/features/library/presentation/widgets/home_app_bar.dart';
import 'package:musicplayer/features/library/presentation/widgets/home_body.dart';
import 'package:musicplayer/features/youtube/presentation/downloads_page.dart';
import 'package:musicplayer/features/youtube/presentation/youtube_home_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final LibraryController controller = Get.find<LibraryController>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateSearch();
    });
  }

  void _updateSearch() {
    controller.filterList();
  }

  void _rescanFiles() {
    if (controller.doneInit.isTrue) {
      controller.audioHandler.stop();
      controller.initFalse();
      controller.getSongs(refreshArt: true);
      scaffoldKey.currentState?.closeDrawer();
    }
  }

  void _onSearchClosed() {
    controller.textController.clear();
    _updateSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: HomeAppBar(
        controller: controller,
        scaffoldKey: scaffoldKey,
        onSearchChanged: _onSearchChanged,
        onSearchClosed: _onSearchClosed,
      ),
      drawer: AppDrawer(
        selectedId: 'library',
        items: [
          DrawerItem(
            id: 'library',
            icon: Icons.library_music_outlined,
            selectedIcon: Icons.library_music,
            label: 'My music',
            subtitle: 'On this device',
            onTap: () => scaffoldKey.currentState?.closeDrawer(),
          ),
          DrawerItem(
            id: 'youtube',
            icon: Icons.smart_display_outlined,
            selectedIcon: Icons.smart_display,
            label: 'YouTube',
            subtitle: 'Search & download',
            onTap: () => AppDrawer.go(context, YoutubeHomePage()),
          ),
          DrawerItem(
            id: 'downloads',
            icon: Icons.download_outlined,
            selectedIcon: Icons.download,
            label: 'Downloads',
            onTap: () =>
                AppDrawer.go(context, const DownloadsPage(), replace: false),
          ),
        ],
        bottomItem: DrawerItem(
          id: 'rescan',
          icon: Icons.refresh_rounded,
          label: 'Rescan files',
          subtitle: 'Refresh library artwork',
          onTap: _rescanFiles,
        ),
      ),
      body: HomeBody(controller: controller),
    );
  }
}
