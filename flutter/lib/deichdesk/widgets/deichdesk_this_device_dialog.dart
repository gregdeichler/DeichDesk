import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:provider/provider.dart';

/// Compact DeichDesk wrapper around RustDesk's existing local identity model.
///
/// The ID, temporary password, password regeneration, and authentication state
/// remain owned by RustDesk. This widget is presentation only.
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

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.computer_outlined, size: 21),
                SizedBox(width: 8),
                Text('This Device'),
              ],
            ),
            content: SizedBox(
              width: 390,
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
                  const SizedBox(height: 14),
                  _AuthenticationSummary(model: model),
                ],
              ),
            ),
            actions: [
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

class _AuthenticationSummary extends StatelessWidget {
  const _AuthenticationSummary({required this.model});

  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    String value;
    if (model.approveMode == 'click') {
      value = 'Manual approval required';
    } else if (model.verificationMethod == kUsePermanentPassword) {
      value = 'Permanent password';
    } else {
      value = 'One-time password enabled';
    }

    return Row(
      children: [
        Icon(Icons.shield_outlined,
            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
