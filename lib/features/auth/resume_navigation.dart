import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/last_tab.dart';
import '../../core/services/demo_order_service.dart';
import '../../core/services/vendor_service.dart';
import '../../core/utils/stall_share_link.dart';
import '../../core/widgets/app_page_app_bar.dart';
import '../customer/vendor_details/vendor_details_screen.dart';
import '../customer/orders/demo_order_cart_screen.dart';
import '../shared/about_screen.dart';
import '../shared/booking_detail_screen.dart';
import '../shared/booking_receipt_screen.dart';
import '../shared/delete_account_screen.dart';
import '../shared/demo_orders_screen.dart';
import '../shared/faq_screen.dart';
import '../shared/legal_screen.dart';
import '../shared/moderation_screen.dart';
import '../shared/notification_settings_screen.dart';
import '../vendor/dashboard/vendor_demo_sales.dart';
import '../vendor/menu/vendor_menu_screen.dart';
import '../vendor/profile/edit_stall_screen.dart';
import '../vendor/profile/vendor_payout_details_screen.dart';
import '../vendor/reviews/vendor_reviews_screen.dart';

class ResumePage extends RouteSettings {
  const ResumePage(this.page, [this.id, this.itemId]);

  final String page;
  final String? id;
  final String? itemId;

  @override
  String get name => page == 'stall' && id != null
      ? stallPath(id!)
      : id == null
          ? '/$page'
          : '/$page/${Uri.encodeComponent(id!)}';

  static ResumePage? fromWebUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty || segments.length > 2) return null;
    final page = segments.first;
    final id = segments.length == 2 ? segments.last : null;
    if (id != null &&
        (id.trim().isEmpty ||
            id.contains('/') ||
            id.startsWith('__') && id.endsWith('__'))) {
      return null;
    }
    return switch (page) {
      'booking' ||
      'receipt' ||
      'report-stall' ||
      'self-collect' when id != null =>
        ResumePage(page, id),
      'reports' => ResumePage(page, id),
      'bookings' ||
      'menu' ||
      'stock' ||
      'payments' ||
      'payout-details' ||
      'faq' ||
      'about' ||
      'privacy' ||
      'terms' ||
      'notification-settings' ||
      'delete-account' ||
      'edit-stall' ||
      'vendor-reviews' ||
      'stall-preview' ||
      'edit-profile' ||
      'personal-information' ||
      'change-password' when id == null =>
        ResumePage(page),
      _ => null,
    };
  }

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
        _ResumeStall(vendorId: id!, itemId: itemId, page: page),
      'report-stall' ||
      'self-collect' when role == 'customer' && id != null =>
        _ResumeStall(vendorId: id!, page: page),
      'vendor-reviews' || 'stall-preview' when vendor => _ResumeStall(
          vendorId: FirebaseAuth.instance.currentUser!.uid, page: page),
      'bookings' when role != 'guest' => DemoOrdersScreen(isVendor: vendor),
      'booking' when role != 'guest' && id != null =>
        BookingDetailScreen(bookingId: id!, isVendor: vendor),
      'receipt' when role != 'guest' && id != null =>
        _LinkedReceipt(bookingId: id!),
      'menu' when vendor => const VendorMenuScreen(),
      'stock' when vendor => const VendorMenuScreen(stockOnly: true),
      'payments' when vendor => const VendorPaymentHistoryScreen(),
      'payout-details' when vendor => const VendorPayoutDetailsScreen(),
      'edit-stall' when vendor => const EditStallScreen(),
      'delete-account' when role != 'guest' => const DeleteAccountScreen(),
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

  void restore(BuildContext context, String accountId, String role,
      {Uri? initialUri, Widget? accountPage}) {
    if (_restoredSession == (accountId, role)) return;
    clearSession();
    _restoredSession = (accountId, role);
    _accountId = accountId;
    _role = role;
    if (ModalRoute.isCurrentOf(context) != true ||
        (initialUri ?? Uri.base).queryParameters.keys.any(
            (key) => const {'vendorId', 'bookingId', 'caseId'}.contains(key))) {
      return;
    }
    final explicitPath = initialUri != null && initialUri.path != '/';
    final page = explicitPath
        ? ResumePage.fromWebUri(initialUri)
        : ResumePage.read(lastPage(accountId, role));
    final screen = accountPage ?? page?.screen(role);
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
  const _ResumeStall({required this.vendorId, required this.page, this.itemId});

  final String vendorId;
  final String page;
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
          if (vendor != null &&
              (!vendor.isSuspended ||
                  widget.page == 'stall-preview' ||
                  widget.page == 'vendor-reviews')) {
            return switch (widget.page) {
              'self-collect' => DemoOrderCartScreen(vendor: vendor),
              'report-stall' => ReportStallScreen(vendor: vendor),
              'vendor-reviews' => VendorReviewsScreen(
                  vendorId: vendor.vendorId, stallName: vendor.stallName),
              _ => VendorDetailsScreen(
                  vendor: vendor,
                  initialDishId: widget.itemId,
                  previewOnly: widget.page == 'stall-preview'),
            };
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

class _LinkedReceipt extends StatefulWidget {
  const _LinkedReceipt({required this.bookingId});
  final String bookingId;

  @override
  State<_LinkedReceipt> createState() => _LinkedReceiptState();
}

class _LinkedReceiptState extends State<_LinkedReceipt> {
  late final _booking = DemoOrderService().watchBooking(widget.bookingId);

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: _booking,
        builder: (context, snapshot) {
          final booking = snapshot.data;
          if (booking != null) return BookingReceiptScreen(booking: booking);
          return Scaffold(
            appBar: AppPageAppBar(title: const Text('Booking receipt')),
            body: Center(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : const Text('This receipt is unavailable.'),
            ),
          );
        },
      );
}
