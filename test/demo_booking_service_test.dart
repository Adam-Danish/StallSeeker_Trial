import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/services/local_demo_booking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('device booking persists through vendor and customer status changes',
      () async {
    final vendorService = LocalDemoBookingService(actorId: 'vendor-1');
    final customerService = LocalDemoBookingService(actorId: 'customer-1');
    final vendor = VendorModel(
      vendorId: 'vendor-1',
      stallName: 'Nasi Stall',
      description: '',
      category: 'Food',
      openingHours: '',
      latitude: 3.1,
      longitude: 101.7,
    );

    expect(await vendorService.isSelfCollectEnabled(vendor.vendorId), false);
    await vendorService.setSelfCollectEnabled(vendor.vendorId, true);
    final id = await customerService.requestOrder(
      vendor,
      const [
        DemoOrderItem(
            itemId: 'dish-1',
            name: 'Nasi Lemak',
            unitPriceCents: 650,
            quantity: 2),
      ],
      customerName: 'Aina',
    );

    var vendorBookings =
        await vendorService.watchVendorOrders('vendor-1').first;
    expect(vendorBookings.single.id, id);
    expect(vendorBookings.single.totalCents, 1300);
    expect(vendorBookings.single.status, 'requested');

    await vendorService.respond(id, accept: true);
    expect(
        (await customerService.watchCustomerOrders('customer-1').first)
            .single
            .status,
        'confirmed');
    await vendorService.advance(id);
    await vendorService.advance(id);
    expect(
        (await customerService.watchCustomerOrders('customer-1').first)
            .single
            .status,
        'ready');
    await vendorService.advance(id);
    vendorBookings = await vendorService.watchVendorOrders('vendor-1').first;
    expect(vendorBookings.single.status, 'collected');

    await customerService.removeAccountData('customer-1');
    expect(await vendorService.watchVendorOrders('vendor-1').first, isEmpty);
  });
}
