// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:musicplayer/core/widgets/search/search_bar_buttons.dart';

class AnimationSearchBar extends StatefulWidget {
  const AnimationSearchBar({
    Key? key,
    this.searchBarWidth,
    this.searchBarHeight,
    this.previousScreen,
    this.backIconColor,
    this.closeIconColor,
    this.searchIconColor,
    this.centerTitle,
    this.centerTitleStyle,
    this.searchFieldHeight,
    this.searchFieldDecoration,
    this.cursorColor,
    this.textStyle,
    this.hintText,
    this.hintStyle,
    required this.onChanged,
    required this.onClosed,
    required this.searchTextEditingController,
    required this.centerWidget,
    this.horizontalPadding,
    this.verticalPadding,
    this.isBackButtonVisible,
    this.backIcon,
    this.duration,
    required this.onDrawerOpen,
    this.searchYoutube,
  }) : super(key: key);

  ///
  final double? searchBarWidth;
  final double? searchBarHeight;
  final double? searchFieldHeight;
  final double? horizontalPadding;
  final double? verticalPadding;
  final Widget? previousScreen;
  final Color? backIconColor;
  final Color? closeIconColor;
  final Color? searchIconColor;
  final Color? cursorColor;
  final String? centerTitle;
  final String? hintText;
  final bool? isBackButtonVisible;
  final IconData? backIcon;
  final TextStyle? centerTitleStyle;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Decoration? searchFieldDecoration;
  final Duration? duration;
  final TextEditingController searchTextEditingController;
  final Function(String) onChanged;
  final Function(String)? searchYoutube;
  final Function() onClosed;
  final void Function() onDrawerOpen;
  final Widget centerWidget;

  @override
  State<AnimationSearchBar> createState() => _AnimationSearchBarState();
}

class _AnimationSearchBarState extends State<AnimationSearchBar> {
  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _closeSearch() {
    _focusNode.unfocus();
    setState(() => _isSearching = false);
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final _duration = widget.duration ?? const Duration(milliseconds: 500);
    final _searchFieldHeight = widget.searchFieldHeight ?? 40;
    final _hPadding =
        widget.horizontalPadding != null ? widget.horizontalPadding! * 2 : 0;
    final _searchBarWidth = widget.searchBarWidth ??
        MediaQuery.of(context).size.width - _hPadding;
    final _isBackButtonVisible = widget.isBackButtonVisible ?? true;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding ?? 0,
          vertical: widget.verticalPadding ?? 0),
      child: SizedBox(
        width: _searchBarWidth,
        height: widget.searchBarHeight ?? 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            /// back Button
            _isBackButtonVisible
                ? AnimatedOpacity(
                    opacity: _isSearching ? 0 : 1,
                    duration: _duration,
                    child: AnimatedContainer(
                        curve: Curves.easeInOutCirc,
                        width: _isSearching ? 0 : 50,
                        height: _isSearching ? 0 : 50,
                        duration: _duration,
                        child: FittedBox(
                            child: KBackButton(
                          icon: Icons.menu_rounded,
                          iconColor: scheme.onSurface,
                          previousScreen: widget.previousScreen,
                          onDrawerOpen: widget.onDrawerOpen,
                        ))))
                : AnimatedContainer(
                    curve: Curves.easeInOutCirc,
                    width: _isSearching ? 0 : 35,
                    height: _isSearching ? 0 : 35,
                    duration: _duration),

            /// text
            AnimatedOpacity(
              opacity: _isSearching ? 0 : 1,
              duration: _duration,
              child: AnimatedContainer(
                curve: Curves.easeInOutCirc,
                width: _isSearching ? 0 : _searchBarWidth - 100,
                duration: _duration,
                alignment: Alignment.center,
                child: FittedBox(child: widget.centerWidget),
              ),
            ),

            /// close search
            AnimatedOpacity(
              opacity: _isSearching ? 1 : 0,
              duration: _duration,
              child: AnimatedContainer(
                curve: Curves.easeInOutCirc,
                width: _isSearching ? 40 : 0,
                height: _isSearching ? 40 : 0,
                duration: _duration,
                child: FittedBox(
                  child: KCustomButton(
                    widget: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.close,
                            size: 60,
                            color: widget.closeIconColor ??
                                scheme.onSurfaceVariant)),
                    onPressed: _closeSearch,
                  ),
                ),
              ),
            ),

            /// input panel
            AnimatedOpacity(
              opacity: _isSearching ? 1 : 0,
              duration: _duration,
              child: AnimatedContainer(
                curve: Curves.easeInOutCirc,
                duration: _duration,
                width: _isSearching
                    ? _searchBarWidth - 55 - (widget.horizontalPadding ?? 0 * 2)
                    : 0,
                height: _isSearching ? _searchFieldHeight : 20,
                margin: EdgeInsets.only(
                    left: _isSearching ? 5 : 0,
                    right: _isSearching ? 10 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: widget.searchFieldDecoration ??
                    BoxDecoration(
                        color: scheme.surface,
                        border: Border.all(
                            color: scheme.outlineVariant, width: .5),
                        borderRadius: BorderRadius.circular(15)),
                child: TextField(
                  controller: widget.searchTextEditingController,
                  focusNode: _focusNode,
                  onTapOutside: (_) => _focusNode.unfocus(),
                  cursorColor: widget.cursorColor ?? scheme.primary,
                  onSubmitted: (textToSeach) {
                    if (widget.searchYoutube == null) {
                      debugPrint("NO youtube function");
                    } else {
                      widget.searchYoutube!(textToSeach);
                    }
                  },
                  style: widget.textStyle ??
                      TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hintText ?? 'Search here...',
                    hintStyle: widget.hintStyle ??
                        TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400),
                    disabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none),
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none),
                    border: const OutlineInputBorder(
                        borderSide: BorderSide.none),
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ),

            ///  search button
            AnimatedOpacity(
              opacity: _isSearching ? 0 : 1,
              duration: _duration,
              child: AnimatedContainer(
                curve: Curves.easeInOutCirc,
                duration: _duration,
                width: _isSearching ? 0 : 40,
                height: _isSearching ? 0 : 40,
                child: FittedBox(
                  child: KCustomButton(
                      widget: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                              Icons.search_rounded,
                              size: 60,
                              color: widget.searchIconColor ??
                                  scheme.onSurface)),
                      onPressed: () {
                        setState(() => _isSearching = true);
                        _focusNode.requestFocus();
                      }),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
