import 'package:flutter/material.dart';

class KCustomButton extends StatelessWidget {
  final Widget widget;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final double? radius;

  const KCustomButton(
      {Key? key,
      required this.widget,
      required this.onPressed,
      this.radius,
      this.onLongPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? 50),
        child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius ?? 50),
            child: InkWell(
                radius: 100,
                splashColor: scheme.primary.withValues(alpha: 0.08),
                highlightColor: scheme.primary.withValues(alpha: 0.04),
                onTap: onPressed,
                onLongPress: onLongPress,
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    child: widget))));
  }
}

class KBackButton extends StatelessWidget {
  final Widget? previousScreen;
  final Color? iconColor;
  final IconData? icon;
  final void Function() onDrawerOpen;
  const KBackButton(
      {Key? key,
      required this.previousScreen,
      required this.iconColor,
      required this.icon,
      required this.onDrawerOpen})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
                radius: 100,
                splashColor: scheme.primary.withValues(alpha: 0.08),
                highlightColor: scheme.primary.withValues(alpha: 0.04),
                onTap: onDrawerOpen,
                child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: SizedBox(
                        width: 10,
                        height: 10,
                        child: Icon(icon ?? Icons.arrow_back_ios_new,
                            color: iconColor ?? scheme.onSurfaceVariant,
                            size: 7))))));
  }
}
