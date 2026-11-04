import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

const reportReasons = <String, String>{
  'wrong_location': 'Wrong location',
  'opening_status': 'Incorrect opening status or hours',
  'menu_prices': 'Outdated menu, prices, or availability',
  'stall_details': 'Incorrect stall information',
  'other': 'Other inaccurate information',
};

class ModerationRecord {
  const ModerationRecord(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String get status => data['status'] as String? ?? 'pending';
  String get stallName => data['stallName'] as String? ?? 'Stall';
  DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
  bool get active => status == 'warning' || status == 'suspended';
  bool get overdue =>
      status == 'warning' &&
      date('dueAt') != null &&
      DateTime.now().isAfter(date('dueAt')!);
}

String moderationTime(DateTime? value) {
  if (value == null) return '—';
  final time = value.toUtc().add(const Duration(hours: 8));
  String two(int number) => number.toString().padLeft(2, '0');
  return '${time.day}/${time.month}/${time.year} ${two(time.hour)}:${two(time.minute)} MYT';
}

class ModerationService {
  ModerationService(
      {FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  Stream<List<ModerationRecord>> _watch(Query<Map<String, dynamic>> query) =>
      query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => ModerationRecord(doc.id, doc.data()))
          .toList());
  Stream<List<ModerationRecord>> customerReports(String uid) => _watch(_db
      .collection('vendorReports')
      .where('customerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(100));
  Stream<List<ModerationRecord>> vendorCases(String uid) => _watch(_db
      .collection('moderationCases')
      .where('vendorId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(100));
  Future<void> submitReport(
      {required String vendorId,
      required String reason,
      required String details,
      required DateTime observedAt,
      required String requestKey}) async {
    await _functions.httpsCallable('submitVendorReport').call<dynamic>({
      'vendorId': vendorId,
      'reason': reason,
      'details': details,
      'observedAt': observedAt.millisecondsSinceEpoch,
      'requestKey': requestKey,
    });
  }

  Future<void> submitCorrection(
      String caseId, String note, String requestKey) async {
    await _functions.httpsCallable('submitVendorCorrection').call<dynamic>({
      'caseId': caseId,
      'note': note,
      'requestKey': requestKey,
    });
  }
}

String moderationError(Object error) {
  if (error is FirebaseFunctionsException) {
    if (error.code == 'unauthenticated') {
      return 'Sign in with a verified account to continue.';
    }
    if (error.code == 'resource-exhausted' ||
        error.code == 'failed-precondition' ||
        error.code == 'invalid-argument') {
      return error.message ?? 'Please check the information and retry.';
    }
    if (error.code == 'permission-denied') {
      return 'Your account cannot perform this action.';
    }
    if (error.code == 'not-found') {
      return 'This stall or warning is no longer available.';
    }
  }
  return 'Could not save this change. Check your connection and retry.';
}
