import 'package:flutter/material.dart';

/// Compact DeichDesk tag/filter bar.
///
/// The parent decides which tags fit in [visibleTags]. Everything else belongs
/// in [overflowTags] and is rendered under More, preventing horizontal
/// scrolling and multi-row wrapping.
class DeichDeskTagBar extends StatelessWidget {
  const DeichDeskTagBar({
    super.key,
    required this.visibleTags,
    required this.overflowTags,
    required this.selectedTag,
    required this.onSelected,
  });

  final List<String> visibleTags;
  final List<String> overflowTags;
  final String? selectedTag;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedOverflow = selectedTag != null &&
        !visibleTags.contains(selectedTag) &&
        overflowTags.contains(selectedTag);

    return SizedBox(
      height: 34,
      child: Row(
        children: [
          _TagChip(
            label: 'All',
            selected: selectedTag == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 6),
          for (final tag in visibleTags) ...[
            _TagChip(
              label: tag,
              selected: selectedTag == tag,
              onTap: () => onSelected(tag),
            ),
            const SizedBox(width: 6),
          ],
          if (overflowTags.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'More tags',
              onSelected: onSelected,
              itemBuilder: (context) => overflowTags
                  .map(
                    (tag) => PopupMenuItem<String>(
                      value: tag,
                      child: Row(
                        children: [
                          if (selectedTag == tag) ...[
                            const Icon(Icons.check, size: 16),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(tag, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              child: _TagChip(
                label: selectedOverflow ? selectedTag! : 'More',
                selected: selectedOverflow,
                trailing: const Icon(Icons.arrow_drop_down, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? scheme.secondary.withOpacity(0.45)
                  : scheme.outlineVariant.withOpacity(0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
