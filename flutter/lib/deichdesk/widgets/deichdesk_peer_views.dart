import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/peer_card.dart';
import 'package:flutter_hbb/common/widgets/peers_view.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/deichdesk/widgets/deichdesk_device_row.dart';
import 'package:flutter_hbb/desktop/widgets/material_mod_popup_menu.dart'
    as mod_menu;
import 'package:flutter_hbb/desktop/widgets/popup_menu.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';

/// Address Book peers rendered with DeichDesk rows while continuing to use
/// RustDesk's peer model, online polling, filtering pipeline, connect path, and
/// AddressBookPeerCard action menu implementation.
class DeichDeskAddressBookPeersView extends BasePeersView {
  DeichDeskAddressBookPeersView({super.key})
      : super(
          peerTabIndex: PeerTabIndex.ab,
          peerFilter: _matchesSelectedTags,
          peerCardBuilder: (peer) => _DeichDeskAddressBookPeerRow(peer: peer),
        );

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
