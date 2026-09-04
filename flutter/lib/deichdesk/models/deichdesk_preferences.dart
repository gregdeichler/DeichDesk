import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/peer_model.dart';

/// DeichDesk-only persistent preferences.
///
/// These values intentionally do not replace RustDesk-owned data. Peer order is
/// keyed only by RustDesk peer ID; the Address Book itself remains authoritative.
class DeichDeskPreferences extends ChangeNotifier {
  static const _peerOrderKey = 'deichdesk-peer-order-v1';
  static const _accessibleExpandedKey = 'deichdesk-accessible-expanded';

  DeichDeskPreferences() {
    _peerOrder = _loadPeerOrder();
    _accessibleDevicesExpanded =
        bind.mainGetLocalOption(key: _accessibleExpandedKey) != 'N';
  }

  late List<String> _peerOrder;
  late bool _accessibleDevicesExpanded;

  List<String> get peerOrder => List.unmodifiable(_peerOrder);
  bool get accessibleDevicesExpanded => _accessibleDevicesExpanded;

  List<String> _loadPeerOrder() {
    final raw = bind.mainGetLocalOption(key: _peerOrderKey);
    if (raw.isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>[];
      return decoded
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: true);
    } catch (_) {
      return <String>[];
    }
  }

  /// Returns peers in DeichDesk's saved manual order.
  ///
  /// IDs not seen before are appended in the order supplied by RustDesk. IDs
  /// no longer present are retained in storage so a temporarily absent device
  /// can recover its old position if it returns.
  List<Peer> orderPeers(Iterable<Peer> peers) {
    final source = peers.toList(growable: false);
    if (_peerOrder.isEmpty) return source;

    final byId = <String, Peer>{for (final peer in source) peer.id: peer};
    final ordered = <Peer>[];

    for (final id in _peerOrder) {
      final peer = byId.remove(id);
      if (peer != null) ordered.add(peer);
    }

    for (final peer in source) {
      if (byId.remove(peer.id) != null) ordered.add(peer);
    }

    return ordered;
  }

  Future<void> saveDisplayedOrder(List<Peer> peers) async {
    final visibleIds = peers.map((peer) => peer.id).toList(growable: false);
    final visibleSet = visibleIds.toSet();

    // Replace positions for currently present peers while retaining positions
    // for IDs not currently loaded from the Address Book.
    final retainedMissing =
        _peerOrder.where((id) => !visibleSet.contains(id)).toList();
    _peerOrder = <String>[...visibleIds, ...retainedMissing];

    await bind.mainSetLocalOption(
      key: _peerOrderKey,
      value: jsonEncode(_peerOrder),
    );
    notifyListeners();
  }

  Future<void> setAccessibleDevicesExpanded(bool value) async {
    if (_accessibleDevicesExpanded == value) return;
    _accessibleDevicesExpanded = value;
    await bind.mainSetLocalOption(
      key: _accessibleExpandedKey,
      value: value ? 'Y' : 'N',
    );
    notifyListeners();
  }

  Future<void> resetPeerOrder() async {
    _peerOrder = <String>[];
    await bind.mainSetLocalOption(key: _peerOrderKey, value: '');
    notifyListeners();
  }
}
