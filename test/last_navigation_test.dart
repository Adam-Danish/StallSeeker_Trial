import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/services/last_tab.dart';
import 'package:stallseeker/features/auth/resume_navigation.dart';
import 'package:stallseeker/features/shared/booking_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await loadLastTabs();
  });

  test('restores the last tab for the same account and role', () async {
    await saveLastTab('customer-a', 'customer', 3);
    await saveLastTab('vendor-a', 'vendor', 1);
    await saveLastTab('guest-a', 'customer', 2);
    await loadLastTabs();

    expect(lastTab('customer-a', 'customer', 4), 3);
    expect(lastTab('vendor-a', 'vendor', 2), 1);
    expect(lastTab('guest-a', 'customer', 4), 2);
    expect(lastTab('customer-b', 'customer', 4), 0);
    expect(lastTab('customer-a', 'vendor', 2), 0);
    expect(lastTab('customer-a', 'customer', 2), 0);
  });

  test('reopens a booking by ID with the signed-in role', () async {
    await saveLastPage('vendor-a', 'vendor',
        const ResumePage('booking', 'booking-42').savedValue);
    await loadLastTabs();

    final page = ResumePage.read(lastPage('vendor-a', 'vendor'))!;
    final screen = page.screen('vendor') as BookingDetailScreen;
    expect(screen.bookingId, 'booking-42');
    expect(screen.isVendor, isTrue);
    expect(screen.openCheckoutOnStart, isFalse);
    expect(page.screen('guest'), isNull);
    expect(lastPage('vendor-b', 'vendor'), isNull);
    await saveLastPage('vendor-a', 'vendor', null);
    expect(lastPage('vendor-a', 'vendor'), isNull);
  });

  test('an invalid saved page falls back to the last tab', () {
    expect(ResumePage.read('invalid JSON'), isNull);
    expect(ResumePage.read('["booking",42,null]'), isNull);
    expect(const ResumePage('removed-page').screen('customer'), isNull);
  });
}
