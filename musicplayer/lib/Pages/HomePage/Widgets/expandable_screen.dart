import 'package:flutter/material.dart';
import 'package:musicplayer/Pages/HomePage/Widgets/SongPlayingWidget.dart';

class ExpandableSongScreen extends StatefulWidget {
  const ExpandableSongScreen({super.key});

  @override
  State<ExpandableSongScreen> createState() => _ExpandableSongScreenState();
}

class _ExpandableSongScreenState extends State<ExpandableSongScreen>
    with SingleTickerProviderStateMixin {
  final _sheet = GlobalKey();
  final _draggableScrollableController = DraggableScrollableController();
  late final AnimationController animationController;

  DraggableScrollableSheet get sheet =>
      (_sheet.currentWidget as DraggableScrollableSheet);

  @override
  void initState() {
    super.initState();
    _draggableScrollableController.addListener(_onChanged);
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    animationController.value = 1;
  }

  void _onChanged() {
    final currentSize = _draggableScrollableController.size;
    animationController.value = 1 - currentSize;
    print(animationController.value);
    if (currentSize <= 0.05) {
      animationController.animateTo(1);
      _collapse();
    } else if (currentSize >= 0.95) {
      animationController.animateTo(0);
    }
  }

  void _collapse() => _animateSheet(sheet.snapSizes!.first);

  void _anchor() => _animateSheet(sheet.snapSizes!.last);

  void _expand() => _animateSheet(sheet.maxChildSize);

  void _hide() => _animateSheet(sheet.minChildSize);

  void _animateSheet(double size) {
    // _draggableScrollableController.animateTo(
    //   size,
    //   duration: const Duration(milliseconds: 50),
    //   curve: Curves.fastOutSlowIn,
    // );
    _draggableScrollableController.jumpTo(size);
  }

  @override
  void dispose() {
    _draggableScrollableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      key: _sheet,
      initialChildSize: 0.09,
      minChildSize: 0.09,
      expand: true,
      snap: true,
      snapSizes: const [0.09, 1],
      controller: _draggableScrollableController,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
            controller: scrollController,
            child: SongPlayingWdiget(
              isFullScreen: true,
              animationController: animationController,
            ));
      },
    );
  }
}
