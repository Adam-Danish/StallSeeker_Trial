import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  final bool isVendor;

  const FaqScreen({super.key, required this.isVendor});

  static const List<Map<String, String>> _vendorFaqs = [
    {
      'question': 'How do I mark my stall as open?',
      'answer': 'On your Dashboard, flip the "Stall Status" switch to Open. '
          'The app will ask for your location permission the first time '
          '-- this is needed so customers can find you on the map.',
    },
    {
      'question': 'Why is my stall not showing up on the customer map?',
      'answer': 'Make sure your stall is toggled Open, and that you allowed '
          'location permission when prompted. If location services are '
          'off on your phone, the app cannot save your position.',
    },
    {
      'question': 'How do I update my menu prices or stock status?',
      'answer':
          'Go to Dashboard > Manage Menu & Stock. Tap the colored circles '
              'next to a dish to mark it Available, Low Stock, or Out of '
              'Stock -- customers see this update instantly.',
    },
    {
      'question': 'How do I add a photo to my stall or a menu item?',
      'answer': 'Go to Edit Stall Profile to set your stall\'s cover photo, '
          'or Manage Menu & Stock and tap the photo box when adding a dish '
          'to attach a picture to that item.',
    },
    {
      'question': 'Will customers be notified when I open my stall?',
      'answer': 'Yes. Anyone who follows your stall gets a push '
          'notification the moment you switch your status to Open.',
    },
    {
      'question': 'I forgot my password. What do I do?',
      'answer': 'On the login screen, tap "Forgot Password?" and enter your '
          'email. You will receive a link to reset your password.',
    },
  ];

  static const List<Map<String, String>> _customerFaqs = [
    {
      'question': 'How do I find stalls near me?',
      'answer': 'The Home tab shows a map centered on your current '
          'location, with a live list of open stalls sorted by distance. '
          'Use the search bar to filter by name or food category.',
    },
    {
      'question': 'How do I follow a stall?',
      'answer':
          'Open a stall\'s details page (tap its marker on the map or its '
              'card in the nearby list) and tap the heart icon in the top '
              'right corner.',
    },
    {
      'question': 'How will I know when a stall I follow opens?',
      'answer': 'You will get a push notification as soon as a followed '
          'stall switches to Open, and can tap it to jump straight to '
          'that stall\'s page.',
    },
    {
      'question': 'How do I see what a stall is selling?',
      'answer': 'Open the stall\'s details page to see its live menu, '
          'including which items are Available, Low Stock, or Out of '
          'Stock.',
    },
    {
      'question': 'I forgot my password. What do I do?',
      'answer': 'On the login screen, tap "Forgot Password?" and enter your '
          'email. You will receive a link to reset your password.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final faqs = isVendor ? _vendorFaqs : _customerFaqs;

    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['answer']!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
