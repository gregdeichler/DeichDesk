import 'package:flutter/material.dart';
import 'package:flutter_hbb/deichdesk/pages/deichdesk_launcher_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_home_page.dart';

/// Transitional desktop home integration for Phase 1.
///
/// RustDesk's existing [DesktopHomePage] currently owns important desktop
/// lifecycle/bootstrap behavior (window method handlers, service-status state,
/// uni-link listening, permission polling, and related main-window plumbing).
/// Rather than duplicate or move that logic during the first UI integration,
/// keep the stock page mounted offstage and present DeichDesk as the visible
/// launcher.
///
/// A later cleanup can extract that bootstrap work into a dedicated controller
/// and remove the hidden stock page once Windows/macOS builds confirm the exact
/// lifecycle dependencies.
class DeichDeskDesktopHomePage extends StatelessWidget {
  const DeichDeskDesktopHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        Offstage(
          offstage: true,
          child: DesktopHomePage(),
        ),
        DeichDeskLauncherPage(),
      ],
    );
  }
}
