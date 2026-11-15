import 'package:cloud_firestore/cloud_firestore.dart';

import 'demo_order.dart';

/// Common Malaysian banks presented when vendors configure payout accounts.
const List<String> malaysianPayoutBanks = [
  'Maybank',
  'CIMB Bank',
  'Public Bank',
  'RHB Bank',
  'Hong Leong Bank',
  'AmBank',
  'Bank Islam',
  'Bank Rakyat',
  'BSN',
  'Alliance Bank',
  'Affin Bank',
  'OCBC Bank',
  'UOB Malaysia',
  'HSBC Malaysia',
  'Standard Chartered',
  'GXBank',
  'Boost Bank',
  'AEON Bank',
  'Other',
];

final RegExp _bankAccountDigitsPattern = RegExp(r'^[0-9]{6,24}$');

/// Normalizes a bank account number by removing spaces and hyphens.
/// Returns `null` if the cleaned number is not 6 to 24 digits.
String? normalizeBankAccountNumber(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[\s\-]+'), '').trim();
  if (!_bankAccountDigitsPattern.hasMatch(cleaned)) return null;
  return cleaned;
}

/// Validates bank name input for payout details.
String? validateBankName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.length < 2) return 'Enter your bank name.';
  if (trimmed.length > 80) return 'Bank name must be 80 characters or fewer.';
  return null;
}

/// Validates account holder name input for payout details.
String? validateAccountHolderName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.length < 2) {
    return 'Enter the bank account holder name.';
  }
  if (trimmed.length > 120) {
    return 'Account holder name must be 120 characters or fewer.';
  }
  return null;
}

/// Validates bank account number input for payout details.
String? validateBankAccountNumber(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return 'Enter your bank account number.';
  if (normalizeBankAccountNumber(raw) == null) {
    return 'Enter a valid 6–24 digit bank account number.';
  }
  return null;
}

/// Formats an account number partially masked for confirmation summaries.
String maskBankAccountNumber(String accountNumber) {
  final normalized = normalizeBankAccountNumber(accountNumber) ?? accountNumber;
  if (normalized.length <= 4) return normalized;
  final tail = normalized.substring(normalized.length - 4);
  return '•••• $tail';
}

/// Formats integer sen/cents into Malaysian Ringgit display text.
String formatRinggit(int cents) => 'RM ${(cents / 100).toStringAsFixed(2)}';

DateTime? _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

int _parseCents(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return 0;
}

/// Private vendor payout bank account saved under `vendorPayoutDetails/{vendorId}`.
class VendorPayoutDetails {
  const VendorPayoutDetails({
    required this.vendorId,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    this.duitNowId = '',
    this.notes = '',
    this.updatedAt,
  });

  final String vendorId;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String duitNowId;
  final String notes;
  final DateTime? updatedAt;

  bool get isComplete =>
      validateBankName(bankName) == null &&
      validateAccountHolderName(accountHolderName) == null &&
      normalizeBankAccountNumber(accountNumber) != null;

  factory VendorPayoutDetails.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return VendorPayoutDetails(
      vendorId: (data['vendorId'] as String?)?.trim().isNotEmpty == true
          ? (data['vendorId'] as String).trim()
          : documentId,
      bankName: (data['bankName'] as String? ?? '').trim(),
      accountHolderName: (data['accountHolderName'] as String? ?? '').trim(),
      accountNumber: (data['accountNumber'] as String? ?? '').trim(),
      duitNowId: (data['duitNowId'] as String? ?? '').trim(),
      notes: (data['notes'] as String? ?? '').trim(),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Serializes user-editable fields for Firestore persistence (without server timestamp).
  Map<String, dynamic> toPayloadMap() => {
        'vendorId': vendorId.trim(),
        'bankName': bankName.trim(),
        'accountHolderName': accountHolderName.trim(),
        'accountNumber': normalizeBankAccountNumber(accountNumber) ??
            accountNumber.trim(),
        'duitNowId': duitNowId.trim(),
        'notes': notes.trim(),
      };
}

/// Auditable payout request or settlement record under `vendorPayouts/{payoutId}`.
class VendorPayoutRecord {
  const VendorPayoutRecord({
    required this.id,
    required this.vendorId,
    required this.stallName,
    required this.amountCents,
    required this.status,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    this.duitNowId = '',
    this.vendorNote = '',
    this.transferReference = '',
    this.adminNote = '',
    this.requestedBy = '',
    this.requestedAt,
    this.settledAt,
    this.updatedAt,
  });

  final String id;
  final String vendorId;
  final String stallName;
  final int amountCents;
  final String status;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String duitNowId;
  final String vendorNote;
  final String transferReference;
  final String adminNote;
  final String requestedBy;
  final DateTime? requestedAt;
  final DateTime? settledAt;
  final DateTime? updatedAt;

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isRejected => status == 'rejected';

  DateTime? get sortTimestamp => settledAt ?? requestedAt ?? updatedAt;

  factory VendorPayoutRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      VendorPayoutRecord.fromMap(doc.data() ?? const {}, doc.id);

  factory VendorPayoutRecord.fromMap(
    Map<String, dynamic> data,
    String id,
  ) {
    return VendorPayoutRecord(
      id: id,
      vendorId: (data['vendorId'] as String? ?? '').trim(),
      stallName: (data['stallName'] as String? ?? '').trim(),
      amountCents: _parseCents(data['amountCents']),
      status: (data['status'] as String? ?? 'pending').trim().toLowerCase(),
      bankName: (data['bankName'] as String? ?? '').trim(),
      accountHolderName: (data['accountHolderName'] as String? ?? '').trim(),
      accountNumber: (data['accountNumber'] as String? ?? '').trim(),
      duitNowId: (data['duitNowId'] as String? ?? '').trim(),
      vendorNote: (data['vendorNote'] as String? ?? '').trim(),
      transferReference: (data['transferReference'] as String? ?? '').trim(),
      adminNote: (data['adminNote'] as String? ?? '').trim(),
      requestedBy: (data['requestedBy'] as String? ?? '').trim(),
      requestedAt: _parseTimestamp(data['requestedAt']),
      settledAt: _parseTimestamp(data['settledAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }
}

/// Computes transferable Live Stripe sales versus paid and pending payouts.
class VendorPayoutBalanceSummary {
  const VendorPayoutBalanceSummary({
    required this.liveNetSalesCents,
    required this.livePaidOrdersCount,
    required this.testNetSalesCents,
    required this.paidOutCents,
    required this.pendingCents,
    required this.unsettledLiveCents,
    required this.availableToRequestCents,
  });

  final int liveNetSalesCents;
  final int livePaidOrdersCount;
  final int testNetSalesCents;
  final int paidOutCents;
  final int pendingCents;
  final int unsettledLiveCents;
  final int availableToRequestCents;

  bool get canRequestPayout => availableToRequestCents >= 100;

  /// Aggregates live/test net order earnings and payout ledger totals for [vendorId].
  factory VendorPayoutBalanceSummary.compute({
    required List<DemoOrder> orders,
    required List<VendorPayoutRecord> payouts,
    required String vendorId,
  }) {
    var liveNet = 0;
    var liveCount = 0;
    var testNet = 0;

    for (final order in orders) {
      if (order.vendorId != vendorId ||
          order.demoSalesCents <= 0 ||
          order.paymentPaidAt == null) {
        continue;
      }
      if (order.paymentMode == 'live') {
        liveNet += order.demoSalesCents;
        liveCount++;
      } else if (order.paymentMode == 'test') {
        testNet += order.demoSalesCents;
      }
    }

    var paidOut = 0;
    var pending = 0;
    for (final payout in payouts) {
      if (payout.vendorId != vendorId || payout.amountCents <= 0) continue;
      if (payout.isPaid) {
        paidOut += payout.amountCents;
      } else if (payout.isPending) {
        pending += payout.amountCents;
      }
    }

    final unsettled = (liveNet - paidOut).clamp(0, liveNet);
    final available = (liveNet - paidOut - pending).clamp(0, liveNet);

    return VendorPayoutBalanceSummary(
      liveNetSalesCents: liveNet,
      livePaidOrdersCount: liveCount,
      testNetSalesCents: testNet,
      paidOutCents: paidOut,
      pendingCents: pending,
      unsettledLiveCents: unsettled,
      availableToRequestCents: available,
    );
  }
}
