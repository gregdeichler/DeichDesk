import 'package:flutter/foundation.dart';

/// DeichDesk-only launcher state.
///
/// RustDesk remains the source of truth for peers, tags, online state,
/// credentials, and discovery. This model intentionally owns presentation
/// state only so it can evolve without forking RustDesk's data model.
class DeichDeskLauncherState extends ChangeNotifier {
  String _searchText = '';
  String? _selectedPeerId;
  String? _selectedTag;
  bool _searchExpanded = false;
  bool _accessibleDevicesExpanded = true;

  String get searchText => _searchText;
  String? get selectedPeerId => _selectedPeerId;
  String? get selectedTag => _selectedTag;
  bool get searchExpanded => _searchExpanded;
  bool get accessibleDevicesExpanded => _accessibleDevicesExpanded;

  void setSearchText(String value) {
    if (_searchText == value) return;
    _searchText = value;
    notifyListeners();
  }

  void setSelectedPeer(String? peerId) {
    if (_selectedPeerId == peerId) return;
    _selectedPeerId = peerId;
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    if (_selectedTag == tag) return;
    _selectedTag = tag;
    notifyListeners();
  }

  void setSearchExpanded(bool value) {
    if (_searchExpanded == value) return;
    _searchExpanded = value;
    if (!value) {
      _searchText = '';
    }
    notifyListeners();
  }

  void toggleAccessibleDevices() {
    _accessibleDevicesExpanded = !_accessibleDevicesExpanded;
    notifyListeners();
  }
}
