import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/deichdesk/models/deichdesk_launcher_state.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_tag_bar.dart';

/// Phase-1 DeichDesk launcher shell.
///
/// This intentionally starts as a presentation shell. The next integration
/// slice wires RustDesk's Address Book, discovered peers, connect callbacks,
/// This Device panel, and context menus into these slots.
class DeichDeskLauncherPage extends StatefulWidget {
  const DeichDeskLauncherPage({super.key});

  @override
  State<DeichDeskLauncherPage> createState() => _DeichDeskLauncherPageState();
}

class _DeichDeskLauncherPageState extends State<DeichDeskLauncherPage> {
  final state = DeichDeskLauncherState();
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  @override
  void dispose() {
    state.dispose();
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

  void _closeSearch() {
    searchController.clear();
    state.setSearchExpanded(false);
    searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
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
                      onSearchChanged: state.setSearchText,
                      onSearchClosed: _closeSearch,
                      onThisDevicePressed: () {
                        // RustDesk ServerModel/ID/password panel is wired in
                        // during the integration slice.
                      },
                      onSettingsPressed: () {
                        // Existing RustDesk settings navigation is wired in
                        // during the integration slice.
                      },
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
                            DeichDeskTagBar(
                              // Temporary shell values. These are replaced by
                              // gFFI.abModel tags in the integration slice.
                              visibleTags: const [],
                              overflowTags: const [],
                              selectedTag: state.selectedTag,
                              onSelected: state.setSelectedTag,
                            ),
                            const SizedBox(height: 8),
                            const Expanded(
                              child: _IntegrationSlot(
                                label: 'RustDesk Address Book peers',
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: state.toggleAccessibleDevices,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      state.accessibleDevicesExpanded
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
                            if (state.accessibleDevicesExpanded)
                              const SizedBox(
                                height: 104,
                                child: _IntegrationSlot(
                                  label: 'RustDesk discovered peers',
                                ),
                              ),
                            const SizedBox(height: 8),
                            _Footer(
                              onConnectById: () {
                                // Existing RustDesk Connect-by-ID UI is wired
                                // here during the integration slice.
                              },
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
        Text(
          'Server status',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _IntegrationSlot extends StatelessWidget {
  const _IntegrationSlot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _CloseSearchIntent extends Intent {
  const _CloseSearchIntent();
}
