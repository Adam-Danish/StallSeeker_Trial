import 'package:flutter/material.dart';

class UnsavedStallChangesGuard extends StatefulWidget {
  const UnsavedStallChangesGuard(
      {super.key,
      required this.hasChanges,
      required this.saving,
      required this.onSave,
      required this.child});
  final bool hasChanges;
  final bool saving;
  final Future<void> Function() onSave;
  final Widget child;

  @override
  State<UnsavedStallChangesGuard> createState() =>
      UnsavedStallChangesGuardState();
}

class UnsavedStallChangesGuardState extends State<UnsavedStallChangesGuard> {
  bool _allowPop = false;
  bool _dialogOpen = false;

  void close() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> requestLeave() async {
    if (widget.saving || _dialogOpen) return;
    if (!widget.hasChanges) {
      close();
      return;
    }
    _dialogOpen = true;
    final choice = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Save your changes?'),
                content:
                    const Text('Your stall changes have not been saved yet.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, 'keep'),
                      child: const Text('Keep editing')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, 'discard'),
                      child: const Text('Discard changes')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, 'save'),
                      child: const Text('Save changes')),
                ]));
    _dialogOpen = false;
    if (!mounted) return;
    if (choice == 'save') {
      await widget.onSave();
    } else if (choice == 'discard') {
      close();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _allowPop || (!widget.saving && !widget.hasChanges),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !widget.saving) requestLeave();
        },
        child: widget.child,
      );
}
