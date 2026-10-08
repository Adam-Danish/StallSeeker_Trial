// Firebase SDK references are faked only in tests to verify local storage and
// current-user routing without a Firebase app or network. Server-rule permission
// enforcement is tested separately with the emulator.
// ignore_for_file: subtype_of_sealed_class

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/models/saved_location.dart';
import 'package:stallseeker/core/services/saved_location_service.dart';

Map<String, dynamic> locationMap({bool home = false}) => {
      'name': home ? 'Home' : 'Campus',
      'address': 'Bangi, Selangor',
      'latitude': 2.9213,
      'longitude': 101.7753,
      'isHome': home,
    };

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);
  @override
  User? currentUser;
}

class _User extends Fake implements User {
  _User(this.uid, {this.isAnonymous = false});
  @override
  final String uid;
  @override
  final bool isAnonymous;
}

class _Firestore extends Fake implements FirebaseFirestore {
  final records = <String, Map<String, dynamic>>{};
  final deleted = <String>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.database, this.path);
  final _Firestore database;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(database, '${this.path}/${path ?? 'generated-id'}');

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _Snapshot([
        for (final record in database.records.entries)
          if (record.key.startsWith('$path/') &&
              !record.key.substring(path.length + 1).contains('/'))
            _QueryDocument(record.key.split('/').last, record.value),
      ]);
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.database, this.path);
  final _Firestore database;
  @override
  final String path;
  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(database, '$path/$collectionPath');

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    database.records[path] = Map.of(data);
  }

  @override
  Future<void> delete() async {
    database.records.remove(path);
    database.deleted.add(path);
  }
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _QueryDocument extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDocument(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('saved location validation', () {
    test('round-trips the exact map coordinate and selected place label', () {
      final location = SavedLocation.fromMap('campus', locationMap())!;
      expect(location.coordinates, const LatLng(2.9213, 101.7753));
      expect(location.selection.coordinates, location.coordinates);
      expect(location.selection.label, 'Campus · Bangi, Selangor');
      expect(SavedLocation.fromMap(location.id, location.toMap())!.toMap(),
          location.toMap());
    });

    test('rejects non-numeric, non-finite and out-of-range raw coordinates',
        () {
      for (final entry in <MapEntry<String, Object>>[
        const MapEntry('latitude', '2.9'),
        const MapEntry('longitude', '101.7'),
        const MapEntry('latitude', double.nan),
        const MapEntry('longitude', double.infinity),
        const MapEntry('latitude', 90.01),
        const MapEntry('latitude', -90.01),
        const MapEntry('longitude', 180.01),
        const MapEntry('longitude', -180.01),
      ]) {
        expect(
            SavedLocation.fromMap(
                'campus', {...locationMap(), entry.key: entry.value}),
            isNull);
      }
      expect(
          SavedLocation.fromMap('campus', {
            ...locationMap(),
            'latitude': -90,
            'longitude': -180,
          }),
          isNotNull);
    });

    test('requires bounded name/address strings and a Home-consistent flag',
        () {
      for (final overrides in <Map<String, dynamic>>[
        {'name': '  '},
        {'name': List.filled(61, 'x').join()},
        {'name': 3},
        {'address': ''},
        {'address': List.filled(501, 'x').join()},
        {'address': null},
        {'isHome': 'true'},
        {'isHome': true},
      ]) {
        expect(
            SavedLocation.fromMap('campus', {...locationMap(), ...overrides}),
            isNull);
      }
      expect(SavedLocation.fromMap('home', locationMap()), isNull);
      expect(SavedLocation.fromMap('home', locationMap(home: true))?.isHome,
          isTrue);
      expect(
          SavedLocation.fromMap('home', {
            ...locationMap(home: true),
            'name': 'Office',
          }),
          isNull);
      for (final id in ['', 'folder/campus', '.', '..']) {
        expect(SavedLocation.fromMap(id, locationMap()), isNull);
      }
    });
  });

  group('guest saved places', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('saves locally, replaces Home, edits custom pins and deletes them',
        () async {
      final database = _Firestore();
      final service = SavedLocationService(
          auth: _Auth(_User('guest-1', isAnonymous: true)),
          firestore: database);
      await service.save(
          name: 'Ignored Home name',
          address: 'First address',
          coordinates: const LatLng(3.1, 101.7),
          isHome: true);
      await service.save(
          name: 'Home',
          address: 'Updated home',
          coordinates: const LatLng(3.2, 101.8),
          isHome: true);
      await service.save(
          name: '  Office  ',
          address: '  Office address  ',
          coordinates: const LatLng(3.3, 101.9),
          isHome: false,
          id: 'office');
      var locations = await service.load();
      expect(locations.map((place) => place.id), ['home', 'office']);
      expect(locations.first.name, 'Home');
      expect(locations.first.address, 'Updated home');
      expect(locations.first.coordinates, const LatLng(3.2, 101.8));
      expect(locations.last.name, 'Office');
      expect(locations.last.address, 'Office address');
      await service.save(
          name: 'Campus',
          address: 'Campus address',
          coordinates: const LatLng(2.9, 101.7),
          isHome: false,
          id: 'office');
      locations = await service.load();
      expect(locations, hasLength(2));
      expect(locations.last.name, 'Campus');
      await service.delete('office');
      expect((await service.load()).single.id, 'home');
      expect(database.records, isEmpty);
      expect(database.deleted, isEmpty);
    });

    test('ignores corrupt local entries without losing valid pins', () async {
      SharedPreferences.setMockInitialValues({
        'guest_saved_locations_v1': [
          'invalid JSON',
          jsonEncode({'id': 'broken', 'name': 'Missing coordinates'}),
          jsonEncode({'id': 'campus', ...locationMap()}),
          jsonEncode({'id': 'home', ...locationMap(home: true)}),
          jsonEncode({'id': 'home', ...locationMap(home: true)}),
        ],
      });
      final service =
          SavedLocationService(auth: _Auth(null), firestore: _Firestore());
      final locations = await service.load();
      expect(locations.map((place) => place.id), ['home', 'campus']);
      expect(locations.where((place) => place.isHome), hasLength(1));
    });
  });

  test('cloud load/save/delete use the currently authenticated owner path',
      () async {
    final database = _Firestore();
    final auth = _Auth(_User('alice'));
    final service = SavedLocationService(auth: auth, firestore: database);
    await service.save(
        name: 'Home',
        address: 'Alice home',
        coordinates: const LatLng(3.1, 101.7),
        isHome: true);
    expect(database.records.keys, ['users/alice/savedLocations/home']);
    expect((await service.load()).single.address, 'Alice home');

    auth.currentUser = _User('bob');
    expect(await service.load(), isEmpty);
    await service.save(
        name: 'Campus',
        address: 'Bob campus',
        coordinates: const LatLng(2.9, 101.7),
        isHome: false,
        id: 'campus');
    expect(database.records.keys, contains('users/bob/savedLocations/campus'));
    expect((await service.load()).single.address, 'Bob campus');
    await service.delete('campus');
    expect(database.deleted, ['users/bob/savedLocations/campus']);
    expect(database.records.keys, ['users/alice/savedLocations/home']);
  });
}
