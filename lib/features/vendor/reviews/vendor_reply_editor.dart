import 'package:flutter/material.dart';
import '../../../core/models/stall_review.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../../shared/stall_review_card.dart';

class VendorReplyEditor extends StatefulWidget {
  const VendorReplyEditor({
    super.key,
    required this.review,
    required this.stallName,
    required this.onSave,
  });
  final StallReview review;
  final String stallName;
  final Future<void> Function(String text) onSave;
  @override
  State<VendorReplyEditor> createState() => _VendorReplyEditorState();
}

class _VendorReplyEditorState extends State<VendorReplyEditor> {
  late final TextEditingController _text;
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  bool _allowPop = false;
  String? _error;
  String get _original => widget.review.vendorReply?.text ?? '';
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: _original);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving) return;
    if (_text.text != _original) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard this draft?'),
          content: const Text('Your reply has not been saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep writing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_text.text.trim());
      if (!mounted) return;
      setState(() {
        _allowPop = true;
        _saving = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not save your reply. Your draft is still here. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          appBar: AppPageAppBar(
            showBackButton: true,
            backLabel: 'Cancel',
            onBack: _leave,
            backEnabled: !_saving,
            title: Text(widget.review.hasReply ? 'Edit reply' : 'Reply'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Customer review',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      StallReviewCard(
                        review: widget.review,
                        stallName: widget.stallName,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your official reply',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your reply will be visible to everyone under this review.',
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _form,
                        child: TextFormField(
                          controller: _text,
                          enabled: !_saving,
                          minLines: 5,
                          maxLines: 12,
                          maxLength: 1000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Reply',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Write a reply before posting.'
                              : value!.trim().length > 1000
                                  ? 'Use 1,000 characters or fewer.'
                                  : null,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving
                              ? 'Saving…'
                              : _error != null
                                  ? 'Retry'
                                  : widget.review.hasReply
                                      ? 'Save changes'
                                      : 'Post reply',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
