import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart';
import 'package:flutter_hbb/common/widgets/peer_card.dart';
import 'package:flutter_hbb/common/widgets/peers_view.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/deichdesk/models/deichdesk_preferences.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_device_row.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';

/// Address Book peers rendered in DeichDesk's persistent manual order.
/// RustDesk remains authoritative for peer data, online state and connections.
class DeichDeskAddressBookPeersView extends StatefulWidget {
  const DeichDeskAddressBookPeersView({
    super.key,
    required this.preferences,
  });

  final DeichDeskPreferences preferences;

  @override
  State<DeichDeskAddressBookPeersView> createState() =>
      _DeichDeskAddressBookPeersViewState();
}

class _DeichDeskAddressBookPeersViewState
    extends State<DeichDeskAddressBookPeersView> {
  Timer? _onlineTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _queryOnlines());
    _onlineTimer =
        Timer.periodic(const Duration(seconds: 6), (_) => _queryOnlines());
  }

  @override
  void dispose() {
    _onlineTimer?.cancel();
    super.dispose();
  }

  void _queryOnlines() {
    final ids = gFFI.abModel.peersModel.peers
        .map((peer) => peer.id)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isNotEmpty) bind.queryOnlines(ids: ids);
  }

  static bool _matchesSelectedTags(Peer peer) {
    final selected = gFFI.abModel.selectedTags;
    if (selected.isEmpty) return true;

    final selectedNormal = selected.where((tag) => tag != kUntagged).toList();
    if (selected.contains(kUntagged)) {
      if (peer.tags.isEmpty) return true;
      if (selectedNormal.isEmpty) return false;
    }

    if (gFFI.abModel.filterByIntersection.value) {
      return selectedNormal.every(peer.tags.contains);
    }
    return selectedNormal.any(peer.tags.contains);
  }

  Future<List<Peer>> _visiblePeers() async {
    var peers = widget.preferences.orderPeers(gFFI.abModel.peersModel.peers);
    peers = peers.where(_matchesSelectedTags).toList(growable: false);

    final search = peerSearchText.value.trim().toLowerCase();
    if (search.isEmpty) return peers;

    final matches = await Future.wait(
      peers.map((peer) => matchPeer(search, peer, PeerTabIndex.ab)),
    );
    final filtered = <Peer>[];
    for (var i = 0; i < peers.length; i++) {
      if (matches[i]) filtered.add(peers[i]);
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([gFFI.abModel.peersModel, widget.preferences]),
      builder: (context, _) => Obx(() {
        peerSearchText.value;
        gFFI.abModel.selectedTags.length;
        gFFI.abModel.filterByIntersection.value;

        return FutureBuilder<List<Peer>>(
          future: _visiblePeers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final peers = snapshot.data!;
            if (peers.isEmpty) {
              return Center(
                child: Text(
                  peerSearchText.value.isNotEmpty ||
                          gFFI.abModel.selectedTags.isNotEmpty
                      ? 'No matching computers'
                      : 'No computers in this Address Book',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }

            final canReorder = peerSearchText.value.trim().isEmpty &&
                gFFI.abModel.selectedTags.isEmpty;

            if (!canReorder) {
              return ListView.builder(
                itemCount: peers.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _DeichDeskPeerRow(
                    peer: peers[index],
                    tab: PeerTabIndex.ab,
                  ),
                ),
              );
            }

            return ReorderableListView.builder(
              buildDefaultDragHandles: true,
              itemCount: peers.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                if (oldIndex == newIndex) return;

                final reordered = peers.toList(growable: true);
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                await widget.preferences.saveDisplayedOrder(reordered);
              },
              itemBuilder: (context, index) => Padding(
                key: ValueKey(peers[index].id),
                padding: const EdgeInsets.only(bottom: 4),
                child: _DeichDeskPeerRow(
                  peer: peers[index],
                  tab: PeerTabIndex.ab,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// LAN/discovered peers are the source for DeichDesk's Accessible Devices.
class DeichDeskAccessiblePeersView extends BasePeersView {
  DeichDeskAccessiblePeersView({super.key})
      : super(
          peerTabIndex: PeerTabIndex.lan,
          peerCardBuilder: (peer) =>
              _DeichDeskPeerRow(peer: peer, tab: PeerTabIndex.lan),
        );

  @override
  Widget build(BuildContext context) {
    final widget = super.build(context);
    bind.mainLoadLanPeers();
    bind.mainDiscover();
    return widget;
  }
}

class _DeichDeskPeerRow extends StatelessWidget {
  const _DeichDeskPeerRow({required this.peer, required this.tab});

  final Peer peer;
  final PeerTabIndex tab;

  @override
  Widget build(BuildContext context) {
    final secondary = hideUsernameOnCard == true
        ? peer.hostname
        : '${peer.username}${peer.username.isNotEmpty && peer.hostname.isNotEmpty ? '@' : ''}${peer.hostname}';
    final displayName = peer.alias.isEmpty ? formatID(peer.id) : peer.alias;
    final selected = gFFI.peerTabModel.isPeerSelected(peer.id);

    return DeichDeskDeviceRow(
      peerId: peer.id,
      name: displayName,
      secondaryText: secondary,
      online: peer.online,
      osIcon: getPlatformImage(peer.platform, size: 25),
      deviceColor: str2color('${peer.id}${peer.platform}', 0x7f),
      selected: selected,
      onSelect: () => gFFI.peerTabModel.select(peer),
      onConnect: () => connectInPeerTab(context, peer, tab),
      onSecondaryTap: (details) =>
          _showPeerMenu(context, details.globalPosition),
    );
  }

  Future<void> _showPeerMenu(BuildContext context, Offset position) async {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'connect', child: Text('Connect')),
      const PopupMenuItem(value: 'file', child: Text('File Transfer')),
      const PopupMenuItem(value: 'camera', child: Text('View Camera')),
      const PopupMenuItem(value: 'terminal', child: Text('Terminal')),
      if (isDesktop && peer.platform != kPeerPlatformAndroid)
        const PopupMenuItem(value: 'tcp', child: Text('TCP Tunneling')),
      if (!peer.online)
        const PopupMenuItem(value: 'wol', child: Text('Wake-on-LAN')),
      if (!isWeb)
        const PopupMenuItem(
          value: 'relay',
          child: Text('Toggle Always Connect via Relay'),
        ),
      if (isWindows && peer.platform == kPeerPlatformWindows)
        const PopupMenuItem(value: 'rdp', child: Text('RDP')),
      if (isWindows)
        const PopupMenuItem(
          value: 'shortcut',
          child: Text('Create Desktop Shortcut'),
        ),
      if (tab == PeerTabIndex.lan && gFFI.userModel.userName.isNotEmpty) ...[
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'add_ab',
          child: Text('Add to Address Book'),
        ),
      ],
      if (tab == PeerTabIndex.ab && gFFI.abModel.current.canWrite()) ...[
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        if (gFFI.abModel.currentAbTags.isNotEmpty)
          const PopupMenuItem(value: 'tags', child: Text('Edit Tags')),
        const PopupMenuItem(value: 'note', child: Text('Edit Note')),
        if (gFFI.abModel.current.isPersonal() && peer.hash.isNotEmpty)
          const PopupMenuItem(
            value: 'forget_password',
            child: Text('Forget Password'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'remove',
          child: Text('Remove from Address Book'),
        ),
      ],
      if (tab == PeerTabIndex.lan) ...[
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'remove_discovered', child: Text('Remove')),
      ],
    ];

    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items,
    );

    if (action == null || !context.mounted) return;
    await _runAction(context, action);
  }

  Future<void> _runAction(BuildContext context, String action) async {
    switch (action) {
      case 'connect':
        connectInPeerTab(context, peer, tab);
        break;
      case 'file':
        connectInPeerTab(context, peer, tab, isFileTransfer: true);
        break;
      case 'camera':
        connectInPeerTab(context, peer, tab, isViewCamera: true);
        break;
      case 'terminal':
        connectInPeerTab(context, peer, tab, isTerminal: true);
        break;
      case 'tcp':
        connectInPeerTab(context, peer, tab, isTcpTunneling: true);
        break;
      case 'wol':
        bind.mainWol(id: peer.id);
        break;
      case 'relay':
        final current = mainGetPeerBoolOptionSync(peer.id, kOptionForceAlwaysRelay);
        await bind.mainSetPeerOption(
          id: peer.id,
          key: kOptionForceAlwaysRelay,
          value: bool2option(kOptionForceAlwaysRelay, !current),
        );
        showToast(translate('Successful'));
        break;
      case 'rdp':
        connectInPeerTab(context, peer, tab, isRDP: true);
        break;
      case 'shortcut':
        bind.mainCreateShortcut(id: peer.id);
        showToast(translate('Successful'));
        break;
      case 'add_ab':
        addPeersToAbDialog([Peer.copy(peer)]);
        break;
      case 'rename':
        renameDialog(
          oldName: peer.alias,
          onSubmit: (newName) async {
            await gFFI.abModel.changeAlias(id: peer.id, alias: newName);
            await bind.mainSetPeerAlias(id: peer.id, alias: newName);
          },
        );
        break;
      case 'tags':
        editAbTagDialog(gFFI.abModel.getPeerTags(peer.id), (selected) async {
          await gFFI.abModel.changeTagForPeers([peer.id], selected);
        });
        break;
      case 'note':
        editAbPeerNoteDialog(peer.id);
        break;
      case 'forget_password':
        await gFFI.abModel.changePersonalHashPassword(peer.id, '');
        await bind.mainForgetPassword(id: peer.id);
        showToast(translate('Successful'));
        break;
      case 'remove':
        deleteConfirmDialog(
          () async => gFFI.abModel.deletePeers([peer.id]),
          'Remove "${peer.alias.isEmpty ? formatID(peer.id) : peer.alias}" from the Address Book? This does not uninstall DeichDesk from that computer.',
        );
        break;
      case 'remove_discovered':
        await bind.mainRemoveDiscovered(id: peer.id);
        bind.mainLoadLanPeers();
        break;
    }
  }
}
