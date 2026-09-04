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
    // Reuse RustDesk's Address Book pull lifecycle. No DeichDesk peer database.
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
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Computers',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            _buildTagBar(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: DeichDeskAddressBookPeersView(
                                  preferences: preferences,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () =>
                                  preferences.setAccessibleDevicesExpanded(
                                !preferences.accessibleDevicesExpanded,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      preferences.accessibleDevicesExpanded
                                          ? Icons.expand_more
                                          : Icons.chevron_right,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Accessible Devices',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (preferences.accessibleDevicesExpanded)
                              SizedBox(
                                height: 112,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: DeichDeskAccessiblePeersView(),
                                ),
                              ),
                            const SizedBox(height: 8),
                            _Footer(
                              onConnectById: () =>
                                  DeichDeskConnectDialog.show(context),
                            ),
                          ],
                        ),
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
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Text(
              'DeichDesk',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (searchExpanded)
              SizedBox(
                width: 220,
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search computers',
                    prefixIcon: const Icon(Icons.search, size: 19),
                    suffixIcon: IconButton(
                      tooltip: 'Close search',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onSearchClosed,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: onSearchPressed,
              ),
            const SizedBox(width: 4),
            OutlinedButton.icon(
              onPressed: onThisDevicePressed,
              icon: const Icon(Icons.computer, size: 18),
              label: const Text('This Device'),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: onSettingsPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onConnectById});

  final VoidCallback onConnectById;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onConnectById,
          icon: const Icon(Icons.add_link, size: 18),
          label: const Text('Connect by ID'),
        ),
        const Spacer(),
        const DeichDeskServerStatus(),
      ],
    );
  }
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _CloseSearchIntent extends Intent {
  const _CloseSearchIntent();
}
