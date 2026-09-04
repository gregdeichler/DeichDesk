import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/peer_card.dart';
import 'package:flutter_hbb/common/widgets/peers_view.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/deichdesk/models/deichdesk_preferences.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_device_row.dart';
import 'package:flutter_hbb/desktop/widgets/material_mod_popup_menu.dart'
    as mod_menu;
import 'package:flutter_hbb/desktop/widgets/popup_menu.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';
import 'package:get/get.dart';

/// Address Book peers rendered in DeichDesk's persistent manual order.
///
/// RustDesk still owns the peer list, online state, search matching, tags,
/// connection path, and context-menu actions. DeichDesk owns only the order of
/// RustDesk peer IDs.
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
    _onlineTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _queryOnlines(),
    );
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
      animation: Listenable.merge([
        gFFI.abModel.peersModel,
        widget.preferences,
      ]),
      builder: (context, _) => Obx(() {
        // Register reactive dependencies used by _visiblePeers().
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
                  child: _DeichDeskAddressBookPeerRow(peer: peers[index]),
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
                child: _DeichDeskAddressBookPeerRow(peer: peers[index]),
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
          peerCardBuilder: (peer) => _DeichDeskDiscoveredPeerRow(peer: peer),
        );

  @override
  Widget build(BuildContext context) {
    final widget = super.build(context);
    bind.mainLoadLanPeers();
    bind.mainDiscover();
    return widget;
  }
}

mixin _DeichDeskPeerRowMixin on BasePeerCard {
  Future<List<mod_menu.PopupMenuEntry<String>>> _menuEntries(
      BuildContext context) async {
    final entries = await _buildMenuItems(context);
    return entries
        .map((entry) => entry.build(
              context,
              const MenuConfig(
                commonColor: CustomPopupMenuTheme.commonColor,
                height: CustomPopupMenuTheme.height,
                dividerHeight: CustomPopupMenuTheme.dividerHeight,
              ),
            ))
        .expand((items) => items)
        .toList();
  }

  Future<void> showDeichDeskPeerMenu(
      BuildContext context, Offset position) async {
    await mod_menu.showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: await _menuEntries(context),
      elevation: 8,
    );
  }

  Widget buildDeichDeskRow(BuildContext context) {
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
          showDeichDeskPeerMenu(context, details.globalPosition),
    );
  }
}

class _DeichDeskAddressBookPeerRow extends AddressBookPeerCard
    with _DeichDeskPeerRowMixin {
  _DeichDeskAddressBookPeerRow({required super.peer});

  @override
  Widget build(BuildContext context) => buildDeichDeskRow(context);
}

class _DeichDeskDiscoveredPeerRow extends DiscoveredPeerCard
    with _DeichDeskPeerRowMixin {
  _DeichDeskDiscoveredPeerRow({required super.peer});

  @override
  Widget build(BuildContext context) => buildDeichDeskRow(context);
}
