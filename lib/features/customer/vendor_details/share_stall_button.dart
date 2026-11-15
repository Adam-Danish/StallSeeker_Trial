import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/stall_share_link.dart';
import '../../../core/widgets/app_sheet_header.dart';

class ShareStallButton extends StatelessWidget {
  const ShareStallButton(
      {super.key, required this.stallId, required this.stallName});

  final String stallId;
  final String stallName;

  Future<void> _showOptions(BuildContext context) {
    final link = stallShareLink(stallId).toString();
    final message = 'Check out $stallName on StallSeeker!\n$link';
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSheetHeader(
                title: const Text('Share stall'),
                subtitle: Text(stallName),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy link'),
                onTap: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (context.mounted) {
                      _showMessage(context, 'Stall link copied.');
                    }
                  } catch (_) {
                    if (sheetContext.mounted) {
                      await showDialog<void>(
                        context: sheetContext,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Copy stall link'),
                          content: SelectableText(link),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: const Text('Share on WhatsApp'),
                onTap: () async {
                  try {
                    final launched = await launchUrl(
                      Uri.https('wa.me', '/', {'text': message}),
                      mode: LaunchMode.externalApplication,
                    );
                    if (launched) return;
                  } catch (_) {
                    // Keep the share options open so the link can be copied.
                  }
                  if (sheetContext.mounted) {
                    _showMessage(sheetContext, 'Could not open WhatsApp.');
                  }
                },
              ),
              Builder(
                builder: (tileContext) => ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: const Text('More sharing options'),
                  onTap: () async {
                    final box = tileContext.findRenderObject() as RenderBox;
                    try {
                      await SharePlus.instance.share(ShareParams(
                        text: message,
                        subject: stallName,
                        sharePositionOrigin:
                            box.localToGlobal(Offset.zero) & box.size,
                        mailToFallbackEnabled: false,
                      ));
                    } catch (_) {
                      if (tileContext.mounted) {
                        _showMessage(tileContext,
                            'Sharing is unavailable here. Use Copy link or WhatsApp.');
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Share stall',
        icon: const Icon(Icons.ios_share),
        onPressed: () => _showOptions(context),
      );
}
