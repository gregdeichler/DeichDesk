import 'package:flutter/material.dart';

/// Polished presentation-only device row used by the DeichDesk launcher.
///
/// Peer actions are callbacks so RustDesk's existing connect/context-menu
/// behavior stays authoritative. [osIcon] accepts RustDesk's existing platform
/// image widget rather than translating platforms into a second icon system.
class DeichDeskDeviceRow extends StatelessWidget {
  const DeichDeskDeviceRow({
    super.key,
    required this.peerId,
    required this.name,
    required this.secondaryText,
    required this.online,
    required this.osIcon,
    required this.deviceColor,
    required this.selected,
    required this.onSelect,
    required this.onConnect,
    this.onSecondaryTap,
    this.trailing,
  });

  final String peerId;
  final String name;
  final String secondaryText;
  final bool online;
  final Widget osIcon;
  final Color deviceColor;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onConnect;
  final GestureTapDownCallback? onSecondaryTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = online
        ? scheme.onSurface
        : scheme.onSurface.withOpacity(0.58);
    final cardColor = selected
        ? scheme.primaryContainer.withOpacity(0.38)
        : scheme.surfaceContainerLow;
    final borderColor = selected
        ? scheme.primary.withOpacity(0.35)
        : scheme.outlineVariant.withOpacity(0.52);

    return AnimatedOpacity(
      opacity: online ? 1 : 0.78,
      duration: const Duration(milliseconds: 140),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onSelect,
          onDoubleTap: onConnect,
          onSecondaryTapDown: onSecondaryTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: deviceColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(width: 27, height: 27, child: osIcon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w650,
                              letterSpacing: -0.1,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: foreground.withOpacity(0.72),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (trailing != null) trailing! else _Status(online: online),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = online
        ? scheme.primaryContainer.withOpacity(0.55)
        : scheme.surfaceContainerHighest;
    final foreground = online
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant.withOpacity(0.72);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? scheme.primary : scheme.outline,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'Online' : 'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
