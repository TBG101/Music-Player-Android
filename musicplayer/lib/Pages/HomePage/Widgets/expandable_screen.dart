import 'package:flutter/material.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/SongPlayingWidget.dart';

class ExpandableSongScreen extends StatefulWidget {
  const ExpandableSongScreen({super.key});

  @override
  State<ExpandableSongScreen> createState() => _ExpandableSongScreenState();
}

class _ExpandableSongScreenState extends State<ExpandableSongScreen>
    with SingleTickerProviderStateMixin {
  final _sheetKey = GlobalKey();
  final _draggableController = DraggableScrollableController();
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _draggableController.addListener(_onScrollChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..value = 1; // Initialize animation value to fully collapsed
  }

  void _onScrollChanged() {
    final currentSize = _draggableController.size;
    _animationController.value = 1 - currentSize;

    if (currentSize <= 0.05) {
      _animationController.animateTo(1);
      _animateSheetToSize(sheet.snapSizes!.first); // Collapse
    } else if (currentSize >= 0.95) {
      _animationController.animateTo(0); // Fully expanded
    }
  }

  void _animateSheetToSize(double size) {
    _draggableController.jumpTo(size);
  }

  DraggableScrollableSheet get sheet =>
      _sheetKey.currentWidget as DraggableScrollableSheet;

  @override
  void dispose() {
    _draggableController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topBarHeight = MediaQuery.of(context).padding.top;
    final maxChildSize = 1 - (topBarHeight / MediaQuery.of(context).size.height);

    return DraggableScrollableSheet(
      key: _sheetKey,
      initialChildSize: 0.09,
      minChildSize: 0.09,
      maxChildSize: maxChildSize,
      snap: true,
      snapSizes: [0.09, maxChildSize],
      controller: _draggableController,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: SongPlayingWdiget(
            isFullScreen: true,
            animationController: _animationController,
          ),
        );
      },
    );
  }
}
