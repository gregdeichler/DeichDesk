import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:flutter_hbb/utils/platform_channel.dart';
import 'package:get/get.dart';
import 'package:window_size/window_size.dart' as window_size;

/// Owns the RustDesk main-window plumbing DeichDesk still relies on while
/// keeping the visible home page entirely DeichDesk-owned.
///
/// This is intentionally infrastructure-only: no stock RustDesk home UI is
/// mounted here. Connection dispatch, multi-window coordination, deep-link
/// listening, local identity refresh, service state and app-block handling stay
/// on RustDesk's existing APIs.
class DeichDeskDesktopBootstrap extends StatefulWidget {
  const DeichDeskDesktopBootstrap({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DeichDeskDesktopBootstrap> createState() =>
      _DeichDeskDesktopBootstrapState();
}

class _DeichDeskDesktopBootstrapState extends State<DeichDeskDesktopBootstrap>
    with WidgetsBindingObserver {
  final RxBool _block = false.obs;
  final RxBool _svcStopped = false.obs;

  Timer? _identityTimer;
  StreamSubscription? _uniLinksSubscription;

  @override
  void initState() {
    super.initState();

    _identityTimer = periodic_immediate(const Duration(seconds: 1), () async {
      await gFFI.serverModel.fetchID();
      final stopped = await mainGetBoolOption(kOptionStopService);
      if (_svcStopped.value != stopped) {
        _svcStopped.value = stopped;
      }
    });

    Get.put<RxBool>(_svcStopped, tag: 'stop-service');
    rustDeskWinManager.registerActiveWindowListener(onActiveWindowChanged);
    rustDeskWinManager.setMethodHandler(_handleWindowMethod);
    _uniLinksSubscription = listenUniLinks();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<dynamic> _handleWindowMethod(
    dynamic call,
    int fromWindowId,
  ) async {
    if (call.method != kWindowBumpMouse) {
      debugPrint(
        '[Main] call ${call.method} with args ${call.arguments} from window $fromWindowId',
      );
    }

    if (call.method == kWindowMainWindowOnTop) {
      windowOnTop(null);
    } else if (call.method == kWindowRefreshCurrentUser) {
      gFFI.userModel.refreshCurrentUser();
    } else if (call.method == kWindowGetScreenList) {
      return jsonEncode(
        (await window_size.getScreenList()).map(_screenToMap).toList(),
      );
    } else if (call.method == kWindowActionRebuild) {
      reloadCurrentWindow();
    } else if (call.method == kWindowEventShow) {
      await rustDeskWinManager.registerActiveWindow(call.arguments['id']);
    } else if (call.method == kWindowEventHide) {
      await rustDeskWinManager.unregisterActiveWindow(call.arguments['id']);
    } else if (call.method == kWindowConnect) {
      await connectMainDesktop(
        call.arguments['id'],
        isFileTransfer: call.arguments['isFileTransfer'],
        isViewCamera: call.arguments['isViewCamera'],
        isTerminal: call.arguments['isTerminal'],
        isTcpTunneling: call.arguments['isTcpTunneling'],
        isRDP: call.arguments['isRDP'],
        password: call.arguments['password'],
        forceRelay: call.arguments['forceRelay'],
        connToken: call.arguments['connToken'],
      );
    } else if (call.method == kWindowBumpMouse) {
      return RdPlatformChannel.instance.bumpMouse(
        dx: call.arguments['dx'],
        dy: call.arguments['dy'],
      );
    } else if (call.method == kWindowEventMoveTabToNewWindow) {
      final args = call.arguments.split(',');
      final windowId = int.tryParse(args[0]);
      WindowType? windowType;
      try {
        windowType = WindowType.values.byName(args[3]);
      } catch (e) {
        debugPrint("Failed to parse window type '${call.arguments}': $e");
      }
      if (windowId != null && windowType != null) {
        await rustDeskWinManager.moveTabToNewWindow(
          windowId,
          args[1],
          args[2],
          windowType,
        );
      }
    } else if (call.method == kWindowEventOpenMonitorSession) {
      final args = jsonDecode(call.arguments);
      await rustDeskWinManager.openMonitorSession(
        args['window_id'] as int,
        args['peer_id'] as String,
        args['display'] as int,
        args['display_count'] as int,
        parseParamScreenRect(args),
        args['window_type'] as int,
      );
    } else if (call.method == kWindowEventRemoteWindowCoords) {
      final windowId = int.tryParse(call.arguments);
      if (windowId != null) {
        return jsonEncode(
          await rustDeskWinManager.getOtherRemoteWindowCoords(windowId),
        );
      }
    }

    return null;
  }

  Map<String, dynamic> _screenToMap(window_size.Screen screen) => {
        'frame': {
          'l': screen.frame.left,
          't': screen.frame.top,
          'r': screen.frame.right,
          'b': screen.frame.bottom,
        },
        'visibleFrame': {
          'l': screen.visibleFrame.left,
          't': screen.visibleFrame.top,
          'r': screen.visibleFrame.right,
          'b': screen.visibleFrame.bottom,
        },
        'scaleFactor': screen.scaleFactor,
      };

  @override
  void dispose() {
    _uniLinksSubscription?.cancel();
    _identityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<RxBool>(tag: 'stop-service');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      shouldBeBlocked(_block, canBeBlocked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildRemoteBlock(
      block: _block,
      mask: true,
      use: canBeBlocked,
      child: widget.child,
    );
  }
}
