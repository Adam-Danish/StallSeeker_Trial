import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/last_tab.dart';
import '../../core/services/vendor_service.dart';
import '../../core/widgets/app_page_app_bar.dart';
import '../customer/vendor_details/vendor_details_screen.dart';
import '../shared/about_screen.dart';
import '../shared/booking_detail_screen.dart';
import '../shared/demo_orders_screen.dart';
import '../shared/faq_screen.dart';
import '../shared/legal_screen.dart';
import '../shared/moderation_screen.dart';
import '../shared/notification_settings_screen.dart';
import '../vendor/dashboard/vendor_demo_sales.dart';
import '../vendor/menu/vendor_menu_screen.dart';

class ResumePage extends RouteSettings {
  const ResumePage(this.page, [this.id, this.itemId]);

  final String page;
  final String? id;
  final String? itemId;

  String get savedValue => jsonEncode([page, id, itemId]);

  static ResumePage? read(String? value) {
    if (value == null) return null;
    try {
      final data = jsonDecode(value);
      if (data is List && data.length == 3 && data.first is String) {
        return ResumePage(
            data[0] as String, data[1] as String?, data[2] as String?);
      }
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
    return null;
  }

  Widget? screen(String role) {
    final vendor = role == 'vendor';
    return switch (page) {
      'stall' when !vendor && id != null =>
        _ResumeStall(vendorId: id!, itemId: itemId),
      'bookings' when role != 'guest' => DemoOrdersScreen(isVendor: vendor),
      'booking' when role != 'guest' && id != null =>
        BookingDetailScreen(bookingId: id!, isVendor: vendor),
      'menu' when vendor => const VendorMenuScreen(),
      'stock' when vendor => const VendorMenuScreen(stockOnly: true),
      'payments' when vendor => const VendorPaymentHistoryScreen(),
      'reports' when role != 'guest' =>
        ModerationScreen(isVendor: vendor, initialCaseId: id),
      'faq' => FaqScreen(isVendor: vendor),
      'about' => const AboutScreen(),
      'privacy' => const LegalScreen(page: LegalPage.privacy),
      'terms' => const LegalScreen(page: LegalPage.terms),
      'notification-settings' when role == 'customer' =>
        const NotificationSettingsScreen(),
      _ => null,
    };
  }
}

final resumeNavigation = ResumeNavigation();

class ResumeNavigation extends NavigatorObserver {
  String? _accountId;
  String? _role;
  Route<dynamic>? _restoredRoute;
  (String, String)? _restoredSession;

  void restore(BuildContext context, String accountId, String role) {
    if (_restoredSession == (accountId, role)) return;
    clearSession();
    _restoredSession = (accountId, role);
    _accountId = accountId;
    _role = role;
    if (ModalRoute.isCurrentOf(context) != true ||
        Uri.base.queryParameters.keys.any(
            (key) => const {'vendorId', 'bookingId', 'caseId'}.contains(key))) {
      return;
    }
    final page = ResumePage.read(lastPage(accountId, role));
    final screen = page?.screen(role);
    if (screen == null) return;
    final route =
        MaterialPageRoute<void>(settings: page, builder: (_) => screen);
    _restoredRoute = route;
    Navigator.of(context).push(route);
  }

  void clearSession() {
    _accountId = null;
    _role = null;
    _restoredSession = null;
    final route = _restoredRoute;
    _restoredRoute = null;
    if (route != null && route.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
  }

  void _save(Route<dynamic>? route) {
    final accountId = _accountId;
    final role = _role;
    if (accountId == null ||
        role == null ||
        FirebaseAuth.instance.currentUser?.uid != accountId) {
      return;
    }
    final settings = route?.settings;
    unawaited(saveLastPage(
        accountId, role, settings is ResumePage ? settings.savedValue : null));
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    if (topRoute is PageRoute) _save(topRoute);
  }
}

class _ResumeStall extends StatefulWidget {
  const _ResumeStall({required this.vendorId, this.itemId});

  final String vendorId;
  final String? itemId;

  @override
  State<_ResumeStall> createState() => _ResumeStallState();
}

class _ResumeStallState extends State<_ResumeStall> {
  late final _vendor = VendorService()
      .getVendorProfile(widget.vendorId)
      .timeout(const Duration(seconds: 12));

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _vendor,
        builder: (context, snapshot) {
          final vendor = snapshot.data;
          if (vendor != null) {
            return VendorDetailsScreen(
                vendor: vendor, initialDishId: widget.itemId);
          }
          return Scaffold(
            appBar: AppPageAppBar(title: const Text('Stall details')),
            body: Center(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : const Text('This stall could not be loaded.'),
            ),
          );
        },
      );
}
