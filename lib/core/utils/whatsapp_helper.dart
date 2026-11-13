import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

const String kAdminWhatsAppNumber = '601137932156';
const String kAdminWhatsAppDisplay = '+60 11-3793 2156';
const String kDefaultReportMessage = 'Hi StallSeeker admin, I want to report a problem: ';

/// Opens WhatsApp chat with the StallSeeker admin with a prefilled message.
Future<void> openWhatsAppAdmin(
  BuildContext context, {
  String message = kDefaultReportMessage,
}) async {
  // WhatsApp Universal Link format: https://wa.me/<number>?text=<encoded_text>
  final uri = Uri.https(
    'wa.me',
    '/$kAdminWhatsAppNumber',
    {'text': message},
  );

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Please ensure it is installed.'),
          backgroundColor: AppColors.closedRed,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open WhatsApp: $e'),
          backgroundColor: AppColors.closedRed,
        ),
      );
    }
  }
}

/// A compact clickable WhatsApp contact widget that matches the reference design.
class WhatsAppContactRow extends StatelessWidget {
  const WhatsAppContactRow({
    super.key,
    this.message = kDefaultReportMessage,
    this.fontSize = 15,
  });

  final String message;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openWhatsAppAdmin(context, message: message),
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFF25D366).withValues(alpha: 0.15),
        highlightColor: const Color(0xFF25D366).withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // WhatsApp icon badge
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.call,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.logoRedOrange,
                      height: 1.3,
                    ),
                    children: const [
                      TextSpan(text: 'WhatsApp: '),
                      TextSpan(
                        text: kAdminWhatsAppDisplay,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
