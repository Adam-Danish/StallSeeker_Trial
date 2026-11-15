import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/vendor_payout.dart';

/// Reads and updates vendor payout bank details and payout request records.
class VendorPayoutService {
  VendorPayoutService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const int minPayoutCents = 100;
  static const int maxPayoutCents = 50000000;

  DocumentReference<Map<String, dynamic>> _detailsRef(String vendorId) =>
      _db.collection('vendorPayoutDetails').doc(vendorId);

  CollectionReference<Map<String, dynamic>> get _payoutsRef =>
      _db.collection('vendorPayouts');

  /// Streams saved payout bank details for [vendorId], or `null` if not set.
  Stream<VendorPayoutDetails?> watchPayoutDetails(String vendorId) {
    if (vendorId.trim().isEmpty) return Stream.value(null);
    return _detailsRef(vendorId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return VendorPayoutDetails.fromMap(data, doc.id);
    });
  }

  /// Fetches saved payout bank details once for [vendorId].
  Future<VendorPayoutDetails?> fetchPayoutDetails(String vendorId) async {
    if (vendorId.trim().isEmpty) return null;
    final doc = await _detailsRef(vendorId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return VendorPayoutDetails.fromMap(data, doc.id);
  }

  /// Saves validated payout bank details to `vendorPayoutDetails/{vendorId}`.
  Future<void> savePayoutDetails(VendorPayoutDetails details) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != details.vendorId.trim()) {
      throw StateError('Sign in to your vendor account to save bank details.');
    }
    final bankError = validateBankName(details.bankName);
    if (bankError != null) throw ArgumentError(bankError);
    final holderError = validateAccountHolderName(details.accountHolderName);
    if (holderError != null) throw ArgumentError(holderError);
    final normalizedAccount = normalizeBankAccountNumber(details.accountNumber);
    if (normalizedAccount == null) {
      throw ArgumentError('Enter a valid 6–24 digit bank account number.');
    }

    final payload = {
      ...details.toPayloadMap(),
      'accountNumber': normalizedAccount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _detailsRef(uid).set(payload);
  }

  /// Streams payout request and settlement records owned by [vendorId], newest first.
  Stream<List<VendorPayoutRecord>> watchVendorPayouts(String vendorId) {
    if (vendorId.trim().isEmpty) return Stream.value(const []);
    return _payoutsRef
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs
          .map(VendorPayoutRecord.fromDocument)
          .toList(growable: false);
      records.sort((a, b) {
        final aMs = a.sortTimestamp?.millisecondsSinceEpoch ?? 0;
        final bMs = b.sortTimestamp?.millisecondsSinceEpoch ?? 0;
        return bMs.compareTo(aMs);
      });
      return records;
    });
  }

  /// Creates a `pending` payout request snapshot in `vendorPayouts`.
  Future<String> requestPayout({
    required String vendorId,
    required String stallName,
    required VendorPayoutDetails bankDetails,
    required int amountCents,
    String vendorNote = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != vendorId.trim()) {
      throw StateError('Sign in to your vendor account to request a payout.');
    }
    if (!bankDetails.isComplete) {
      throw ArgumentError('Save complete bank details before requesting a payout.');
    }
    if (amountCents < minPayoutCents || amountCents > maxPayoutCents) {
      throw ArgumentError(
          'Payout request must be between RM 1.00 and RM 500,000.00.');
    }
    final normalizedAccount =
        normalizeBankAccountNumber(bankDetails.accountNumber)!;
    final ref = _payoutsRef.doc();
    final trimmedNote = vendorNote.trim();
    await ref.set({
      'vendorId': uid,
      'stallName': stallName.trim().length > 160
          ? stallName.trim().substring(0, 160)
          : stallName.trim(),
      'amountCents': amountCents,
      'status': 'pending',
      'bankName': bankDetails.bankName.trim(),
      'accountHolderName': bankDetails.accountHolderName.trim(),
      'accountNumber': normalizedAccount,
      'duitNowId': bankDetails.duitNowId.trim(),
      'vendorNote': trimmedNote.length > 240
          ? trimmedNote.substring(0, 240)
          : trimmedNote,
      'requestedBy': uid,
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
