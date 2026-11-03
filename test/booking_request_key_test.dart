import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/utils/booking_request_key.dart';

void main() {
  test('booking request keys can be generated and accepted on web and native',
      () {
    final keys = List.generate(1000, (_) => newBookingRequestKey());
    expect(keys.toSet(), hasLength(keys.length));
    for (final key in keys) {
      expect(key, matches(RegExp(r'^[A-Za-z0-9_-]{12,80}$')));
    }
  });
}
