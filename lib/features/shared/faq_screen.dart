import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<Map<String, String>> _faqs = [
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
      'question': 'How do I follow a stall as a customer?',
      'answer':
          'Open a stall\'s details page (tap its marker on the map or its '
              'card in the nearby list) and tap the heart icon in the top '
              'right corner.',
    },
    {
      'question': 'I forgot my password. What do I do?',
      'answer': 'On the login screen, tap "Forgot Password?" and enter your '
          'email. You will receive a link to reset your password.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
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
