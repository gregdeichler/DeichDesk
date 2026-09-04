import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/peers_view.dart';
import 'package:flutter_hbb/deichdesk/models/deichdesk_launcher_state.dart';
import 'package:flutter_hbb/deichdesk/models/deichdesk_preferences.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_connect_dialog.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_peer_views.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_server_status.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_settings_dialog.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_tag_bar.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_this_device_dialog.dart';
import 'package:flutter_hbb/models/ab_model.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';
import 'package:get/get.dart';

/// Device-first DeichDesk launcher backed directly by RustDesk models.
class DeichDeskLauncherPage extends StatefulWidget {
  const DeichDeskLauncherPage({super.key});

  @override
  State<DeichDeskLauncherPage> createState() => _DeichDeskLauncherPageState();
}

class _DeichDeskLauncherPageState extends State<DeichDeskLauncherPage> {
  final state = DeichDeskLauncherState();
  final preferences = DeichDeskPreferences();
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    gFFI.peerTabModel.setCurrentTab(PeerTabIndex.ab.index);
    gFFI.abModel.pullAb(force: ForcePullAb.listAndCurrent, quiet: false);
  }

  @override
  void dispose() {
    peerSearchText.value = '';
    state.dispose();
    preferences.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    state.setSearchExpanded(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) searchFocusNode.requestFocus();
    });
  }

  void _setSearch(String value) {
    state.setSearchText(value);
    peerSearchText.value = value;
  }

  void _closeSearch() {
    searchController.clear();
    peerSearchText.value = '';
    state.setSearchExpanded(false);
    searchFocusNode.unfocus();
  }

  void _selectTag(String? tag) {
    state.setSelectedTag(tag);
    gFFI.abModel.selectedTags.clear();
    if (tag != null) gFFI.abModel.selectedTags.add(tag);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([state, preferences]),
      builder: (context, _) => Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              const _OpenSearchIntent(),
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
              const _OpenSearchIntent(),
          const SingleActivator(LogicalKeyboardKey.escape):
              const _CloseSearchIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
              onInvoke: (_) {
                _openSearch();
                return null;
              },
            ),
            _CloseSearchIntent: CallbackAction<_CloseSearchIntent>(
              onInvoke: (_) {
                if (state.searchExpanded) _closeSearch();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: SafeArea(
                child: Column(
                  children: [
                    _Header(
                      searchExpanded: state.searchExpanded,
                      searchController: searchController,
                      searchFocusNode: searchFocusNode,
                      onSearchPressed: _openSearch,
                      onSearchChanged: _setSearch,
                      onSearchClosed: _closeSearch,
                      onThisDevicePressed: () =>
                          DeichDeskThisDeviceDialog.show(context),
                      onSettingsPressed: () =>
                          DeichDeskSettingsDialog.show(context, preferences),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 760;
                          final horizontalPadding = compact ? 12.0 : 20.0;
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  compact ? 12 : 18,
                                  horizontalPadding,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'My Computers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -.3,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Your saved remote computers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTagBar(),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: DeichDeskAddressBookPeersView(
                                        preferences: preferences,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _AccessibleSection(
                                      expanded:
                                          preferences.accessibleDevicesExpanded,
                                      onToggle: () => preferences
                                          .setAccessibleDevicesExpanded(
                                        !preferences.accessibleDevicesExpanded,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _Footer(
                                      onConnectById: () =>
                                          DeichDeskConnectDialog.show(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagBar() {
    return Obx(() {
      final tags = gFFI.abModel.currentAbTags
          .map((tag) => tag.toString())
          .toList(growable: false);
      final visibleCount = tags.length > 4 ? 4 : tags.length;
      final visible = tags.take(visibleCount).toList(growable: false);
      final overflow = tags.skip(visibleCount).toList(growable: false);

      return DeichDeskTagBar(
        visibleTags: visible,
        overflowTags: overflow,
        selectedTag: state.selectedTag,
        onSelected: _selectTag,
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searchExpanded,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchPressed,
    required this.onSearchChanged,
    required this.onSearchClosed,
    required this.onThisDevicePressed,
    required this.onSettingsPressed,
  });

  final bool searchExpanded;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchPressed;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClosed;
  final VoidCallback onThisDevicePressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withOpacity(.5)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 20,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.desktop_windows_rounded,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                if (!compact || !searchExpanded)
                  Text(
                    'DeichDesk',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.2,
                        ),
                  ),
                const Spacer(),
                if (searchExpanded)
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 150,
                        maxWidth: compact ? 240 : 300,
                      ),
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          onChanged: onSearchChanged,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search computers',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: IconButton(
                              tooltip: 'Close search',
                              icon: const Icon(Icons.close, size: 17),
                              onPressed: onSearchClosed,
                            ),
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  _HeaderIcon(
                    tooltip: 'Search',
                    icon: Icons.search_rounded,
                    onPressed: onSearchPressed,
                  ),
                const SizedBox(width: 6),
                if (compact)
                  _HeaderIcon(
                    tooltip: 'This Device',
                    icon: Icons.computer_rounded,
                    onPressed: onThisDevicePressed,
                  )
                else
                  OutlinedButton.icon(
                    onPressed: onThisDevicePressed,
                    icon: const Icon(Icons.computer_rounded, size: 17),
                    label: const Text('This Device'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                _HeaderIcon(
                  tooltip: 'Settings',
                  icon: Icons.settings_outlined,
                  onPressed: onSettingsPressed,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        maximumSize: const Size(40, 40),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }
}

class _AccessibleSection extends StatelessWidget {
  const _AccessibleSection({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withOpacity(.52)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.devices_other_rounded,
                      size: 17,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Accessible Devices',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: scheme.outlineVariant.withOpacity(.5)),
            SizedBox(
              height: 112,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DeichDeskAccessiblePeersView(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onConnectById});

  final VoidCallback onConnectById;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: onConnectById,
                icon: const Icon(Icons.add_link, size: 18),
                label: const Text('Connect by ID'),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: DeichDeskServerStatus(),
              ),
            ],
          );
        }

        return Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: onConnectById,
              icon: const Icon(Icons.add_link, size: 18),
              label: const Text('Connect by ID'),
            ),
            const Spacer(),
            const DeichDeskServerStatus(),
          ],
        );
      },
    );
  }
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _CloseSearchIntent extends Intent {
  const _CloseSearchIntent();
}
