import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:provider/provider.dart';

/// DeichDesk wrapper around RustDesk's existing local identity and incoming
/// access model. Authentication, passwords, service installation, and incoming
/// connection security remain owned by RustDesk.
class DeichDeskThisDeviceDialog extends StatelessWidget {
  const DeichDeskThisDeviceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const DeichDeskThisDeviceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(
        builder: (context, model, _) {
          final showOneTime = model.approveMode != 'click' &&
              model.verificationMethod != kUsePermanentPassword;
          final installed = !isWindows || bind.mainIsInstalled();
          final unattendedEnabled = model.approveMode != 'click' &&
              model.verificationMethod != kUseTemporaryPassword;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.computer_outlined, size: 21),
                SizedBox(width: 8),
                Text('This Device'),
              ],
            ),
            content: SizedBox(
              width: 430,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use these details when you want someone to connect to this computer.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    _ValueRow(
                      label: 'ID',
                      value: model.serverId.text,
                      onCopy: () => _copy(context, model.serverId.text),
                    ),
                    const SizedBox(height: 12),
                    _ValueRow(
                      label: 'One-time Password',
                      value: showOneTime ? model.serverPasswd.text : 'Disabled',
                      onCopy: showOneTime
                          ? () => _copy(context, model.serverPasswd.text)
                          : null,
                      trailing: showOneTime
                          ? IconButton(
                              tooltip: 'Refresh password',
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () => bind.mainUpdateTemporaryPassword(),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _AccessStatusCard(
                      installed: installed,
                      unattendedEnabled: unattendedEnabled,
                      model: model,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isWindows
                          ? 'For unattended access, install DeichDesk, set a permanent password, and allow password-based incoming connections. When installed, closing the window leaves the service available from the system tray.'
                          : 'For unattended access, set a permanent password and allow password-based incoming connections. DeichDesk uses the native background service and tray behavior for this platform.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  DesktopSettingPage.switch2page(SettingsTabKey.safety);
                },
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Unattended Access'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _copy(BuildContext context, String value) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
      );
    }
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.onCopy,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value.isEmpty ? '—' : value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (onCopy != null)
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: onCopy,
                ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}

class _AccessStatusCard extends StatelessWidget {
  const _AccessStatusCard({
    required this.installed,
    required this.unattendedEnabled,
    required this.model,
  });

  final bool installed;
  final bool unattendedEnabled;
  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ready = installed && unattendedEnabled;

    String authentication;
    if (model.approveMode == 'click') {
      authentication = 'Manual approval required';
    } else if (model.verificationMethod == kUsePermanentPassword) {
      authentication = 'Permanent password only';
    } else if (model.verificationMethod == kUseBothPasswords) {
      authentication = 'Permanent + one-time passwords';
    } else {
      authentication = 'One-time password only';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ready
            ? scheme.primaryContainer.withOpacity(.45)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withOpacity(.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ready ? Icons.check_circle_outline : Icons.shield_outlined,
                size: 19,
                color: ready ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                ready ? 'Unattended access ready' : 'Unattended access setup',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _StatusLine(
            label: 'Authentication',
            value: authentication,
          ),
          if (isWindows)
            _StatusLine(
              label: 'Background service',
              value: installed ? 'Installed' : 'Install DeichDesk first',
            ),
          const _StatusLine(
            label: 'System tray',
            value: 'Enabled while the background service is running',
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
