import 'package:flutter/material.dart';
import 'account_ui.dart';

enum LegalPage { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.page});
  final LegalPage page;

  @override
  Widget build(BuildContext context) {
    final privacy = page == LegalPage.privacy;
    return AccountLayout(
      title: privacy ? 'Privacy Policy' : 'Terms of Use',
      background: const Color(0xFFF2F2F7),
      children: [
        Container(padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(privacy ? 'Your privacy at StallSeeker' : 'Using StallSeeker',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -.3)),
            const SizedBox(height: 8),
            const Text('Last updated: 6 September 2026',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
            const SizedBox(height: 24),
            ...(privacy ? _privacySections : _termSections).map((section) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(section.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                Text(section.value, style: const TextStyle(fontSize: 15, height: 1.55,
                  color: Color(0xFF52525A))),
              ]))),
          ])),
      ],
    );
  }

  static const _privacySections = <MapEntry<String, String>>[
    MapEntry('Information we collect', 'We store your name, email address, account type, followed stalls, notification history and device notification token. Vendors may share their stall details and live location while using the service.'),
    MapEntry('How we use it', 'We use this information to run your account, show nearby stalls, save favourites, send stall updates and keep the service secure.'),
    MapEntry('Location', 'Customer location is used to show nearby stalls. Vendor location may be shown to customers when the stall is active. StallSeeker does not need location when these features are not being used.'),
    MapEntry('Sharing and storage', 'Account and app data are stored using Firebase services. We do not sell personal information. Data may be processed by service providers needed to operate the app.'),
    MapEntry('Your choices', 'You can turn off alerts in Notification settings, remove phone permissions in device settings, or delete your StallSeeker account from the Profile page.'),
    MapEntry('Data deletion', 'Deleting your account removes your account and related StallSeeker data. Some security or legal records may be kept only when required by law.'),
    MapEntry('Contact', 'For privacy questions, contact the StallSeeker team at support@stallseeker.my.'),
  ];

  static const _termSections = <MapEntry<String, String>>[
    MapEntry('Service purpose', 'StallSeeker helps customers find food stalls and helps vendors share their status, menu and location.'),
    MapEntry('Account responsibility', 'Use correct information, protect your password and do not use another person’s account. You are responsible for activity under your account.'),
    MapEntry('Vendor information', 'Vendors are responsible for keeping their location, opening status, menu, prices and stock information accurate.'),
    MapEntry('Acceptable use', 'Do not misuse the service, post harmful or false content, interfere with the app, scrape private data or break applicable laws.'),
    MapEntry('Availability', 'Stall locations, stock and opening status can change. StallSeeker cannot guarantee that every listing or live update is always correct or available.'),
    MapEntry('Account action', 'We may limit or remove accounts that abuse the service or put other users at risk. You may delete your account from the Profile page.'),
    MapEntry('Changes and contact', 'These terms may change as the service develops. For questions, contact support@stallseeker.my.'),
  ];
}
