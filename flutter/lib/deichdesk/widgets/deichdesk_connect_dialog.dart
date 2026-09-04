import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';

/// Small DeichDesk entry point into RustDesk's existing connection function.
class DeichDeskConnectDialog extends StatefulWidget {
  const DeichDeskConnectDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const DeichDeskConnectDialog(),
    );
  }

  @override
  State<DeichDeskConnectDialog> createState() => _DeichDeskConnectDialogState();
}

class _DeichDeskConnectDialogState extends State<DeichDeskConnectDialog> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final last = await bind.mainGetLastRemoteId();
      if (!mounted) return;
      controller.text = last;
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
      focusNode.requestFocus();
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  bool get canConnect => controller.text.replaceAll(' ', '').isNotEmpty;

  void _connect() {
    final id = controller.text.replaceAll(' ', '').trim();
    if (id.isEmpty) return;
    Navigator.of(context).pop();
    connect(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect by ID'),
      content: SizedBox(
        width: 380,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: <TextInputFormatter>[IDTextInputFormatter()],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (canConnect) _connect();
          },
          decoration: const InputDecoration(
            labelText: 'Remote ID',
            hintText: 'Enter Remote ID',
            prefixIcon: Icon(Icons.add_link),
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: canConnect ? _connect : null,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Connect'),
        ),
      ],
    );
  }
}
