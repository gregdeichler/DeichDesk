import 'package:flutter/material.dart';
import 'package:flutter_hbb/deichdesk/models/deichdesk_preferences.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';

/// Everyday DeichDesk settings with clear routes into the complete RustDesk
/// settings UI for advanced configuration.
class DeichDeskSettingsDialog extends StatelessWidget {
  const DeichDeskSettingsDialog({
    super.key,
    required this.preferences,
  });

  final DeichDeskPreferences preferences;

  static Future<void> show(
    BuildContext context,
    DeichDeskPreferences preferences,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => DeichDeskSettingsDialog(preferences: preferences),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: preferences,
      builder: (context, _) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_outlined, size: 21),
            SizedBox(width: 8),
            Text('DeichDesk Settings'),
          ],
        ),
        content: SizedBox(
          width: 470,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Launcher', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open Accessible Devices by default'),
                  subtitle: const Text(
                    'Keep the discovered-device section expanded when DeichDesk opens.',
                  ),
                  value: preferences.accessibleDevicesExpanded,
                  onChanged: preferences.setAccessibleDevicesExpanded,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Computer order'),
                  subtitle: const Text(
                    'Drag computers in the All view. Tagged views inherit the same order.',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await preferences.resetPeerOrder();
                      if (context.mounted) {
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          const SnackBar(
                            content: Text('Computer order reset'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const Divider(height: 28),
                Text(
                  'RustDesk Settings',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                _SettingsRoute(
                  icon: Icons.shield_outlined,
                  title: 'Security & unattended access',
                  subtitle: 'Passwords, approval, and incoming access',
                  onTap: () => _openAdvanced(context, SettingsTabKey.safety),
                ),
                _SettingsRoute(
                  icon: Icons.link_outlined,
                  title: 'Network',
                  subtitle: 'ID server, relay, API server, and key',
                  onTap: () => _openAdvanced(context, SettingsTabKey.network),
                ),
                _SettingsRoute(
                  icon: Icons.desktop_windows_outlined,
                  title: 'Display & session defaults',
                  subtitle: 'Display and remote-session behavior',
                  onTap: () => _openAdvanced(context, SettingsTabKey.display),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final first = DesktopSettingPage.tabKeys.isNotEmpty
                          ? DesktopSettingPage.tabKeys.first
                          : SettingsTabKey.about;
                      _openAdvanced(context, first);
                    },
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Advanced RustDesk Settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  static void _openAdvanced(BuildContext context, SettingsTabKey tab) {
    Navigator.of(context).pop();
    DesktopSettingPage.switch2page(tab);
  }
}

class _SettingsRoute extends StatelessWidget {
  const _SettingsRoute({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 21),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
