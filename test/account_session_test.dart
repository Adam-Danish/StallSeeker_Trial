import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/services/auth_service.dart';

class _User extends Fake implements User {
  _User({this.failure, this.isAnonymous = false});
  final FirebaseAuthException? failure;
  @override
  final bool isAnonymous;
  int refreshes = 0;
  @override
  Future<void> reload() async {
    if (failure != null) throw failure!;
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    expect(forceRefresh, isTrue);
    refreshes++;
    return 'refreshed-token';
  }
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);
  @override
  User? currentUser;
  int signOuts = 0;
  @override
  Future<void> signOut() async {
    signOuts++;
    currentUser = null;
  }
}

class _Database extends Fake implements FirebaseFirestore {}

// Session invalidation must not depend on optional device cleanup services.
class _Service extends AuthService {
  _Service(this.auth) : super(auth: auth, firestore: _Database());
  final _Auth auth;
  @override
  Future<void> signOut() => auth.signOut();
}

void main() {
  for (final code in [
    'user-not-found',
    'user-disabled',
    'user-token-expired',
    'invalid-user-token'
  ]) {
    test('$code clears a cached signed-in account', () async {
      final auth = _Auth(_User(failure: FirebaseAuthException(code: code)));
      await _Service(auth).validateCurrentSession();
      expect(auth.currentUser, isNull);
      expect(auth.signOuts, 1);
    });
  }

  test('a connection failure can retry without signing out a valid account',
      () async {
    final user =
        _User(failure: FirebaseAuthException(code: 'network-request-failed'));
    final auth = _Auth(user);
    await expectLater(_Service(auth).validateCurrentSession(),
        throwsA(isA<FirebaseAuthException>()));
    expect(auth.currentUser, same(user));
    expect(auth.signOuts, 0);
  });

  test('valid sessions force a fresh token and guest sessions skip validation',
      () async {
    final user = _User();
    await _Service(_Auth(user)).validateCurrentSession();
    expect(user.refreshes, 1);
    final guest = _User(isAnonymous: true);
    await _Service(_Auth(guest)).validateCurrentSession();
    expect(guest.refreshes, 0);
    await _Service(_Auth(null)).validateCurrentSession();
  });
}
