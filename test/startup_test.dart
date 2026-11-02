// ignore_for_file: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/main.dart' as app;

class _UnloadedBrowserFirebase extends FirebasePlatform {
  int attempts = 0;
  @override
  List<FirebaseAppPlatform> get apps =>
      throw StateError('Browser SDK is not loaded yet');
  @override
  Future<FirebaseAppPlatform> initializeApp(
      {String? name, FirebaseOptions? options}) async {
    attempts++;
    throw FirebaseException(plugin: 'core', code: 'network-request-failed');
  }
}

void main() {
  testWidgets(
      'startup initializes before reading apps and retry offers error details',
      (tester) async {
    final previous = Firebase.delegatePackingProperty;
    final firebase = _UnloadedBrowserFirebase();
    Firebase.delegatePackingProperty = firebase;
    addTearDown(() => Firebase.delegatePackingProperty = previous);
    await app.main();
    await tester.pumpAndSettle();
    expect(firebase.attempts, 1);
    expect(find.textContaining('StallSeeker could not start'), findsOneWidget);
    await tester.tap(find.text('Error details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('network-request-failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(firebase.attempts, 2);
  });
}
