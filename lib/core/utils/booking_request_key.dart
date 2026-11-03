import 'dart:math';

/// A unique, server-compatible key for creating a booking on every platform.
String newBookingRequestKey() {
  final random = Random.secure();
  // JavaScript bit shifts are 32-bit, so `1 << 32` becomes zero on web.
  const randomLimit = 0x100000000;
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${random.nextInt(randomLimit).toRadixString(36).padLeft(7, '0')}'
      '${random.nextInt(randomLimit).toRadixString(36).padLeft(7, '0')}';
}
