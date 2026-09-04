import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';

/// Compact status indicator backed by RustDesk's existing connection-status API.
class DeichDeskServerStatus extends StatefulWidget {
  const DeichDeskServerStatus({super.key});

  @override
  State<DeichDeskServerStatus> createState() => _DeichDeskServerStatusState();
}

class _DeichDeskServerStatusState extends State<DeichDeskServerStatus> {
  Timer? timer;
  _Status status = _Status.connecting;

  @override
  void initState() {
    super.initState();
    _refresh();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final raw = jsonDecode(await bind.mainGetConnectStatus())
          as Map<String, dynamic>;
      final number = raw['status_num'] as int? ?? 0;
      final next = number == 1
          ? _Status.ready
          : number == 0
              ? _Status.connecting
              : _Status.notReady;
      if (mounted && next != status) setState(() => status = next);
    } catch (_) {
      if (mounted && status != _Status.notReady) {
        setState(() => status = _Status.notReady);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      _Status.ready => ('Ready', scheme.primary),
      _Status.connecting => ('Connecting', scheme.tertiary),
      _Status.notReady => ('Not ready', scheme.error),
    };

    return Tooltip(
      message: 'RustDesk server connection status',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

enum _Status { ready, connecting, notReady }
