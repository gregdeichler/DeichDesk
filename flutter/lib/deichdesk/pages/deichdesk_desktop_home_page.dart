import 'package:flutter/material.dart';
import 'package:flutter_hbb/deichdesk/pages/deichdesk_desktop_bootstrap.dart';
import 'package:flutter_hbb/deichdesk/pages/deichdesk_launcher_page.dart';

/// DeichDesk's normal desktop home composition.
///
/// The visible home page is fully DeichDesk-owned. RustDesk's main-window
/// lifecycle and multi-window plumbing live in [DeichDeskDesktopBootstrap]
/// rather than an offstage stock [DesktopHomePage].
class DeichDeskDesktopHomePage extends StatelessWidget {
  const DeichDeskDesktopHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeichDeskDesktopBootstrap(
      child: DeichDeskLauncherPage(),
    );
  }
}
