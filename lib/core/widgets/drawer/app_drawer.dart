import 'package:flutter/material.dart';

class DrawerItem {
  final String id;
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const DrawerItem({
    required this.id,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}

class AppDrawer extends StatelessWidget {
  final List<DrawerItem> items;
  final DrawerItem? bottomItem;
  final String? selectedId;
  final Widget? header;

  const AppDrawer({
    super.key,
    required this.items,
    this.bottomItem,
    this.selectedId,
    this.header,
  });

  /// Closes the drawer first, then navigates.
  ///
  /// Use [replace] for top-level destinations (Library <-> YouTube) so the
  /// back stack doesn't pile up `Home > YouTube > Home...`.
  /// Use `replace: false` for sub-pages (e.g. Downloads) so Back returns.
  static void go(BuildContext context, Widget page, {bool replace = true}) {
    Navigator.pop(context);
    final route = MaterialPageRoute(builder: (_) => page);
    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      width: 304,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header ?? _DefaultHeader(colorScheme: colorScheme, textTheme: textTheme),
              const SizedBox(height: 12),
              Text(
                'Browse',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 4),
                _NavTile(
                  item: items[i],
                  selected: selectedId != null && items[i].id == selectedId,
                ),
              ],
              const Spacer(),
              if (bottomItem != null) ...[
                const Divider(height: 24),
                _BottomTile(item: bottomItem!),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultHeader extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _DefaultHeader({required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/icon.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: 'My ',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                    children: [
                      TextSpan(
                        text: 'Music',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Local & YouTube player',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final DrawerItem item;
  final bool selected;

  const _NavTile({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: colorScheme.primaryContainer,
      selectedColor: colorScheme.onPrimaryContainer,
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(selected ? (item.selectedIcon ?? item.icon) : item.icon),
      title: Text(
        item.label,
        style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
      ),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: selected
            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      onTap: item.onTap,
    );
  }
}

class _BottomTile extends StatelessWidget {
  final DrawerItem item;

  const _BottomTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(item.icon, size: 22),
      title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      onTap: item.onTap,
    );
  }
}
