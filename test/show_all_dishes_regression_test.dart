// Read-only Firebase platform fakes exercise the real stall-details widget.
// The interfaces are already installed FlutterFire dependencies; no package is added.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/customer/vendor_details/vendor_details_screen.dart';

class _SignedOutAuth extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues(
          {PigeonUserDetails? currentUser, String? languageCode}) =>
      this;
  @override
  UserPlatform? get currentUser => null;
}

class _ReadOnlyFirestore extends FirebaseFirestorePlatform {
  _ReadOnlyFirestore() {
    menu = StreamController<QuerySnapshotPlatform>.broadcast(
        onListen: () => menuListens++, onCancel: () => menuCancels++);
    reviews = StreamController<QuerySnapshotPlatform>.broadcast(
        onListen: () => reviewListens++, onCancel: () => reviewCancels++);
  }
  late final StreamController<QuerySnapshotPlatform> menu;
  late final StreamController<QuerySnapshotPlatform> reviews;
  int menuListens = 0, menuCancels = 0, reviewListens = 0, reviewCancels = 0;
  @override
  FirebaseFirestorePlatform delegateFor(
          {required FirebaseApp app, required String databaseId}) =>
      this;
  @override
  CollectionReferencePlatform collection(String path) =>
      _ReadOnlyCollection(this, path);
  @override
  DocumentReferencePlatform doc(String path) => _ReadOnlyDocument(this, path);
  QuerySnapshotPlatform snapshot(
          String collectionPath, List<Map<String, Object?>> data) =>
      QuerySnapshotPlatform([
        for (var index = 0; index < data.length; index++)
          DocumentSnapshotPlatform(
              this,
              '$collectionPath/item-$index',
              data[index],
              PigeonSnapshotMetadata(
                  hasPendingWrites: false, isFromCache: true)),
      ], [], SnapshotMetadataPlatform(false, true));
  Future<void> close() async {
    await menu.close();
    await reviews.close();
  }
}

class _ReadOnlyCollection extends CollectionReferencePlatform {
  _ReadOnlyCollection(this.owner, String path) : super(owner, path);
  final _ReadOnlyFirestore owner;
  @override
  DocumentReferencePlatform doc([String? path]) =>
      owner.doc('${this.path}/${path ?? 'generated'}');
  @override
  Stream<QuerySnapshotPlatform> snapshots(
          {bool includeMetadataChanges = false,
          ServerTimestampBehavior serverTimestampBehavior =
              ServerTimestampBehavior.none,
          required ListenSource listenSource}) =>
      path.endsWith('/menu') ? owner.menu.stream : owner.reviews.stream;
}

class _ReadOnlyDocument extends DocumentReferencePlatform {
  _ReadOnlyDocument(super.firestore, super.path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  final firestore = _ReadOnlyFirestore();
  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = _SignedOutAuth();
    FirebaseFirestorePlatform.instance = firestore;
  });
  tearDownAll(firestore.close);
  for (final width in [390.0, 960.0]) {
    testWidgets('Show all dishes keeps the loaded menu and reviews at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });
      firestore.menuListens = 0;
      firestore.menuCancels = 0;
      firestore.reviewListens = 0;
      firestore.reviewCancels = 0;
      final vendor = VendorModel(
          vendorId: 'seller',
          stallName: 'Burger Pak Ali',
          description: 'Fresh burgers',
          category: 'Burger',
          openingHours: '9 AM – 5 PM');
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: VendorDetailsScreen(
              vendor: vendor,
              initialDishId: 'item-0',
              previewOnly: true,
              draftPreview: true)));
      await tester.pump();
      // A live broadcast emits once. No future database update should be needed
      // merely to remove the selected-dish filter and reveal cached dishes.
      firestore.menu.add(firestore.snapshot('vendors/seller/menu', [
        {
          'name': 'Beef burger',
          'price': 8.0,
          'status': 'available',
          'section': 'Burgers'
        },
        {
          'name': 'Chicken burger',
          'price': 7.0,
          'status': 'available',
          'section': 'Burgers'
        },
      ]));
      firestore.reviews.add(firestore.snapshot('stallReviews/seller/entries', [
        {
          'customerName': 'Aina',
          'rating': 4,
          'text': 'Customer feedback remains visible',
          'photoUrls': <String>[]
        },
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Beef burger'), findsOneWidget);
      expect(find.text('Chicken burger'), findsNothing);
      expect(find.text('Customer feedback remains visible'), findsOneWidget);
      expect(firestore.menuListens, 1);
      expect(firestore.reviewListens, 1);
      await tester.ensureVisible(find.text('Show all dishes'));
      await tester.tap(find.text('Show all dishes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Chicken burger'), findsOneWidget,
          reason:
              'Clearing a local filter must reveal already-loaded dishes without another server event.');
      expect(find.text('Beef burger'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Customer feedback remains visible'), findsOneWidget);
      expect(firestore.menuListens, 1);
      expect(firestore.menuCancels, 0);
      expect(firestore.reviewListens, 1);
      expect(firestore.reviewCancels, 0);
      // The preserved subscription must still accept real menu updates.
      firestore.menu.add(firestore.snapshot('vendors/seller/menu', [
        {
          'name': 'Beef burger',
          'price': 8.0,
          'status': 'available',
          'section': 'Burgers'
        },
        {
          'name': 'Chicken burger',
          'price': 7.0,
          'status': 'available',
          'section': 'Burgers'
        },
        {
          'name': 'Fish burger',
          'price': 9.0,
          'status': 'available',
          'section': 'Burgers'
        },
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Fish burger'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
