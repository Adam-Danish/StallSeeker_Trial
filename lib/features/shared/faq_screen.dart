import 'package:flutter/material.dart';
import 'account_ui.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, required this.isVendor});
  final bool isVendor;
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqEntry {
  const _FaqEntry(this.group, this.question, this.answer);
  final String group;
  final String question;
  final String answer;
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  static const _customer = [
    _FaqEntry('FINDING STALLS', 'How do I find stalls near me?',
      'Open Discover to see the map. Allow location access to find your area, or move the map yourself. Search by stall name or food category.'),
    _FaqEntry('FINDING STALLS', 'Why can’t I see a stall on the map?',
      'The stall may be closed, outside the area shown, or hidden by a filter. Clear your filters and zoom out. Vendors need to share a valid location.'),
    _FaqEntry('FINDING STALLS', 'Where can I see the menu and stock?',
      'Open a stall’s details to see its menu and available stock. Stock is updated by the vendor, so check with them if you need to be certain.'),
    _FaqEntry('FOLLOWING & UPDATES', 'How do I follow or unfollow a stall?',
      'Sign in and open the stall’s details. Tap the follow or heart button. Your saved stalls appear in Following. Tap the button again to unfollow.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Where are my past notifications?',
      'Open Notifications for saved stall-opening updates. Use All or Unread to filter the list. Older pushes sent before history was enabled are not added automatically.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Why am I not getting alerts?',
      'Check that you follow the stall, are signed in, and have allowed notifications in your phone settings. Alerts are sent when a stall changes from closed to open. Your phone or network may delay delivery.'),
  ];
  static const _vendor = [
    _FaqEntry('YOUR STALL', 'How do I mark my stall as open?',
      'Use the stall status switch on your Dashboard. Allow location access and turn on your phone’s location services so customers can find you.'),
    _FaqEntry('YOUR STALL', 'Why is my stall missing from the map?',
      'Check that your stall is open and its location has updated. Customers may also need to clear filters or move the map to your area.'),
    _FaqEntry('MENU & STOCK', 'How do I update my menu and stock?',
      'Open Manage Menu & Stock from the Dashboard. Edit a dish’s details or change its stock status. Keep this updated when items sell out.'),
    _FaqEntry('MENU & STOCK', 'How do I change my stall photo?',
      'Open Profile, then My stall to edit your stall details and photo. Menu item photos can be changed in Manage Menu & Stock.'),
    _FaqEntry('STALL UPDATES', 'When are followers notified?',
      'An opening update is created when your stall changes from closed to open. Changing a price or moving your location alone does not create an opening alert. Push delivery depends on customer settings and connectivity.'),
  ];
  static const _account = [
    _FaqEntry('ACCOUNT', 'How do I change my name?',
      'Open Profile and tap Edit Profile. Enter your full name and save. Your avatar uses your account photo when available, or the first word of your name.'),
    _FaqEntry('ACCOUNT', 'I forgot my password. What should I do?',
      'Tap Forgot Password on Sign In and enter your account email. Follow the link in the email to set a new password. If you signed up with Google, use Continue with Google.'),
    _FaqEntry('ACCOUNT', 'Why is the reset email missing?',
      'Check the email address and look in Spam or Junk. If you requested the email and recognise the sender, mark it as not spam. Wait for the resend countdown before requesting another link.'),
    _FaqEntry('ACCOUNT', 'Will logging out delete my account?',
      'No. Logging out ends your session on this device. Your account and saved follows stay available when you sign in again.'),
  ];

  @override
  Widget build(BuildContext context) {
    final all = [...(widget.isVendor ? _vendor : _customer), ..._account];
    final entries = all.where((e) => '${e.question} ${e.answer}'.toLowerCase().contains(_query)).toList();
    final groups = entries.map((e) => e.group).toSet();
    return AccountLayout(title: 'Help & FAQ', background: const Color(0xFFF2F2F7), children: [
      const Text('How can we help?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Find quick answers about your account and stalls.',
        style: TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
      const SizedBox(height: 20),
      TextField(controller: _search, onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
        decoration: accountField('Search questions', suffix: _query.isEmpty
          ? const Icon(Icons.search_rounded) : IconButton(tooltip: 'Clear search',
            onPressed: () { _search.clear(); setState(() => _query = ''); },
            icon: const Icon(Icons.close_rounded)))),
      const SizedBox(height: 28),
      if (entries.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 32),
        child: Text('No matching answers. Try a different word.', textAlign: TextAlign.center)),
      for (final group in groups) ...[
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(group,
          style: const TextStyle(fontSize: 12, color: Color(0xFF707078)))),
        _group(entries.where((e) => e.group == group).toList()),
        const SizedBox(height: 26),
      ],
    ]);
  }

  Widget _group(List<_FaqEntry> entries) => Material(color: Colors.white,
    borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias,
    child: Column(children: [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) const Divider(height: .5, thickness: .5, color: Color(0xFFE5E5EA)),
        ExpansionTile(key: PageStorageKey(entries[i].question),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          shape: const Border(), collapsedShape: const Border(),
          backgroundColor: Colors.white, collapsedBackgroundColor: Colors.white,
          iconColor: const Color(0xFFFF6E41), collapsedIconColor: const Color(0xFF8E8E93),
          title: Text(entries[i].question, style: const TextStyle(fontSize: 15,
            fontWeight: FontWeight.w500, color: Color(0xFF222222), height: 1.4)),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Align(alignment: Alignment.centerLeft, child: Text(entries[i].answer,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF707078))))]),
      ],
    ]));
}
