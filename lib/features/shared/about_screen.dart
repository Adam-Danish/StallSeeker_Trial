import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'info_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.65,
              color: Color(0xFF52525A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      title: 'About StallSeeker',
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/app_logo.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
                semanticLabel: 'StallSeeker logo',
              ),
              const SizedBox(height: 16),
              const Text(
                'StallSeeker',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Version 1.0.3 · Prototype',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _section(
          'Why StallSeeker exists',
          'Food stalls do not always operate from one fixed location or '
              'keep the same menu throughout the day. A stall may close early, '
              'move to another spot, or sell out of a dish. StallSeeker helps '
              'customers check vendor-provided details before making the trip.',
        ),
        _section(
          'Finding a stall',
          'Customers can explore stalls on a map, search for dishes, and '
              'filter results by location, category, distance, price, and '
              'opening status. Stall pages show information such as the menu, '
              'availability, reviews, and directions. Customers can also '
              'follow stalls or dishes for updates and request self-collect '
              'bookings where available.',
        ),
        _section(
          'Managing a stall',
          'Vendors can update their stall details, business hours, and '
              'temporary closures. They can add menu items, change prices, '
              'upload images, and mark items as out of stock. When their stall '
              'is open, they can share its current location and manage '
              'booking requests from customers.',
        ),
        _section(
          'Guest and account access',
          'Visitors can browse as guests without creating an account. '
              'Signing in allows the app to keep account-based information, '
              'such as followed stalls and dishes and booking activity, '
              'connected to the same user.',
        ),
        _section(
          'Checking the latest details',
          'Stall information is managed by vendors and can change during '
              'service. Opening status, location, prices, and availability '
              'should be checked again before travelling for a particular '
              'stall or dish.',
        ),
        const Divider(
          height: 1,
          color: Color(0xFFEEEEEE),
        ),
        const SizedBox(height: 20),
        const Text(
          'StallSeeker is a Final Year Project prototype. Its features '
          'and listings are being tested and may change during development.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
