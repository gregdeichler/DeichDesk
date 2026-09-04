import 'package:flutter/material.dart';

/// Compact presentation-only device row used by the DeichDesk launcher.
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
        : scheme.onSurface.withOpacity(0.46);

    return Opacity(
      opacity: online ? 1 : 0.72,
      child: Material(
        color: selected ? scheme.secondaryContainer.withOpacity(0.55) : null,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onSelect,
          onDoubleTap: onConnect,
          onSecondaryTapDown: onSecondaryTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: deviceColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(width: 25, height: 25, child: osIcon),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
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
                const SizedBox(width: 8),
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
    return Row(
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
                color: online
                    ? scheme.onSurfaceVariant
                    : scheme.onSurfaceVariant.withOpacity(0.55),
              ),
        ),
      ],
    );
  }
}
