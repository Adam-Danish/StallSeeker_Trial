import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/services/saved_search_service.dart';

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);
  @override
  final User? currentUser;
}

class _User extends Fake implements User {
  _User(this.isAnonymous, this.emailVerified);
  @override
  final bool isAnonymous;
  @override
  final bool emailVerified;
}

class _Database extends Fake implements FirebaseFirestore {}

void main() {
  test(
      'saved searches reject signed-out, guest and unverified users before accessing data',
      () async {
    for (final user in <User?>[null, _User(true, false), _User(false, false)]) {
      final service =
          SavedSearchService(auth: _Auth(user), firestore: _Database());
      await expectLater(service.load(), throwsStateError);
      await expectLater(service.save('My burgers', {}), throwsStateError);
      expect(() => service.remove('search'), throwsStateError);
    }
  });
}
