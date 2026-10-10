import 'package:flutter/material.dart';
import 'package:musicplayer/core/widgets/search/animation_search_bar.dart';
import 'package:musicplayer/features/library/controller/library_controller.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final LibraryController controller;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClosed;

  const HomeAppBar({
    super.key,
    required this.controller,
    required this.scaffoldKey,
    required this.onSearchChanged,
    required this.onSearchClosed,
  });

  @override
  Size get preferredSize => const Size(double.infinity, 65);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: AnimationSearchBar(
          onChanged: onSearchChanged,
          onClosed: onSearchClosed,
          closeIconColor: scheme.onSurface,
          isBackButtonVisible: true,
          duration: const Duration(milliseconds: 250),
          previousScreen: null,
          backIconColor: scheme.onSurface,
          centerTitle: 'My Music',
          searchIconColor: scheme.onSurface,
          centerTitleStyle: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
              ) ??
              TextStyle(color: scheme.onSurface, fontSize: 18),
          searchTextEditingController: controller.textController,
          horizontalPadding: 5,
          centerWidget: const _HomeTitle(),
          onDrawerOpen: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
    );
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return RichText(
      overflow: TextOverflow.clip,
      textAlign: TextAlign.end,
      textDirection: TextDirection.rtl,
      maxLines: 1,
      text: TextSpan(
        text: 'My ',
        style: (textTheme.headlineSmall ??
                const TextStyle(fontSize: 23))
            .copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w400,
        ),
        children: [
          TextSpan(
            text: 'Music',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
