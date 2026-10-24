This file is a merged representation of a subset of the codebase, containing specifically included files, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: **/*.dart
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
````
lib/
  core/
    constants/
      app_colors.dart
      firestore_collections.dart
      stall_categories.dart
    models/
      demo_order.dart
      dish_follow_model.dart
      dish_search_entry.dart
      menu_item_model.dart
      notification_model.dart
      saved_location.dart
      stall_review.dart
      stall_schedule.dart
      user_model.dart
      vendor_model.dart
    services/
      auth_service.dart
      demo_order_service.dart
      dish_follow_service.dart
      dish_search_service.dart
      follow_service.dart
      local_demo_booking_service.dart
      menu_service.dart
      notification_history_service.dart
      notification_service.dart
      place_search_service.dart
      saved_location_service.dart
      search_history_service.dart
      stall_review_service.dart
      storage_service.dart
      vendor_location_service.dart
      vendor_service.dart
    theme/
      app_theme.dart
    utils/
      vendor_phone.dart
    widgets/
      app_dropdown.dart
      app_pill_navigation.dart
      ios_grouped.dart
  features/
    auth/
      screens/
        change_email_screen.dart
        email_verification_screen.dart
        forgot_password_screen.dart
        login_screen.dart
        register_screen.dart
        welcome_screen.dart
      auth_wrapper.dart
    customer/
      following/
        customer_following_screen.dart
        followed_dishes_list.dart
      home/
        customer_home_screen.dart
        discovery_search_filters.dart
        map_marker_focus.dart
        open_at_picker.dart
        price_range_picker.dart
      notifications/
        customer_notifications_screen.dart
      orders/
        demo_order_cart_screen.dart
      profile/
        customer_profile_screen.dart
      vendor_details/
        vendor_details_screen.dart
    shared/
      about_screen.dart
      account_ui.dart
      booking_detail_screen.dart
      booking_payment_card.dart
      change_password_screen.dart
      delete_account_screen.dart
      demo_orders_screen.dart
      edit_profile_screen.dart
      faq_screen.dart
      info_page.dart
      legal_screen.dart
      live_booking_section.dart
      logout_helper.dart
      manual_location_dialog.dart
      notification_settings_screen.dart
      personal_information_screen.dart
      pin_location_screen.dart
      profile_header.dart
      profile_page.dart
      saved_locations_sheet.dart
    splash/
      splash_screen.dart
    vendor/
      dashboard/
        vendor_dashboard_screen.dart
        vendor_demo_sales.dart
      menu/
        vendor_menu_screen.dart
      profile/
        edit_stall_screen.dart
        stall_schedule_editor.dart
        vendor_profile_screen.dart
      vendor_main_screen.dart
  firebase_options.dart
  main.dart
test/
  app_pill_navigation_test.dart
  booking_card_test.dart
  booking_cart_view_test.dart
  customer_discovery_search_test.dart
  demo_booking_service_test.dart
  demo_orders_screen_test.dart
  discovery_filters_test.dart
  map_marker_focus_test.dart
  payment_ui_test.dart
  profile_page_test.dart
  recent_changes_test.dart
  saved_location_test.dart
````

# Files

## File: lib/core/constants/stall_categories.dart
````dart
const stallCategories = <String>[
  'Goreng Pisang',
  'Burger',
  'Beverages',
  'Snacks & Desserts',
  'Malay Food',
  'Chinese Food',
  'Indian Food',
  'Western',
  'Noodles',
];
````

## File: lib/core/models/dish_follow_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DishFollowModel {
  const DishFollowModel(
      {required this.id,
      required this.vendorId,
      required this.itemId,
      this.followedAt});

  final String id;
  final String vendorId;
  final String itemId;
  final DateTime? followedAt;

  factory DishFollowModel.fromMap(Map<String, dynamic> data, String id) {
    final time = data['followedAt'];
    return DishFollowModel(
      id: id,
      vendorId: data['vendorId'] is String ? data['vendorId'] as String : '',
      itemId: data['itemId'] is String ? data['itemId'] as String : '',
      followedAt: time is Timestamp ? time.toDate() : null,
    );
  }
}
````

## File: lib/core/models/saved_location.dart
````dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/place_search_service.dart';

class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.isHome,
  });

  final String id;
  final String name;
  final String address;
  final LatLng coordinates;
  final bool isHome;

  LocationSelection get selection =>
      LocationSelection(coordinates: coordinates, label: '$name · $address');

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'isHome': isHome,
      };

  static SavedLocation? fromMap(String id, Map<String, dynamic> map) {
    final latitude = map['latitude'];
    final longitude = map['longitude'];
    final name = map['name'];
    final address = map['address'];
    if (id.isEmpty ||
        id == '.' ||
        id == '..' ||
        id.contains('/') ||
        id.length > 128 ||
        latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 60 ||
        address is! String ||
        address.trim().isEmpty ||
        address.length > 500 ||
        map['isHome'] is! bool ||
        (id == 'home') != map['isHome'] ||
        (map['isHome'] == true && name != 'Home')) {
      return null;
    }
    return SavedLocation(
        id: id,
        name: name,
        address: address,
        coordinates: LatLng(latitude.toDouble(), longitude.toDouble()),
        isHome: map['isHome'] as bool);
  }
}
````

## File: lib/core/models/stall_review.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StallReview {
  const StallReview({required this.customerId, required this.customerName,
    required this.rating, required this.text, required this.photoUrls,
    this.updatedAt});

  final String customerId;
  final String customerName;
  final int rating;
  final String text;
  final List<String> photoUrls;
  final DateTime? updatedAt;

  factory StallReview.fromMap(Map<String, dynamic> map, String id) => StallReview(
    customerId: id,
    customerName: map['customerName'] is String ? map['customerName'] as String : 'Customer',
    rating: map['rating'] is int ? (map['rating'] as int).clamp(1, 5) : 1,
    text: map['text'] is String ? map['text'] as String : '',
    photoUrls: map['photoUrls'] is List
        ? (map['photoUrls'] as List).whereType<String>().take(5).toList() : const [],
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );
}
````

## File: lib/core/services/dish_follow_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dish_follow_model.dart';
import '../models/menu_item_model.dart';

/// Each customer's subscriptions live beneath their own user document.
/// The same stall/dish pair always uses the same ID, so following it twice
/// cannot create duplicate alerts.
class DishFollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _subscriptions(String uid) =>
      _db.collection('users').doc(uid).collection('dishFollows');

  String _id(String vendorId, String itemId) {
    for (final value in [vendorId, itemId]) {
      if (value.isEmpty ||
          value.length > 128 ||
          value.contains('/') ||
          value.contains(':')) {
        throw ArgumentError('Invalid stall or dish.');
      }
    }
    return '$vendorId:$itemId';
  }

  void _requireOwner(String uid) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Sign in to follow dishes.');
    }
    if (!user.emailVerified) {
      throw StateError('Verify your email before following dishes.');
    }
  }

  Future<void> _requireCustomer(String uid) async {
    _requireOwner(uid);
    final profile = await _db
        .collection('users')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 10));
    _requireOwner(uid);
    if (profile.data()?['role'] != 'customer') {
      throw StateError('Only customers can follow dishes.');
    }
  }

  Future<void> follow(String uid, String vendorId, String itemId) async {
    final id = _id(vendorId, itemId);
    await _requireCustomer(uid);
    final ref = _subscriptions(uid).doc(id);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      // Preserve the original follow time when a tap is repeated or a second
      // device follows the same dish while this device has stale state.
      if (!existing.exists) {
        transaction.set(ref, {
          'customerId': uid,
          'vendorId': vendorId,
          'itemId': itemId,
          'followedAt': FieldValue.serverTimestamp()
        });
      }
    }).timeout(const Duration(seconds: 10));
  }

  Future<void> unfollow(String uid, String vendorId, String itemId) async {
    await _requireCustomer(uid);
    await _subscriptions(uid)
        .doc(_id(vendorId, itemId))
        .delete()
        .timeout(const Duration(seconds: 10));
  }

  Stream<List<DishFollowModel>> watch(String uid, {String? vendorId}) {
    _requireOwner(uid);
    Query<Map<String, dynamic>> query = _subscriptions(uid);
    if (vendorId != null) query = query.where('vendorId', isEqualTo: vendorId);
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => DishFollowModel.fromMap(doc.data(), doc.id))
        .where((item) => item.vendorId.isNotEmpty && item.itemId.isNotEmpty)
        .toList());
  }

  Stream<MenuItemModel?> watchDish(String vendorId, String itemId) => _db
      .collection('vendors')
      .doc(vendorId)
      .collection('menu')
      .doc(itemId)
      .snapshots()
      .map((doc) =>
          doc.exists ? MenuItemModel.fromMap(doc.data()!, doc.id) : null);
}
````

## File: lib/core/services/follow_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _followsRef => _firestore.collection('follows');

  // Combining customerId + vendorId into one predictable document ID
  // means a customer can never accidentally follow the same vendor
  // twice -- the second "follow" would just overwrite the same document.
  String _followId(String customerId, String vendorId) =>
      '${customerId}_$vendorId';

  Future<void> followVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).set({
      'customerId': customerId,
      'vendorId': vendorId,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).delete();
  }

  // Live stream of whether this customer currently follows this vendor.
  // Used to show the correct Follow/Unfollow button state, and keeps it
  // in sync automatically if changed from another device.
  Stream<bool> isFollowing(String customerId, String vendorId) {
    return _followsRef
        .doc(_followId(customerId, vendorId))
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Live stream of vendor IDs this customer follows -- used by the
  // Following tab to build its list.
  Stream<List<String>> getFollowedVendorIds(String customerId) {
    return _followsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['vendorId'] as String).toList());
  }
}
````

## File: lib/core/services/local_demo_booking_service.dart
````dart
import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/demo_order.dart';
import '../models/vendor_model.dart';

/// Device-only self-collect bookings for the prototype APK.
/// Nothing here sends a booking to another phone or charges a customer.
class LocalDemoBookingService {
  LocalDemoBookingService({String? actorId}) : _testActorId = actorId;

  static const _bookingsKey = 'self_collect_bookings_v1';
  static const _enabledPrefix = 'self_collect_enabled_v1_';
  static final _changed = StreamController<void>.broadcast();

  final String? _testActorId;

  String? get _actorId =>
      _testActorId ?? FirebaseAuth.instance.currentUser?.uid;

  Future<bool> isSelfCollectEnabled(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_enabledPrefix$vendorId') ?? false;
  }

  Future<void> setSelfCollectEnabled(String vendorId, bool enabled) async {
    if (_actorId != vendorId) throw StateError('Vendor account required.');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool('$_enabledPrefix$vendorId', enabled)) {
      throw StateError('Could not save booking preference.');
    }
    _changed.add(null);
  }

  Stream<List<DemoOrder>> watchCustomerOrders(String customerId) =>
      _watch((booking) => booking.customerId == customerId);

  Stream<List<DemoOrder>> watchVendorOrders(String vendorId) =>
      _watch((booking) => booking.vendorId == vendorId);

  Stream<List<DemoOrder>> _watch(bool Function(DemoOrder) include) async* {
    Future<List<DemoOrder>> current() async {
      final bookings = (await _load()).where(include).toList();
      bookings.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return bookings;
    }

    yield await current();
    yield* _changed.stream.asyncMap((_) => current());
  }

  Future<String> requestOrder(VendorModel vendor, List<DemoOrderItem> items,
      {String? customerName}) async {
    final customerId = _actorId;
    if (customerId == null || customerId == vendor.vendorId) {
      throw StateError('Customer account required.');
    }
    if (!await isSelfCollectEnabled(vendor.vendorId)) {
      throw StateError('Self-collect booking is unavailable.');
    }
    if (items.isEmpty || items.any((item) => item.quantity < 1)) {
      throw ArgumentError('Choose at least one dish.');
    }
    final user =
        _testActorId == null ? FirebaseAuth.instance.currentUser : null;
    final name = customerName?.trim().isNotEmpty == true
        ? customerName!.trim()
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : user?.email?.split('@').first ?? 'Customer');
    final now = DateTime.now();
    final booking = DemoOrder(
      id: '${now.microsecondsSinceEpoch}_$customerId',
      customerId: customerId,
      vendorId: vendor.vendorId,
      customerName: name,
      stallName: vendor.stallName,
      status: 'requested',
      items: items,
      totalCents: items.fold(0, (sum, item) => sum + item.subtotalCents),
      createdAt: now,
      pickupLatitude: vendor.hasValidLocation ? vendor.latitude : null,
      pickupLongitude: vendor.hasValidLocation ? vendor.longitude : null,
    );
    final bookings = await _load();
    bookings.insert(0, booking);
    await _save(bookings);
    return booking.id;
  }

  Future<void> removeAccountData(String accountId) async {
    final bookings = await _load();
    await _save(bookings
        .where((booking) =>
            booking.customerId != accountId && booking.vendorId != accountId)
        .toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_enabledPrefix$accountId');
  }

  Future<void> respond(String bookingId, {required bool accept}) =>
      _update(bookingId, (booking) {
        if (_actorId != booking.vendorId ||
            booking.effectiveStatus != 'requested') {
          throw StateError('This booking can no longer be answered.');
        }
        return booking.withStatus(accept ? 'confirmed' : 'rejected');
      });

  Future<void> advance(String bookingId) => _update(bookingId, (booking) {
        if (_actorId != booking.vendorId) {
          throw StateError('Vendor account required.');
        }
        final next = switch (booking.effectiveStatus) {
          'confirmed' => 'preparing',
          'preparing' => 'ready',
          'ready' => 'collected',
          _ => null,
        };
        if (next == null) throw StateError('This booking cannot advance.');
        return booking.withStatus(next);
      });

  Future<void> cancel(String bookingId) => _update(bookingId, (booking) {
        final status = booking.effectiveStatus;
        final customerCanCancel =
            _actorId == booking.customerId && status == 'requested';
        final vendorCanCancel = _actorId == booking.vendorId &&
            {'requested', 'confirmed', 'preparing', 'ready'}.contains(status);
        if (!customerCanCancel && !vendorCanCancel) {
          throw StateError('This booking cannot be cancelled.');
        }
        return booking.withStatus('cancelled');
      });

  Future<void> _update(
      String bookingId, DemoOrder Function(DemoOrder) change) async {
    final bookings = await _load();
    final index = bookings.indexWhere((booking) => booking.id == bookingId);
    if (index < 0) throw StateError('Booking not found on this device.');
    bookings[index] = change(bookings[index]);
    await _save(bookings);
  }

  Future<List<DemoOrder>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bookingsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => DemoOrder.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _save(List<DemoOrder> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_bookingsKey,
        jsonEncode(bookings.map((booking) => booking.toMap()).toList()))) {
      throw StateError('Could not save booking on this device.');
    }
    _changed.add(null);
  }
}
````

## File: lib/core/services/saved_location_service.dart
````dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_location.dart';

class SavedLocationService {
  SavedLocationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  static const _guestKey = 'guest_saved_locations_v1';
  bool get _isGuest =>
      _auth.currentUser == null || _auth.currentUser!.isAnonymous;

  CollectionReference<Map<String, dynamic>> get _locations => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('savedLocations');

  Future<List<SavedLocation>> load() async {
    final List<SavedLocation> locations;
    if (_isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final byId = <String, SavedLocation>{};
      for (final value in prefs.getStringList(_guestKey) ?? <String>[]) {
        try {
          final map = jsonDecode(value) as Map<String, dynamic>;
          final location = SavedLocation.fromMap(map['id'] as String, map);
          if (location != null) byId[location.id] = location;
        } catch (_) {
          // Ignore an invalid legacy pin without hiding other saved places.
        }
      }
      locations = byId.values.toList();
    } else {
      final snapshot =
          await _locations.get().timeout(const Duration(seconds: 12));
      locations = snapshot.docs
          .map((doc) => SavedLocation.fromMap(doc.id, doc.data()))
          .whereType<SavedLocation>()
          .toList();
    }
    locations.sort((a, b) => a.isHome != b.isHome
        ? (a.isHome ? -1 : 1)
        : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return locations;
  }

  Future<void> save(
      {required String name,
      required String address,
      required LatLng coordinates,
      required bool isHome,
      String? id}) async {
    final locationId = isHome ? 'home' : id ?? _db.collection('_ids').doc().id;
    final location = SavedLocation.fromMap(locationId, {
      'name': isHome ? 'Home' : name.trim(),
      'address': address.trim(),
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'isHome': isHome,
    });
    if (location == null) {
      throw ArgumentError('Enter a valid name and map pin.');
    }
    if (_isGuest) {
      final saved = await load();
      saved.removeWhere((pin) => pin.id == location.id);
      saved.add(location);
      await _writeGuest(saved);
    } else {
      await _locations.doc(location.id).set({
        ...location.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 12));
    }
  }

  Future<void> delete(String id) async {
    if (_isGuest) {
      final saved = await load();
      saved.removeWhere((pin) => pin.id == id);
      await _writeGuest(saved);
    } else {
      await _locations.doc(id).delete().timeout(const Duration(seconds: 12));
    }
  }

  Future<void> _writeGuest(List<SavedLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
        _guestKey,
        locations
            .map((location) =>
                jsonEncode({'id': location.id, ...location.toMap()}))
            .toList());
    if (!saved) throw StateError('Could not save the pin on this device.');
  }
}
````

## File: lib/core/services/stall_review_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stall_review.dart';

class StallReviewService {
  final _db = FirebaseFirestore.instance;

  Stream<List<StallReview>> watchReviews(String vendorId) => _db
      .collection('stallReviews').doc(vendorId).collection('entries')
      .snapshots().map((snapshot) {
        final reviews = snapshot.docs
            .map((doc) => StallReview.fromMap(doc.data(), doc.id)).toList();
        reviews.sort((a, b) => (b.updatedAt ?? DateTime(0))
            .compareTo(a.updatedAt ?? DateTime(0)));
        return reviews;
      });

  Future<void> saveReview(String vendorId, String customerId,
      String customerName, int rating, String text, List<String> photoUrls) async {
    if (rating < 1 || rating > 5 || photoUrls.length > 5 || text.length > 1000) {
      throw ArgumentError('Invalid review');
    }
    await _db.collection('stallReviews').doc(vendorId).collection('entries')
        .doc(customerId).set({
      'customerId': customerId,
      'customerName': customerName.trim().isEmpty ? 'Customer' : customerName.trim(),
      'rating': rating,
      'text': text.trim(),
      'photoUrls': photoUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
````

## File: lib/core/utils/vendor_phone.dart
````dart
/// Normalizes Malaysian vendor contact numbers for display and tap-to-call.
/// This checks format only; it does not verify ownership of the number.
String? normalizeVendorPhone(String input) {
  var value = input.replaceAll(RegExp(r'[\s()\-]'), '');
  if (value.startsWith('+60')) {
    value = value.substring(3);
  } else if (value.startsWith('60')) {
    value = value.substring(2);
  } else if (value.startsWith('0')) {
    value = value.substring(1);
  } else {
    return null;
  }
  final mobile = RegExp(r'^1[0-9]{8,9}$');
  final landline = RegExp(r'^[2-9][0-9]{7,8}$');
  return mobile.hasMatch(value) || landline.hasMatch(value)
      ? '+60$value'
      : null;
}
````

## File: lib/core/widgets/ios_grouped.dart
````dart
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 32,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .26),
          gradient: color == AppColors.primary
              ? AppColors.logoGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(Colors.white, color, .78)!,
                    color,
                  ],
                ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * .65,
        ),
      );
}

class AppGroupedCard extends StatelessWidget {
  const AppGroupedCard({
    super.key,
    required this.children,
    this.dividerIndent = 60,
  });

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: .5,
                  thickness: .5,
                  indent: dividerIndent,
                  endIndent: 16,
                  color: AppColors.border,
                ),
              children[i],
            ],
          ],
        ),
      );
}
````

## File: lib/features/auth/screens/forgot_password_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/account_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  bool _sent = false;
  String? _error;
  String _sentTo = '';
  @override
  void dispose() { _timer?.cancel(); _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_busy || _seconds > 0) { return; }
    if (!_sent && !_form.currentState!.validate()) { return; }
    FocusScope.of(context).unfocus();
    final address = _email.text.trim();
    setState(() { _busy = true; _error = null; });
    final error = await AuthService().resetPassword(email: address);
    if (!mounted) { return; }
    setState(() {
      _busy = false; _error = error;
      if (error == null) { _sent = true; _sentTo = address; _seconds = 60; }
    });
    if (error == null) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        setState(() { if (_seconds > 0) { _seconds--; } });
        if (_seconds == 0) { timer.cancel(); }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AccountLayout(title: 'Forgot password', busy: _busy,
    children: [
      const SizedBox(height: 24),
      AccountIntro(icon: _sent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
        title: _sent ? 'Check your email' : 'Reset your password',
        body: _sent
          ? 'If an account uses $_sentTo, you will receive a link to reset its password.'
          : 'Enter the email address linked to your account. We will send you a reset link.'),
      if (!_sent) ...[
        Form(key: _form, child: TextFormField(controller: _email, enabled: !_busy,
          keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email], autocorrect: false,
          decoration: accountField('Email address'),
          validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
            ? null : 'Enter a valid email address.',
          onFieldSubmitted: (_) => _send())),
        const SizedBox(height: 24), AccountError(_error),
        AccountButton(label: _seconds > 0 ? 'Send again in ${_seconds}s' : 'Send reset link',
          busy: _busy, onPressed: _seconds > 0 ? null : _send),
        const SizedBox(height: 20),
        const Text('Signed up with Google? Use Continue with Google to sign in.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF707078), height: 1.5)),
      ] else ...[
        const Text('Open the email and follow the link to choose a new password. Check Spam or Junk if it is missing.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
        const SizedBox(height: 28), AccountError(_error),
        AccountButton(label: 'Done', onPressed: _busy ? null : () => Navigator.pop(context)),
        const SizedBox(height: 12),
        TextButton(onPressed: _busy || _seconds > 0 ? null : _send,
          child: Text(_busy ? 'Sending…' : _seconds > 0 ? 'Resend in ${_seconds}s' : 'Resend email')),
        TextButton(onPressed: _busy ? null : () => setState(() { _sent = false; _error = null; }),
          child: const Text('Use another email')),
      ],
    ]);
}
````

## File: lib/features/customer/home/discovery_search_filters.dart
````dart
import '../../../core/models/dish_search_entry.dart';
import '../../../core/models/vendor_model.dart';

String normalizeDiscoveryQuery(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

class MenuPriceRange {
  const MenuPriceRange({this.minimum, this.maximum});

  final double? minimum;
  final double? maximum;

  bool get isActive => minimum != null || maximum != null;

  bool contains(DishSearchEntry dish) =>
      dish.priceIsKnown &&
      dish.item.price.isFinite &&
      dish.item.price >= 0 &&
      (minimum == null || dish.item.price >= minimum!) &&
      (maximum == null || dish.item.price <= maximum!);

  String get label {
    String amount(double value) => value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    if (minimum != null && maximum != null) {
      return 'RM ${amount(minimum!)}–${amount(maximum!)}';
    }
    if (minimum != null) return 'RM ${amount(minimum!)}+';
    if (maximum != null) return 'Up to RM ${amount(maximum!)}';
    return 'Any price';
  }
}

/// For a dish query, the matching dish itself must meet the price range.
/// Stall/category queries can match any genuinely priced dish on that menu.
bool vendorMatchesQueryAndPrice({
  required VendorModel vendor,
  required Iterable<DishSearchEntry> dishes,
  required String query,
  MenuPriceRange? priceRange,
}) {
  final normalized = normalizeDiscoveryQuery(query);
  final vendorMatches =
      normalizeDiscoveryQuery(vendor.stallName).contains(normalized) ||
          normalizeDiscoveryQuery(vendor.category).contains(normalized);
  final matchingDishes = normalized.isEmpty
      ? dishes
      : dishes.where((dish) =>
          normalizeDiscoveryQuery(dish.item.name).contains(normalized));
  if (priceRange == null || !priceRange.isActive) {
    return normalized.isEmpty || vendorMatches || matchingDishes.isNotEmpty;
  }
  // Do not let a cheap unrelated menu item make an expensive dish match.
  if (matchingDishes.isNotEmpty) {
    return matchingDishes.any(priceRange.contains);
  }
  return vendorMatches && dishes.any(priceRange.contains);
}

enum DiscoverySuggestionKind { dish, stall, category, recent }

class DiscoverySuggestion {
  const DiscoverySuggestion({
    required this.label,
    required this.kind,
    this.isRecent = false,
  });

  final String label;
  final DiscoverySuggestionKind kind;
  final bool isRecent;

  String get detail => switch (kind) {
        DiscoverySuggestionKind.dish => 'Dish',
        DiscoverySuggestionKind.stall => 'Stall',
        DiscoverySuggestionKind.category => 'Category',
        DiscoverySuggestionKind.recent => 'Recent search',
      };
}

List<DiscoverySuggestion> buildDiscoverySuggestions({
  required String query,
  required Iterable<VendorModel> vendors,
  required Iterable<DishSearchEntry> dishes,
  required Iterable<String> categories,
  required List<String> recentSearches,
  MenuPriceRange? priceRange,
  int limit = 8,
}) {
  final typed = normalizeDiscoveryQuery(query);
  final recentKeys = recentSearches.map(normalizeDiscoveryQuery).toSet();
  final suggestions = <String, DiscoverySuggestion>{};

  void add(String rawLabel, DiscoverySuggestionKind kind) {
    final label = rawLabel.trim().replaceAll(RegExp(r'\s+'), ' ');
    final key = normalizeDiscoveryQuery(label);
    if (key.isEmpty || (typed.isNotEmpty && !key.contains(typed))) return;
    final current = suggestions[key];
    if (current == null || kind.index < current.kind.index) {
      suggestions[key] = DiscoverySuggestion(
        label: label,
        kind: kind,
        isRecent: recentKeys.contains(key),
      );
    }
  }

  for (final recent in recentSearches) {
    add(recent, DiscoverySuggestionKind.recent);
  }
  if (typed.isEmpty) return suggestions.values.take(limit).toList();

  final vendorById = {
    for (final vendor in vendors) vendor.vendorId: vendor,
  };
  final eligibleDishes = dishes.where((dish) =>
      vendorById.containsKey(dish.vendorId) &&
      (priceRange == null ||
          !priceRange.isActive ||
          priceRange.contains(dish)));
  final pricedVendorIds = eligibleDishes.map((dish) => dish.vendorId).toSet();
  final eligibleVendors = vendorById.values.where((vendor) =>
      priceRange == null ||
      !priceRange.isActive ||
      pricedVendorIds.contains(vendor.vendorId));

  for (final dish in eligibleDishes) {
    add(dish.item.name, DiscoverySuggestionKind.dish);
  }
  for (final vendor in eligibleVendors) {
    add(vendor.stallName, DiscoverySuggestionKind.stall);
  }
  final offeredCategories = eligibleVendors
      .map((vendor) => normalizeDiscoveryQuery(vendor.category))
      .toSet();
  for (final category in categories) {
    if (offeredCategories.contains(normalizeDiscoveryQuery(category))) {
      add(category, DiscoverySuggestionKind.category);
    }
  }

  int matchRank(String label) {
    final normalized = normalizeDiscoveryQuery(label);
    if (normalized == typed) return 0;
    if (normalized.startsWith(typed)) return 1;
    if (normalized.split(' ').any((word) => word.startsWith(typed))) return 2;
    return 3;
  }

  final ranked = suggestions.values.toList()
    ..sort((a, b) {
      final matchOrder = matchRank(a.label).compareTo(matchRank(b.label));
      if (matchOrder != 0) return matchOrder;
      final sourceOrder = a.kind.index.compareTo(b.kind.index);
      if (sourceOrder != 0) return sourceOrder;
      if (a.kind == DiscoverySuggestionKind.recent) {
        return recentSearches
            .indexWhere((value) =>
                normalizeDiscoveryQuery(value) ==
                normalizeDiscoveryQuery(a.label))
            .compareTo(recentSearches.indexWhere((value) =>
                normalizeDiscoveryQuery(value) ==
                normalizeDiscoveryQuery(b.label)));
      }
      return normalizeDiscoveryQuery(a.label)
          .compareTo(normalizeDiscoveryQuery(b.label));
    });
  return ranked.take(limit).toList();
}
````

## File: lib/features/customer/home/map_marker_focus.dart
````dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/vendor_model.dart';

/// Finds a visible stall close to the center of the map after a user pan.
/// The threshold scales with zoom because it is a fraction of the viewport.
VendorModel? stallNearMapCenter({
  required LatLng center,
  required LatLngBounds bounds,
  required Iterable<VendorModel> vendors,
  double focusFraction = .15,
}) {
  final latitudeSpan = bounds.northeast.latitude - bounds.southwest.latitude;
  final longitudeSpan = bounds.northeast.longitude - bounds.southwest.longitude;
  if (latitudeSpan <= 0 || longitudeSpan <= 0 || focusFraction <= 0) {
    return null;
  }

  VendorModel? nearest;
  var nearestScore = 1.0;
  for (final vendor in vendors) {
    if (!vendor.hasValidLocation) continue;
    final latitudeOffset =
        (vendor.latitude - center.latitude) / (latitudeSpan * focusFraction);
    final longitudeOffset =
        (vendor.longitude - center.longitude) / (longitudeSpan * focusFraction);
    final score =
        latitudeOffset * latitudeOffset + longitudeOffset * longitudeOffset;
    if (score <= nearestScore) {
      nearest = vendor;
      nearestScore = score;
    }
  }
  return nearest;
}
````

## File: lib/features/shared/change_password_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../auth/screens/forgot_password_screen.dart';
import 'account_ui.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.email});
  final String email;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _hidden = [true, true, true];
  bool _busy = false;
  bool _saved = false;
  String? _error;
  @override
  void dispose() { _current.dispose(); _next.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) { return; }
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    // Do not trim passwords: spaces may be intentional.
    final error = await AuthService().changePassword(_next.text, currentPassword: _current.text);
    if (!mounted) { return; }
    setState(() { _busy = false; _error = error; _saved = error == null; });
    if (_saved) { _current.clear(); _next.clear(); _confirm.clear(); }
  }

  Widget _field(String label, TextEditingController controller, int index,
      String? Function(String?) validator) => Padding(padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(controller: controller, enabled: !_busy, obscureText: _hidden[index],
      enableSuggestions: false, autocorrect: false,
      autofillHints: [index == 0 ? AutofillHints.password : AutofillHints.newPassword],
      textInputAction: index == 2 ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: index == 2 ? (_) => _save() : null,
      validator: validator, decoration: accountField(label,
        suffix: IconButton(tooltip: _hidden[index] ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _hidden[index] = !_hidden[index]),
          icon: Icon(_hidden[index] ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 21, color: const Color(0xFF707078))))));

  @override
  Widget build(BuildContext context) => AccountLayout(title: 'Change password', busy: _busy,
    children: _saved ? [
      const SizedBox(height: 40),
      const AccountIntro(icon: Icons.check_rounded, title: 'Password changed',
        body: 'Your new password is ready. Use it the next time you sign in.'),
      AccountButton(label: 'Back to profile', onPressed: () => Navigator.pop(context)),
    ] : [
      const AccountIntro(icon: Icons.lock_outline_rounded, title: 'Choose a new password',
        body: 'Confirm your current password, then enter a new one.'),
      Form(key: _form, child: AutofillGroup(child: Column(children: [
        _field('Current password', _current, 0,
          (v) => (v ?? '').isEmpty ? 'Enter your current password.' : null),
        _field('New password', _next, 1, (v) {
          if ((v ?? '').length < 6) { return 'Use at least 6 characters.'; }
          if (v == _current.text) { return 'Choose a different password.'; }
          return null;
        }),
        _field('Confirm new password', _confirm, 2,
          (v) => v != _next.text ? 'Your passwords do not match.' : null),
      ]))),
      const Padding(padding: EdgeInsets.only(bottom: 20), child: Text(
        'Use a long, unique password. Your account may require extra characters.',
        style: TextStyle(fontSize: 13, color: Color(0xFF707078), height: 1.4))),
      AccountError(_error),
      AccountButton(label: 'Update password', busy: _busy, onPressed: _save),
      const SizedBox(height: 12),
      TextButton(onPressed: _busy ? null : () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: widget.email))),
        child: const Text('Forgot your current password?')),
    ]);
}
````

## File: lib/features/shared/info_page.dart
````dart
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tablet ? 24 : 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720,
                maxHeight: 900,
              ),
              child: SizedBox.expand(
                child: Material(
                  color: Colors.white,
                  elevation: tablet ? 4 : 0,
                  shadowColor: const Color(0x18000000),
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      ),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.textDark,
                          ),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              tablet ? 32 : 20,
                              12,
                              tablet ? 32 : 20,
                              28,
                            ),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: -.3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ...children,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/shared/profile_header.dart
````dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(
      {super.key, required this.name, this.photoUrl, this.size = 100});

  final String name;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: photoUrl == null || photoUrl!.trim().isEmpty
              ? const ColoredBox(
                  color: AppColors.mint,
                  child: Icon(CupertinoIcons.person_fill,
                      size: 58, color: AppColors.primary),
                )
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.mint,
                    child: Icon(CupertinoIcons.person_fill,
                        size: 58, color: AppColors.primary),
                  ),
                ),
        ),
      );
}

class ProfileTopAction extends StatelessWidget {
  const ProfileTopAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x14000000),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: icon == null
                ? Text(label,
                    style: const TextStyle(fontSize: 17, color: Colors.black))
                : Icon(icon, size: 22, color: Colors.black),
          ),
        ),
      );
}
````

## File: lib/features/vendor/dashboard/vendor_demo_sales.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/demo_order.dart';
import '../../../core/services/demo_order_service.dart';
import '../../shared/booking_detail_screen.dart';
import '../../shared/booking_payment_card.dart';

class DemoSalesSummary {
  const DemoSalesSummary(
      {required this.todayCents,
      required this.totalCents,
      required this.paidOrders});
  final int todayCents;
  final int totalCents;
  final int paidOrders;

  factory DemoSalesSummary.fromOrders(List<DemoOrder> orders,
      {required String vendorId, required DateTime now}) {
    DateTime malaysia(DateTime value) =>
        value.toUtc().add(const Duration(hours: 8));
    final today = malaysia(now);
    var daily = 0;
    var total = 0;
    var count = 0;
    for (final order in orders) {
      if (order.vendorId != vendorId ||
          order.demoSalesCents <= 0 ||
          order.paymentPaidAt == null) {
        continue;
      }
      total += order.demoSalesCents;
      count++;
      final paid = malaysia(order.paymentPaidAt!);
      if (paid.year == today.year &&
          paid.month == today.month &&
          paid.day == today.day) {
        daily += order.demoSalesCents;
      }
    }
    return DemoSalesSummary(
        todayCents: daily, totalCents: total, paidOrders: count);
  }
}

class VendorDemoSales extends StatefulWidget {
  const VendorDemoSales({super.key});
  @override
  State<VendorDemoSales> createState() => _VendorDemoSalesState();
}

class _VendorDemoSalesState extends State<VendorDemoSales> {
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final _orders = DemoOrderService().watchVendorOrders(_uid);

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: StreamBuilder<List<DemoOrder>>(
            stream: _orders,
            builder: (context, snapshot) {
              final summary = DemoSalesSummary.fromOrders(snapshot.data ?? [],
                  vendorId: _uid, now: DateTime.now());
              return DemoSalesCard(
                  summary: summary,
                  loading: !snapshot.hasData,
                  hasError: snapshot.hasError,
                  onHistory: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VendorPaymentHistoryScreen())));
            }));
  }
}

class DemoSalesCard extends StatelessWidget {
  const DemoSalesCard(
      {super.key,
      required this.summary,
      required this.onHistory,
      this.loading = false,
      this.hasError = false});
  final DemoSalesSummary summary;
  final VoidCallback onHistory;
  final bool loading;
  final bool hasError;

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.payments_outlined),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Demo sales',
                      style: Theme.of(context).textTheme.titleLarge)),
              const Chip(
                  label: Text('TEST MODE'),
                  visualDensity: VisualDensity.compact),
            ]),
            const SizedBox(height: 12),
            if (hasError)
              const Text('Sales could not load. Check your connection.')
            else if (loading)
              const LinearProgressIndicator()
            else ...[
              const Text('Today · Malaysia time'),
              const SizedBox(height: 4),
              Text('RM ${(summary.todayCents / 100).toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  '${summary.paidOrders} paid orders · RM ${(summary.totalCents / 100).toStringAsFixed(2)} total'),
            ],
            const SizedBox(height: 12),
            const Text(
                'Test payments enabled. Simulated sales only — no bank deposits or payouts.'),
            const SizedBox(height: 8),
            TextButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View payment history')),
          ])));
}

class VendorPaymentHistoryScreen extends StatefulWidget {
  const VendorPaymentHistoryScreen({super.key});
  @override
  State<VendorPaymentHistoryScreen> createState() =>
      _VendorPaymentHistoryScreenState();
}

class _VendorPaymentHistoryScreenState
    extends State<VendorPaymentHistoryScreen> {
  late final _orders = DemoOrderService()
      .watchVendorOrders(FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Demo payment history')),
      body: StreamBuilder<List<DemoOrder>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Payments could not load. Please retry.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snapshot.data!
                .where((order) =>
                    order.hasTestPayment && order.paymentStatus != 'unpaid')
                .toList();
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'Test transactions only. These amounts are not real earnings.'),
              const SizedBox(height: 16),
              if (orders.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'No test payments yet. Paid bookings will appear here.')),
              for (final order in orders)
                Card(
                    child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(order.customerName),
                        subtitle: Text(bookingPaymentLabel(order)),
                        trailing: Text(
                            'RM ${(order.totalCents / 100).toStringAsFixed(2)}'),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(
                                    bookingId: order.id, isVendor: true))))),
            ]);
          }));
}
````

## File: test/booking_card_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/features/shared/booking_detail_screen.dart';

void main() {
  testWidgets(
      'simultaneous bookings show separate progress and open separately',
      (tester) async {
    final opened = <String>[];
    DemoOrder booking(String id, String status, bool unseen) => DemoOrder(
          id: id,
          customerId: 'customer',
          vendorId: 'vendor',
          customerName: 'Customer',
          stallName: 'Stall $id',
          status: status,
          items: const [],
          totalCents: 1200,
          createdAt: DateTime(2026, 10, 8),
          customerUnseenReady: unseen,
        );

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      BookingSummaryCard(
          booking: booking('first', 'preparing', false),
          isVendor: false,
          onTap: () => opened.add('first')),
      BookingSummaryCard(
          booking: booking('second', 'ready', true),
          isVendor: false,
          onTap: () => opened.add('second')),
    ]))));

    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Ready for collection'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    await tester.tap(find.text('Stall second'));
    expect(opened, ['second']);
  });
}
````

## File: test/booking_cart_view_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/customer/orders/demo_order_cart_screen.dart';

void main() {
  for (final width in [320.0, 390.0, 960.0]) {
    testWidgets('booking cart fits ${width.toInt()}px and updates the total',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final item = MenuItemModel(itemId: 'tea', name: 'Air teh', price: 2);
      final quantities = <String, int>{};
      var submitted = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Your order')),
          body: StatefulBuilder(
              builder: (context, setState) => BookingCartView(
                    stallName: 'Adam stalls',
                    items: [item],
                    quantities: quantities,
                    sending: false,
                    onQuantityChanged: (item, quantity) =>
                        setState(() => quantities[item.itemId] = quantity),
                    onSubmit: () => submitted = true,
                  )),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Choose an item'), findsOneWidget);
      expect(find.text('RM 0.00'), findsOneWidget);

      await tester.tap(find.byTooltip('Add Air teh'));
      await tester.pump();
      expect(find.text('RM 2.00'), findsNWidgets(2));
      expect(find.text('Continue to payment'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Continue to payment'));
      expect(submitted, isTrue);
    });
  }

  testWidgets('out-of-stock selection cannot count toward payment',
      (tester) async {
    final item = MenuItemModel(
        itemId: 'tea', name: 'Air teh', price: 2, status: 'out_of_stock');
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: BookingCartView(
          stallName: 'Adam stalls',
          items: [item],
          quantities: const {'tea': 1},
          sending: false,
          onQuantityChanged: (_, __) {},
          onSubmit: () {},
        ),
      ),
    ));
    expect(find.text('RM 0.00'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
        isNull);
  });
}
````

## File: test/customer_discovery_search_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/dish_search_entry.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/discovery_search_filters.dart';
import 'package:stallseeker/features/customer/home/price_range_picker.dart';

VendorModel vendor(String id, String name, {String category = 'Malay Food'}) =>
    VendorModel(
      vendorId: id,
      stallName: name,
      description: '',
      category: category,
      openingHours: '',
      latitude: 3.1,
      longitude: 101.7,
    );

DishSearchEntry dish(String vendorId, String name, double price,
        {bool priceIsKnown = true}) =>
    DishSearchEntry(
      vendorId: vendorId,
      item: MenuItemModel(itemId: name, name: name, price: price),
      priceIsKnown: priceIsKnown,
    );

void main() {
  group('price filtering', () {
    test('includes both boundaries and supports either open end', () {
      const range = MenuPriceRange(minimum: 5, maximum: 10);
      expect(range.contains(dish('a', 'Lower', 5)), isTrue);
      expect(range.contains(dish('a', 'Upper', 10)), isTrue);
      expect(range.contains(dish('a', 'Low', 4.99)), isFalse);
      expect(range.contains(dish('a', 'High', 10.01)), isFalse);
      expect(const MenuPriceRange(minimum: 5).contains(dish('a', 'High', 100)),
          isTrue);
      expect(const MenuPriceRange(maximum: 10).contains(dish('a', 'Low', 0)),
          isTrue);
    });

    test('missing or invalid prices cannot masquerade as free menu items', () {
      const range = MenuPriceRange(minimum: 0, maximum: 0);
      expect(range.contains(dish('a', 'Actual free item', 0)), isTrue);
      expect(
          range.contains(dish('a', 'No saved price', 0, priceIsKnown: false)),
          isFalse);
      expect(range.contains(dish('a', 'Negative', -1)), isFalse);
      expect(range.contains(dish('a', 'Invalid', double.nan)), isFalse);
      expect(range.contains(dish('a', 'Infinite', double.infinity)), isFalse);
    });

    test('a cheap unrelated dish cannot qualify an expensive dish search', () {
      final seller = vendor('a', 'Warung A');
      final menu = [dish('a', 'Nasi lemak', 12), dish('a', 'Teh ais', 3)];
      const range = MenuPriceRange(maximum: 5);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'nasi', priceRange: range),
          isFalse);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'warung', priceRange: range),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'malay', priceRange: range),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'nasi'),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: const [], query: '', priceRange: range),
          isFalse);
    });
  });

  group('live search suggestions', () {
    test('prefix matches outrank contains/history and labels are distinct', () {
      final suggestions = buildDiscoverySuggestions(
        query: '  NASI  ',
        vendors: [vendor('a', 'Nasi Corner')],
        dishes: [
          dish('a', 'Nasi lemak', 5),
          dish('a', '  NASI   lemak  ', 7),
          dish('a', 'Special nasi goreng', 6),
        ],
        categories: const ['Malay Food'],
        recentSearches: const ['My nasi spot', 'nasi lemak'],
      );
      expect(suggestions.map((item) => item.label), [
        'Nasi lemak',
        'Nasi Corner',
        'Special nasi goreng',
        'My nasi spot',
      ]);
      expect(suggestions.first.kind, DiscoverySuggestionKind.dish);
      expect(suggestions.first.isRecent, isTrue);
    });

    test('keeps dish, stall, category and history suggestions within budget',
        () {
      final suggestions = buildDiscoverySuggestions(
        query: 'burger',
        vendors: [vendor('a', 'Burger Corner', category: 'Burger')],
        dishes: [
          dish('a', 'Burger ayam', 5),
          dish('a', 'Burger premium', 20),
          dish('orphan', 'Burger elsewhere', 4),
        ],
        categories: const ['Burger', 'Malay Food'],
        recentSearches: const ['Burger favourite'],
        priceRange: const MenuPriceRange(maximum: 10),
      );
      expect(suggestions.map((item) => item.label), [
        'Burger',
        'Burger ayam',
        'Burger Corner',
        'Burger favourite',
      ]);
      // Exact category matches appear first even before dish prefix matches.
    });

    test('empty input keeps history order and filters duplicates', () {
      final suggestions = buildDiscoverySuggestions(
        query: '',
        vendors: const [],
        dishes: const [],
        categories: const [],
        recentSearches: const ['Nasi lemak', 'burger', ' NASI  LEMAK '],
      );
      expect(suggestions.map((item) => item.label), ['Nasi lemak', 'burger']);
    });
  });

  testWidgets(
      'price picker validates reversed bounds and applies exact amounts',
      (tester) async {
    MenuPriceRange? selected;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              selected = await showPriceRangePicker(context);
            },
            child: const Text('Choose price'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Choose price'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).last, '5');
    await tester.tap(find.text('Apply price range'));
    await tester.pumpAndSettle();
    expect(find.text('Must be at least the minimum'), findsOneWidget);
    expect(selected, isNull);
    await tester.enterText(find.byType(TextFormField).last, '12.50');
    await tester.tap(find.text('Apply price range'));
    await tester.pumpAndSettle();
    expect(selected?.minimum, 10);
    expect(selected?.maximum, 12.5);

    await tester.tap(find.text('Choose price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(selected?.isActive, isFalse);
  });
}
````

## File: test/demo_booking_service_test.dart
````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/services/local_demo_booking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('device booking persists through vendor and customer status changes',
      () async {
    final vendorService = LocalDemoBookingService(actorId: 'vendor-1');
    final customerService = LocalDemoBookingService(actorId: 'customer-1');
    final vendor = VendorModel(
      vendorId: 'vendor-1',
      stallName: 'Nasi Stall',
      description: '',
      category: 'Food',
      openingHours: '',
      latitude: 3.1,
      longitude: 101.7,
    );

    expect(await vendorService.isSelfCollectEnabled(vendor.vendorId), false);
    await vendorService.setSelfCollectEnabled(vendor.vendorId, true);
    final id = await customerService.requestOrder(
      vendor,
      const [
        DemoOrderItem(
            itemId: 'dish-1',
            name: 'Nasi Lemak',
            unitPriceCents: 650,
            quantity: 2),
      ],
      customerName: 'Aina',
    );

    var vendorBookings =
        await vendorService.watchVendorOrders('vendor-1').first;
    expect(vendorBookings.single.id, id);
    expect(vendorBookings.single.totalCents, 1300);
    expect(vendorBookings.single.status, 'requested');

    await vendorService.respond(id, accept: true);
    expect(
        (await customerService.watchCustomerOrders('customer-1').first)
            .single
            .status,
        'confirmed');
    await vendorService.advance(id);
    await vendorService.advance(id);
    expect(
        (await customerService.watchCustomerOrders('customer-1').first)
            .single
            .status,
        'ready');
    await vendorService.advance(id);
    vendorBookings = await vendorService.watchVendorOrders('vendor-1').first;
    expect(vendorBookings.single.status, 'collected');

    await customerService.removeAccountData('customer-1');
    expect(await vendorService.watchVendorOrders('vendor-1').first, isEmpty);
  });
}
````

## File: test/demo_orders_screen_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/features/shared/demo_orders_screen.dart';

void main() {
  testWidgets('customer bookings only show Active and History', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DemoOrdersScreen(
        isVendor: false,
        accountId: 'test-customer',
        liveBookings: Stream.value(<DemoOrder>[]),
      ),
    ));
    expect(find.text('Past demos'), findsNothing);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings in this section yet.'), findsOneWidget);
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings in this section yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
````

## File: test/map_marker_focus_test.dart
````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/map_marker_focus.dart';

void main() {
  final bounds = LatLngBounds(
    southwest: const LatLng(3.10, 101.65),
    northeast: const LatLng(3.18, 101.73),
  );
  final nearby = VendorModel(
    vendorId: 'nearby',
    stallName: 'Nearby stall',
    description: '',
    category: 'Drinks',
    openingHours: '',
    latitude: 3.1405,
    longitude: 101.6865,
  );
  final distant = VendorModel(
    vendorId: 'distant',
    stallName: 'Distant stall',
    description: '',
    category: 'Drinks',
    openingHours: '',
    latitude: 3.16,
    longitude: 101.71,
  );

  test('selects the nearest stall when the map settles over its marker', () {
    final focused = stallNearMapCenter(
      center: const LatLng(3.14, 101.686),
      bounds: bounds,
      vendors: [distant, nearby],
    );
    expect(focused?.vendorId, 'nearby');
  });

  test('does not select a stall away from the map center', () {
    final focused = stallNearMapCenter(
      center: const LatLng(3.14, 101.686),
      bounds: bounds,
      vendors: [distant],
    );
    expect(focused, isNull);
  });
}
````

## File: test/payment_ui_test.dart
````dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/shared/booking_payment_card.dart';
import 'package:stallseeker/features/vendor/dashboard/vendor_demo_sales.dart';

DemoOrder order(
        {String id = 'order',
        String vendorId = 'seller',
        String? mode = 'test',
        String? payment = 'awaiting_payment',
        bool checkoutFirst = false,
        bool vendorUnseenRequest = false,
        int refund = 0,
        DateTime? paidAt}) =>
    DemoOrder(
        id: id,
        customerId: 'buyer',
        vendorId: vendorId,
        customerName: 'Adam',
        stallName: 'Nasi Lemak Kak Ani',
        status: 'confirmed',
        items: const [],
        totalCents: 1250,
        createdAt: DateTime(2026, 10, 20),
        paymentMode: mode,
        checkoutFirst: checkoutFirst,
        vendorUnseenRequest: vendorUnseenRequest,
        paymentStatus: payment,
        paymentRefundedCents: refund,
        paymentExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
        paymentPaidAt: paidAt);

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('PAYMENT_PREVIEW')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(const Key('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('tmp/payment-previews').create(recursive: true);
    await File('tmp/payment-previews/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Widget app(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: RepaintBoundary(
        key: const Key('preview'),
        child: Scaffold(
            appBar: AppBar(
                title: const Text('StallSeeker',
                    style: TextStyle(fontFamily: 'Roboto'))),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16), child: child))));

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('PAYMENT_PREVIEW')) return;
    const fontRoot = String.fromEnvironment('PREVIEW_FONT_ROOT');
    final bytes = await File('$fontRoot/roboto-regular.ttf').readAsBytes();
    for (final family in ['Roboto', 'Ahem']) {
      final font = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await font.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test(
      'legacy records remain payable outside the app and test payment metadata survives round trips',
      () {
    final legacy = order(mode: null, payment: null);
    expect(legacy.canPrepare, isTrue);
    expect(legacy.hasTestPayment, isFalse);
    final paid = order(payment: 'paid', paidAt: DateTime.utc(2026, 10, 20));
    final decoded = DemoOrder.fromMap(paid.toMap()).withStatus('preparing');
    expect(decoded.paymentStatus, 'paid');
    expect(decoded.paymentPaidAt, paid.paymentPaidAt);
    expect(decoded.paymentMode, 'test');
    expect(order(checkoutFirst: true).toMap()['checkoutFirst'], isTrue);
    expect(DemoOrder.fromMap(order(checkoutFirst: true).toMap()).checkoutFirst,
        isTrue);
    expect(order().canPrepare, isFalse);
    expect(paid.canPrepare, isTrue);
  });

  test('customer may cancel a paid test booking until it is collected', () {
    final paid = order(payment: 'paid');
    for (final status in ['confirmed', 'preparing', 'ready']) {
      expect(paid.withStatus(status).canCustomerCancel, isTrue);
    }
    expect(paid.withStatus('collected').canCustomerCancel, isFalse);
    expect(order(mode: null).canCustomerCancel, isFalse);
    expect(bookingStatusLabel(order(checkoutFirst: true)), 'Awaiting payment');
    expect(bookingStatusLabel(order(checkoutFirst: true, payment: 'paid')),
        'Paid · awaiting preparation');
    expect(
        order(checkoutFirst: true, payment: 'paid', vendorUnseenRequest: true)
            .vendorNeedsAttention,
        isTrue);
    expect(
        order(
                checkoutFirst: true,
                payment: 'pending',
                vendorUnseenRequest: true)
            .vendorNeedsAttention,
        isFalse);
  });

  test(
      'demo sales exclude other stalls, old bookings, unpaid and refunded orders',
      () {
    final now =
        DateTime.utc(2026, 10, 19, 17); // 1am on 20 October in Malaysia.
    final result = DemoSalesSummary.fromOrders([
      order(payment: 'paid', paidAt: now),
      order(payment: 'paid', paidAt: now, refund: 250),
      order(payment: 'paid', paidAt: DateTime.utc(2026, 10, 19, 15)),
      order(vendorId: 'other', payment: 'paid', paidAt: now),
      order(mode: null, payment: 'paid', paidAt: now),
      order(payment: 'refunded', paidAt: now),
      order(payment: 'refund_pending', paidAt: now),
      order(payment: 'pending', paidAt: now),
    ], vendorId: 'seller', now: now);
    expect(result.todayCents, 2250);
    expect(result.totalCents, 3500);
    expect(result.paidOrders, 3);
  });

  testWidgets(
      'customer can pay only eligible bookings and sees test disclosure',
      (tester) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = 0;
    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(),
        isVendor: false,
        onPay: () => tapped++,
        onRefresh: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Pay RM 12.50'), findsOneWidget);
    expect(find.textContaining('No real money'), findsOneWidget);
    await tester.tap(find.text('Pay RM 12.50'));
    expect(tapped, 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, 'customer-payment');

    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(payment: 'paid'),
        isVendor: false,
        onPay: () => tapped++)));
    expect(find.text('Pay RM 12.50'), findsNothing);
    expect(find.text('Paid · Test'), findsOneWidget);
  });

  testWidgets('vendor and busy payment cards cannot launch checkout',
      (tester) async {
    await tester
        .pumpWidget(app(BookingPaymentCard(booking: order(), isVendor: true)));
    expect(find.text('Pay RM 12.50'), findsNothing);
    expect(find.textContaining('Preparation unlocks'), findsOneWidget);
    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(),
        isVendor: false,
        busy: true,
        onPay: () => fail('Must not start another payment'))));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets('sales card is labelled as a simulation and fits narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(DemoSalesCard(
        summary: const DemoSalesSummary(
            todayCents: 8500, totalCents: 12500, paidOrders: 8),
        onHistory: () {})));
    await tester.pumpAndSettle();
    expect(find.text('RM 85.00'), findsOneWidget);
    expect(find.textContaining('no bank deposits'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await preview(tester, 'vendor-sales');
  });
}
````

## File: test/profile_page_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/features/shared/profile_page.dart';

ProfilePage page({
  bool guest = false,
  String name = 'Adam Danish',
  String email = 'adam@example.com',
  VoidCallback? onHome,
  VoidCallback? onCustom,
  VoidCallback? onSignIn,
}) {
  void noop() {}
  return ProfilePage(
    name: name,
    email: email,
    isVendor: false,
    isGuest: guest,
    canChangePassword: true,
    location: 'Johor Bahru, Johor',
    isLoadingLocation: false,
    onRefresh: () async {},
    onLocation: noop,
    onEdit: noop,
    onPassword: noop,
    onFaq: noop,
    onAbout: noop,
    onLogout: noop,
    onSignIn: onSignIn ?? noop,
    onNotificationSettings: noop,
    onPrivacyPolicy: noop,
    onTerms: noop,
    onDeleteAccount: noop,
    onHomeLocation: onHome,
    onCustomLocation: onCustom,
  );
}

void main() {
  testWidgets(
      'saved pin rows invoke their actions and remain available to guests',
      (tester) async {
    var homes = 0;
    var customs = 0;
    var signIns = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: page(
          guest: true,
          name: 'Guest',
          email: '',
          onHome: () => homes++,
          onCustom: () => customs++,
          onSignIn: () => signIns++,
        ),
      ),
    ));

    await tester.tap(find.text('Home location'));
    await tester.tap(find.text('Custom pins'));
    await tester.tap(find.text('Sign in'));
    expect(homes, 1);
    expect(customs, 1);
    expect(signIns, 1);
    expect(find.text('Change password'), findsNothing);
    expect(find.text('Delete account'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long account details wrap on small screens with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.5),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: page(
          name: 'Adam Danish bin Muhammad Abdullah',
          email: 'adam.danish.muhammad.abdullah@example.com',
          onHome: () {},
          onCustom: () {},
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Logout'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Logout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
````

## File: test/recent_changes_test.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/utils/vendor_phone.dart';
import 'package:stallseeker/features/vendor/profile/stall_schedule_editor.dart';

void main() {
  group('vendor phone', () {
    test('normalizes common Malaysian mobile and landline formats', () {
      expect(normalizeVendorPhone('012-345 6789'), '+60123456789');
      expect(normalizeVendorPhone('+60 12 345 6789'), '+60123456789');
      expect(normalizeVendorPhone('03-1234 5678'), '+60312345678');
    });

    test('rejects blank, foreign and implausible numbers', () {
      expect(normalizeVendorPhone(''), isNull);
      expect(normalizeVendorPhone('+44 20 1234 5678'), isNull);
      expect(normalizeVendorPhone('01234'), isNull);
    });
  });

  group('structured hours and closures', () {
    test('round-trips weekday intervals and rejects invalid ranges', () {
      final hours = <int, List<StallHoursInterval>>{
        1: [const StallHoursInterval(9 * 60, 12 * 60),
            const StallHoursInterval(13 * 60, 17 * 60)],
        6: [const StallHoursInterval(20 * 60, 2 * 60)],
      };
      final parsed = parseWeeklyHours(serializeWeeklyHours(hours));
      expect(parsed[1]!.map((range) => range.openMinute), [540, 780]);
      expect(parsed[6]!.single.closeMinute, 120);
      expect(StallHoursInterval.fromMap({'open': 540, 'close': 540}), isNull);
      expect(StallHoursInterval.fromMap({'open': -1, 'close': 600}), isNull);
    });

    test('closure start is inclusive and end is exclusive', () {
      final start = DateTime.utc(2026, 9, 18, 2);
      final end = start.add(const Duration(hours: 3));
      final closure = TemporaryClosure(start, end);
      final parsed = TemporaryClosure.fromMap(closure.toMap())!;
      expect(parsed.contains(start), isTrue);
      expect(parsed.contains(end.subtract(const Duration(milliseconds: 1))),
          isTrue);
      expect(parsed.contains(end), isFalse);
      expect(TemporaryClosure.fromMap({
        'startAt': Timestamp.fromDate(end),
        'endAt': Timestamp.fromDate(start),
      }), isNull);
    });

    test('active closure hides an otherwise open stall', () {
      final now = DateTime.now();
      final vendor = VendorModel(
        vendorId: 'vendor-a', stallName: 'Test', description: '',
        category: 'Malay Food', openingHours: '', isOpen: true,
        temporaryClosures: [TemporaryClosure(
          now.subtract(const Duration(minutes: 1)),
          now.add(const Duration(minutes: 1)))],
      );
      expect(vendor.isTemporarilyClosed, isTrue);
      expect(vendor.isOpenNow, isFalse);
      expect(vendor.copyWith(temporaryClosures: []).isOpenNow, isTrue);
    });
  });

  test('old dishes get a section, and stock time comes from Firestore', () {
    final legacy = MenuItemModel.fromMap(
      {'name': 'Nasi lemak', 'price': 5.5, 'status': 'available'}, 'dish-1');
    expect(legacy.section, 'Main menu');
    expect(legacy.statusUpdatedAt, isNull);

    final updated = DateTime.utc(2026, 9, 18, 3);
    final current = MenuItemModel.fromMap({
      'name': 'Teh ais', 'price': 2,
      'section': 'Drinks', 'status': 'low_stock',
      'statusUpdatedAt': Timestamp.fromDate(updated),
    }, 'dish-2');
    expect(current.section, 'Drinks');
    expect(current.statusUpdatedAt!.toUtc(), updated);
  });

  testWidgets('vendor can toggle a day and add a second time period',
      (tester) async {
    var hours = <int, List<StallHoursInterval>>{};
    final closures = <TemporaryClosure>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        child: StallScheduleEditor(hours: hours, closures: closures,
          onChanged: (nextHours, _) => setState(() => hours = nextHours))),
    ))));

    await tester.tap(find.text('Monday').first);
    await tester.pump();
    expect(hours[1], hasLength(1));
    expect(hours[1]!.single.openMinute, 540);

    await tester.tap(find.text('Add time').first);
    await tester.pump();
    expect(hours[1], hasLength(2));

    await tester.tap(find.byTooltip('Remove time').first);
    await tester.pump();
    expect(hours[1], hasLength(1));
  });
}
````

## File: test/saved_location_test.dart
````dart
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
````

## File: lib/core/constants/firestore_collections.dart
````dart
class FirestoreCollections {
  static const String users = 'users';
  static const String vendors = 'vendors';
  static const String menus = 'menus';
  static const String follows = 'follows';
}
````

## File: lib/core/models/demo_order.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoOrderItem {
  const DemoOrderItem(
      {required this.itemId,
      required this.name,
      required this.unitPriceCents,
      required this.quantity});

  final String itemId;
  final String name;
  final int unitPriceCents;
  final int quantity;

  int get subtotalCents => unitPriceCents * quantity;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'name': name,
        'unitPriceCents': unitPriceCents,
        'quantity': quantity,
      };

  factory DemoOrderItem.fromMap(Map<String, dynamic> data) => DemoOrderItem(
        itemId: data['itemId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        unitPriceCents: (data['unitPriceCents'] as num?)?.toInt() ?? 0,
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      );
}

class DemoOrder {
  const DemoOrder(
      {required this.id,
      required this.customerId,
      required this.vendorId,
      required this.customerName,
      required this.stallName,
      required this.status,
      required this.items,
      required this.totalCents,
      required this.createdAt,
      this.expiresAt,
      this.pickupLatitude,
      this.pickupLongitude,
      this.paymentMode,
      this.checkoutFirst = false,
      this.paymentStatus,
      this.paymentReference,
      this.paymentExpiresAt,
      this.paymentPaidAt,
      this.paymentRefundedCents = 0,
      this.vendorUnseenRequest = false,
      this.customerUnseenReady = false});

  final String id;
  final String customerId;
  final String vendorId;
  final String customerName;
  final String stallName;
  final String status;
  final List<DemoOrderItem> items;
  final int totalCents;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? paymentMode;
  final bool checkoutFirst;
  final String? paymentStatus;
  final String? paymentReference;
  final DateTime? paymentExpiresAt;
  final DateTime? paymentPaidAt;
  final int paymentRefundedCents;

  bool get hasTestPayment => paymentMode == 'test';
  bool get awaitingPayment =>
      hasTestPayment &&
      status == 'confirmed' &&
      {'awaiting_payment', 'pending', 'failed'}.contains(paymentStatus);
  bool get canPay =>
      awaitingPayment &&
      paymentExpiresAt != null &&
      DateTime.now().isBefore(paymentExpiresAt!);
  bool get canPrepare =>
      status == 'confirmed' && (!hasTestPayment || paymentStatus == 'paid');
  bool get canCustomerCancel =>
      effectiveStatus == 'requested' ||
      (hasTestPayment &&
          {'confirmed', 'preparing', 'ready'}.contains(effectiveStatus));
  bool get vendorNeedsAttention =>
      vendorUnseenRequest &&
      (effectiveStatus == 'requested' ||
          (checkoutFirst && paymentStatus == 'paid'));
  int get demoSalesCents => hasTestPayment && paymentStatus == 'paid'
      ? (totalCents - paymentRefundedCents).clamp(0, totalCents)
      : 0;
  final bool vendorUnseenRequest;
  final bool customerUnseenReady;

  String get effectiveStatus {
    if (status == 'requested' &&
        expiresAt != null &&
        DateTime.now().isAfter(expiresAt!)) {
      return 'expired';
    }
    return status;
  }

  bool get isActive => !{'collected', 'rejected', 'cancelled', 'expired'}
      .contains(effectiveStatus);

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'vendorId': vendorId,
        'customerName': customerName,
        'stallName': stallName,
        'status': status,
        'items': items.map((item) => item.toMap()).toList(),
        'totalCents': totalCents,
        'createdAt': createdAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'paymentMode': paymentMode,
        'checkoutFirst': checkoutFirst,
        'paymentStatus': paymentStatus,
        'paymentReference': paymentReference,
        'paymentExpiresAt': paymentExpiresAt?.toIso8601String(),
        'paymentPaidAt': paymentPaidAt?.toIso8601String(),
        'paymentRefundedCents': paymentRefundedCents,
        'vendorUnseenRequest': vendorUnseenRequest,
        'customerUnseenReady': customerUnseenReady,
      };

  DemoOrder withStatus(String nextStatus) => DemoOrder(
        id: id,
        customerId: customerId,
        vendorId: vendorId,
        customerName: customerName,
        stallName: stallName,
        status: nextStatus,
        items: items,
        totalCents: totalCents,
        createdAt: createdAt,
        expiresAt: nextStatus == 'requested' ? expiresAt : null,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        paymentMode: paymentMode,
        checkoutFirst: checkoutFirst,
        paymentStatus: paymentStatus,
        paymentReference: paymentReference,
        paymentExpiresAt: paymentExpiresAt,
        paymentPaidAt: paymentPaidAt,
        paymentRefundedCents: paymentRefundedCents,
        vendorUnseenRequest: vendorUnseenRequest,
        customerUnseenReady: customerUnseenReady,
      );

  factory DemoOrder.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return DemoOrder(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      vendorId: data['vendorId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      stallName: data['stallName'] as String? ?? 'Stall',
      status: data['status'] as String? ?? 'requested',
      items: rawItems
          .whereType<Map>()
          .map((item) => DemoOrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      pickupLatitude: (data['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickupLongitude'] as num?)?.toDouble(),
      paymentMode: data['paymentMode'] as String?,
      checkoutFirst: data['checkoutFirst'] == true,
      paymentStatus: data['paymentStatus'] as String?,
      paymentReference: data['paymentReference'] as String?,
      paymentExpiresAt: (data['paymentExpiresAt'] as Timestamp?)?.toDate(),
      paymentPaidAt: (data['paymentPaidAt'] as Timestamp?)?.toDate(),
      paymentRefundedCents:
          (data['paymentRefundedCents'] as num?)?.toInt() ?? 0,
      vendorUnseenRequest: data['vendorUnseenRequest'] == true,
      customerUnseenReady: data['customerUnseenReady'] == true,
    );
  }

  factory DemoOrder.fromMap(Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return DemoOrder(
      id: data['id'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      vendorId: data['vendorId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      stallName: data['stallName'] as String? ?? 'Stall',
      status: data['status'] as String? ?? 'requested',
      items: rawItems
          .whereType<Map>()
          .map((item) => DemoOrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
      pickupLatitude: (data['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickupLongitude'] as num?)?.toDouble(),
      paymentMode: data['paymentMode'] as String?,
      checkoutFirst: data['checkoutFirst'] == true,
      paymentStatus: data['paymentStatus'] as String?,
      paymentReference: data['paymentReference'] as String?,
      paymentExpiresAt:
          DateTime.tryParse(data['paymentExpiresAt'] as String? ?? ''),
      paymentPaidAt: DateTime.tryParse(data['paymentPaidAt'] as String? ?? ''),
      paymentRefundedCents:
          (data['paymentRefundedCents'] as num?)?.toInt() ?? 0,
      vendorUnseenRequest: data['vendorUnseenRequest'] == true,
      customerUnseenReady: data['customerUnseenReady'] == true,
    );
  }
}

String demoOrderStatusLabel(String status) => switch (status) {
      'requested' => 'Booking requested',
      'confirmed' => 'Booking confirmed',
      'preparing' => 'Preparing',
      'ready' => 'Ready for collection',
      'collected' => 'Collected',
      'rejected' => 'Rejected',
      'cancelled' => 'Cancelled',
      'expired' => 'Expired',
      _ => status,
    };

String bookingStatusLabel(DemoOrder booking) {
  if (booking.checkoutFirst && booking.status == 'confirmed') {
    return booking.paymentStatus == 'paid'
        ? 'Paid · awaiting preparation'
        : 'Awaiting payment';
  }
  return demoOrderStatusLabel(booking.effectiveStatus);
}
````

## File: lib/core/models/dish_search_entry.dart
````dart
import 'menu_item_model.dart';

class DishSearchEntry {
  const DishSearchEntry({
    required this.vendorId,
    required this.item,
    this.priceIsKnown = true,
  });

  final String vendorId;
  final MenuItemModel item;
  // Older menu records may not contain a price. Their model fallback of zero
  // must not make them appear as free dishes in a price filter.
  final bool priceIsKnown;
}
````

## File: lib/core/models/stall_schedule.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Calendar fields in Malaysia, independent of the phone's time zone.
DateTime malaysiaTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 8));

DateTime malaysiaInstant(int year, int month, int day, int hour, int minute) =>
    DateTime.utc(year, month, day, hour, minute)
        .subtract(const Duration(hours: 8));

/// True when any scheduled serving time remains in this window after closures.
bool hasScheduledOpening(DateTime start, DateTime end,
    Map<int, List<StallHoursInterval>> hours, List<TemporaryClosure> closures) {
  if (!end.isAfter(start) || hours.isEmpty) return false;
  final first = malaysiaTime(start);
  final last = malaysiaTime(end);
  var day = DateTime.utc(first.year, first.month, first.day)
      .subtract(const Duration(days: 1));
  final lastDay = DateTime.utc(last.year, last.month, last.day);
  while (!day.isAfter(lastDay)) {
    final midnight = malaysiaInstant(day.year, day.month, day.day, 0, 0);
    for (final interval in hours[day.weekday] ?? <StallHoursInterval>[]) {
      var open = midnight.add(Duration(minutes: interval.openMinute));
      var close = midnight.add(Duration(
          minutes: interval.closeMinute +
              (interval.closeMinute < interval.openMinute ? 1440 : 0)));
      if (open.isBefore(start)) open = start;
      if (close.isAfter(end)) close = end;
      if (!close.isAfter(open)) continue;
      var available = <TemporaryClosure>[TemporaryClosure(open, close)];
      for (final closure in closures) {
        final remaining = <TemporaryClosure>[];
        for (final segment in available) {
          if (!closure.end.isAfter(segment.start) ||
              !closure.start.isBefore(segment.end)) {
            remaining.add(segment);
          } else {
            if (closure.start.isAfter(segment.start)) {
              remaining.add(TemporaryClosure(segment.start, closure.start));
            }
            if (closure.end.isBefore(segment.end)) {
              remaining.add(TemporaryClosure(closure.end, segment.end));
            }
          }
        }
        available = remaining;
      }
      if (available.isNotEmpty) return true;
    }
    day = day.add(const Duration(days: 1));
  }
  return false;
}

bool isWithinStallSchedule(DateTime instant,
    Map<int, List<StallHoursInterval>> hours, List<TemporaryClosure> closures) {
  if (hours.isEmpty || closures.any((closure) => closure.contains(instant))) {
    return false;
  }
  final local = malaysiaTime(instant);
  final minute = local.hour * 60 + local.minute;
  for (final interval in hours[local.weekday] ?? <StallHoursInterval>[]) {
    if (interval.closeMinute > interval.openMinute) {
      if (minute >= interval.openMinute && minute < interval.closeMinute) {
        return true;
      }
    } else if (minute >= interval.openMinute) {
      return true;
    }
  }
  final previousDay = local.weekday == 1 ? 7 : local.weekday - 1;
  return (hours[previousDay] ?? <StallHoursInterval>[]).any((interval) =>
      interval.closeMinute < interval.openMinute &&
      minute < interval.closeMinute);
}

/// Weekly hours use Monday=1 through Sunday=7 and minutes after midnight.
class StallHoursInterval {
  const StallHoursInterval(this.openMinute, this.closeMinute);
  final int openMinute;
  final int closeMinute;

  Map<String, int> toMap() => {'open': openMinute, 'close': closeMinute};

  static StallHoursInterval? fromMap(Object? value) {
    if (value is! Map) return null;
    final open = value['open'];
    final close = value['close'];
    if (open is! int ||
        close is! int ||
        open < 0 ||
        open >= 1440 ||
        close < 0 ||
        close >= 1440 ||
        open == close) {
      return null;
    }
    return StallHoursInterval(open, close);
  }
}

class TemporaryClosure {
  const TemporaryClosure(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
  Map<String, Timestamp> toMap() => {
        'startAt': Timestamp.fromDate(start.toUtc()),
        'endAt': Timestamp.fromDate(end.toUtc()),
      };

  static TemporaryClosure? fromMap(Object? value) {
    if (value is! Map) return null;
    final start = value['startAt'];
    final end = value['endAt'];
    if (start is! Timestamp || end is! Timestamp) return null;
    final result = TemporaryClosure(start.toDate(), end.toDate());
    return result.end.isAfter(result.start) ? result : null;
  }
}

Map<int, List<StallHoursInterval>> parseWeeklyHours(Object? value) {
  if (value is! Map) return {};
  final result = <int, List<StallHoursInterval>>{};
  for (var day = 1; day <= 7; day++) {
    final raw = value['$day'];
    if (raw is List) {
      result[day] = raw
          .map(StallHoursInterval.fromMap)
          .whereType<StallHoursInterval>()
          .toList();
    }
  }
  return result;
}

Map<String, List<Map<String, int>>> serializeWeeklyHours(
        Map<int, List<StallHoursInterval>> hours) =>
    {
      for (var day = 1; day <= 7; day++)
        '$day': (hours[day] ?? []).map((interval) => interval.toMap()).toList(),
    };

String formatStallTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}
````

## File: lib/core/services/demo_order_service.dart
````dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/demo_order.dart';
import '../models/vendor_model.dart';

/// Live self-collect bookings shared between customer and vendor accounts.
/// The old same-phone demo is read separately by LocalDemoBookingService.
class DemoOrderService {
  DemoOrderService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<DemoOrder>> watchCustomerOrders(String customerId) => _watch(_db
      .collection('bookings')
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true));

  Stream<List<DemoOrder>> watchVendorOrders(String vendorId) => _watch(_db
          .collection('bookings')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true))
      .map((orders) => orders
          .where((order) => !order.checkoutFirst || order.paymentPaidAt != null)
          .toList());

  Stream<List<DemoOrder>> _watch(Query<Map<String, dynamic>> query) => query
      .snapshots()
      .map((snapshot) => snapshot.docs.map(DemoOrder.fromDocument).toList());

  Stream<DemoOrder?> watchBooking(String bookingId) => _db
      .collection('bookings')
      .doc(bookingId)
      .snapshots()
      .map((doc) => doc.exists ? DemoOrder.fromDocument(doc) : null);

  Stream<int> watchUnseenCount(String uid, {required bool isVendor}) =>
      (isVendor ? watchVendorOrders(uid) : watchCustomerOrders(uid)).map(
          (orders) => orders
              .where((booking) => isVendor
                  ? booking.vendorNeedsAttention
                  : booking.customerUnseenReady)
              .length);

  Future<String> requestOrder(
      VendorModel vendor, List<DemoOrderItem> items) async {
    final random = Random.secure();
    final key = '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0')}'
        '${random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0')}';
    final result = await _functions.httpsCallable('createBooking').call({
      'vendorId': vendor.vendorId,
      'requestKey': key,
      'items': [
        for (final item in items)
          {'itemId': item.itemId, 'quantity': item.quantity}
      ],
    });
    return (result.data as Map)['bookingId'] as String;
  }

  Future<void> respond(String bookingId, {required bool accept}) =>
      _action(bookingId, accept ? 'accept' : 'reject');

  Future<void> advance(String bookingId, String status) => _action(
        bookingId,
        switch (status) {
          'confirmed' => 'startPreparing',
          'preparing' => 'markReady',
          'ready' => 'markCollected',
          _ => throw StateError('Booking cannot advance.'),
        },
      );

  Future<void> cancel(String bookingId) => _action(bookingId, 'cancel');

  Future<Uri> createTestCheckout(String bookingId) async {
    final result = await _functions
        .httpsCallable('createStripeCheckout',
            options:
                HttpsCallableOptions(timeout: const Duration(seconds: 120)))
        .call({'bookingId': bookingId});
    final uri = Uri.parse((result.data as Map)['checkoutUrl'] as String);
    if (uri.scheme != 'https' || uri.host != 'checkout.stripe.com') {
      throw StateError('Invalid checkout URL.');
    }
    return uri;
  }

  Future<void> refreshPayment(String bookingId) async {
    await _functions
        .httpsCallable('refreshStripePayment',
            options:
                HttpsCallableOptions(timeout: const Duration(seconds: 120)))
        .call({'bookingId': bookingId});
  }

  Future<void> markViewed(String bookingId) async {
    await _functions.httpsCallable('markBookingViewed').call({
      'bookingId': bookingId,
    });
  }

  Future<void> _action(String bookingId, String action) async {
    await _functions.httpsCallable('updateBooking').call({
      'bookingId': bookingId,
      'action': action,
    });
  }
}
````

## File: lib/core/services/dish_search_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dish_search_entry.dart';
import '../models/menu_item_model.dart';

class DishSearchService {
  DishSearchService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<DishSearchEntry>> watchAllDishes() {
    return _db.collectionGroup('menu').snapshots().map((snapshot) {
      final dishes = <DishSearchEntry>[];
      for (final document in snapshot.docs) {
        final vendorId = document.reference.parent.parent?.id;
        if (vendorId == null || vendorId.isEmpty) continue;
        final data = document.data();
        final price = data['price'];
        dishes.add(DishSearchEntry(
          vendorId: vendorId,
          item: MenuItemModel.fromMap(
              {...data, 'price': price is num ? price : 0}, document.id),
          priceIsKnown: price is num && price.isFinite && price >= 0,
        ));
      }
      dishes.sort((a, b) =>
          a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase()));
      return dishes;
    });
  }
}
````

## File: lib/core/services/notification_history_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

/// The server creates history records. Clients can read their own records
/// and mark them read, but cannot invent or edit alert content.
class NotificationHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<NotificationModel>> watch(String uid,
          {int limit = 50}) =>
      _inbox(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList());

  // Cap the badge query; the UI displays 99+ rather than a misleading exact count.
  Stream<int> watchUnreadCount(String uid) => _inbox(uid)
      .where('isRead', isEqualTo: false)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  Future<void> markRead(String uid, String notificationId) async {
    _requireOwner(uid);
    await _inbox(uid)
        .doc(notificationId)
        .update({'isRead': true}).timeout(const Duration(seconds: 10));
  }

  Future<void> remove(String uid, String notificationId) async {
    _requireOwner(uid);
    await _inbox(uid)
        .doc(notificationId)
        .delete()
        .timeout(const Duration(seconds: 10));
  }

  /// Marks only the records the screen displayed. A new alert arriving during
  /// this operation remains unread, and writes stay below the batch limit.
  Future<void> markDisplayedRead(
      String uid, Iterable<NotificationModel> items) async {
    _requireOwner(uid);
    final ids = items
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toSet()
        .toList();
    for (var start = 0; start < ids.length; start += 400) {
      _requireOwner(uid);
      final batch = _db.batch();
      for (final id in ids.skip(start).take(400)) {
        batch.update(_inbox(uid).doc(id), {'isRead': true});
      }
      await batch.commit().timeout(const Duration(seconds: 10));
    }
  }

  void _requireOwner(String uid) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Sign in to read your notifications.');
    }
  }
}
````

## File: lib/core/services/search_history_service.dart
````dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  SearchHistoryService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  static const _guestKey = 'guest_search_history_v1';
  static const _limit = 10;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  bool get _usesLocalHistory {
    final user = _auth.currentUser;
    return user == null || user.isAnonymous;
  }

  Future<List<String>> loadRecent() async {
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      return (preferences.getStringList(_guestKey) ?? const <String>[])
          .take(_limit)
          .toList();
    }

    final uid = _auth.currentUser!.uid;
    final snapshot = await _history(uid)
        .orderBy('searchedAt', descending: true)
        .limit(_limit)
        .get();
    return snapshot.docs
        .map((document) => document.data()['query'])
        .whereType<String>()
        .where((query) => query.trim().isNotEmpty)
        .toList();
  }

  /// Retry-safe: the local copy is removed only after every account write succeeds.
  Future<void> mergeGuestHistoryIntoCustomerAccount() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) return;
    final preferences = await SharedPreferences.getInstance();
    final guest = preferences.getStringList(_guestKey) ?? const <String>[];
    if (guest.isEmpty) return;
    final account = await loadRecent();
    final seen = <String>{};
    final merged = <String>[];
    for (final raw in [...guest, ...account]) {
      final query = _clean(raw);
      if (query.isNotEmpty && seen.add(query.toLowerCase())) {
        merged.add(query);
      }
      if (merged.length == _limit) break;
    }
    for (final query in merged.reversed) {
      if (_auth.currentUser?.uid != user.uid) return;
      await save(query);
    }
    if (_auth.currentUser?.uid == user.uid) {
      await preferences.remove(_guestKey);
    }
  }

  Future<void> save(String rawQuery) async {
    final query = _clean(rawQuery);
    if (query.isEmpty) return;

    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      final recent = preferences.getStringList(_guestKey) ?? <String>[];
      final normalized = query.toLowerCase();
      recent.removeWhere((item) => item.toLowerCase() == normalized);
      recent.insert(0, query);
      await preferences.setStringList(_guestKey, recent.take(_limit).toList());
      return;
    }

    final uid = _auth.currentUser!.uid;
    await _history(uid).doc(_documentId(query)).set({
      'query': query,
      'normalizedQuery': query.toLowerCase(),
      'searchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String rawQuery) async {
    final query = _clean(rawQuery);
    if (query.isEmpty) return;
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      final recent = preferences.getStringList(_guestKey) ?? <String>[];
      recent.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      await preferences.setStringList(_guestKey, recent);
      return;
    }
    await _history(_auth.currentUser!.uid).doc(_documentId(query)).delete();
  }

  Future<void> clear() async {
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_guestKey);
      return;
    }
    final snapshot = await _history(_auth.currentUser!.uid).get();
    final batch = _db.batch();
    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _db.collection('users').doc(uid).collection('searchHistory');

  String _clean(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.length <= 100 ? cleaned : cleaned.substring(0, 100);
  }

  String _documentId(String query) =>
      base64Url.encode(utf8.encode(query.toLowerCase())).replaceAll('=', '');
}
````

## File: lib/core/services/vendor_location_service.dart
````dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Shares an open vendor's location, including while the app is backgrounded.
/// Android keeps the stream alive with a visible foreground-service
/// notification; iOS uses the location background mode.
class VendorLocationService extends ChangeNotifier {
  VendorLocationService._();
  static final instance = VendorLocationService._();
  StreamSubscription<Position>? _positionSubscription;
  Future<void> _writes = Future<void>.value();
  String? _vendorId;
  int _generation = 0;
  String? error;
  bool get isSharing => _vendorId != null;

  Future<void> _operations = Future<void>.value();
  int _request = 0;

  Future<void> start(String vendorId) {
    final request = ++_request;
    _operations = _operations.catchError((Object _) {}).then((_) async {
      await _pause();
      if (request != _request ||
          FirebaseAuth.instance.currentUser?.uid != vendorId) {
        return;
      }
      _vendorId = vendorId;
      error = null;
      final generation = ++_generation;
      notifyListeners();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings(),
      ).listen(
        (position) => _queuePosition(vendorId, generation, position),
        onError: (Object _) {
          if (generation == _generation) {
            error = 'Location could not update. Check GPS and your connection.';
            notifyListeners();
          }
        },
      );
    });
    return _operations;
  }

  Future<void> pause() {
    ++_request;
    ++_generation;
    _operations = _operations.catchError((Object _) {}).then((_) => _pause());
    return _operations;
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 15),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Stall location sharing is active',
          notificationText:
              'Customers can see your location while your stall is open.',
          notificationChannelName: 'Stall location sharing',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  void _queuePosition(String vendorId, int generation, Position position) {
    _writes = _writes.catchError((Object _) {}).then(
          (_) => _writePosition(vendorId, generation, position),
        );
  }

  Future<void> _writePosition(
      String vendorId, int generation, Position position) async {
    try {
      if (generation != _generation ||
          FirebaseAuth.instance.currentUser?.uid != vendorId) {
        return;
      }
      final ref =
          FirebaseFirestore.instance.collection('vendors').doc(vendorId);
      // Do not reopen a stall closed by another screen/device.
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (generation != _generation || doc.data()?['isOpen'] != true) {
          return;
        }
        tx.update(ref, {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
          'locationSharingActive': true,
        });
      }).timeout(const Duration(seconds: 8));
      if (generation == _generation) {
        error = null;
      }
    } catch (_) {
      if (generation == _generation) {
        error = 'Location could not update. Check GPS and your connection.';
      }
    }
    if (generation == _generation) {
      notifyListeners();
    }
  }

  Future<void> _pause() async {
    ++_generation;
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
    final id = _vendorId;
    _vendorId = null;
    // Finish queued writes before writing the paused state.
    await _writes.catchError((Object _) {});
    if (id != null && FirebaseAuth.instance.currentUser?.uid == id) {
      try {
        await FirebaseFirestore.instance.collection('vendors').doc(id).update({
          'locationSharingActive': false,
        }).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Customers also expire old timestamps if this device is offline/killed.
      }
    }
    notifyListeners();
  }
}
````

## File: lib/core/widgets/app_dropdown.dart
````dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.hint = 'Select an option',
    this.displayText,
    this.icon,
    this.width,
    this.compact = false,
    this.iconOnly = false,
  });

  final Map<T, String> options;
  final ValueChanged<T>? onChanged;
  final T? value;
  final String? label;
  final String hint;
  final String? displayText;
  final IconData? icon;
  final double? width;
  final bool compact;
  final bool iconOnly;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _open = false;

  static const _accent = AppColors.primary;

  void _setOpen(bool value) {
    if (mounted && _open != value) {
      setState(() => _open = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth =
            math.max(48.0, MediaQuery.sizeOf(context).width - 32);

        final buttonWidth = widget.iconOnly
            ? 48.0
            : math.min(
                widget.width ??
                    (constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : 180.0),
                screenWidth,
              );

        final menuWidth =
            widget.iconOnly ? math.min(260.0, screenWidth) : buttonWidth;

        final enabled = widget.onChanged != null;
        final text =
            widget.displayText ?? widget.options[widget.value] ?? widget.hint;

        return SizedBox(
          width: buttonWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: const Color(0xFFF3F4F6),
                  focusColor: const Color(0xFFF3F4F6),
                  highlightColor: const Color(0xFFF3F4F6),
                ),
                child: PopupMenuButton<T>(
                  enabled: enabled,
                  tooltip: widget.label ?? widget.hint,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 6),
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 8,
                  shadowColor: const Color(0x26000000),
                  menuPadding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  constraints: BoxConstraints(
                    minWidth: menuWidth,
                    maxWidth: menuWidth,
                    maxHeight: 280,
                  ),
                  onOpened: () => _setOpen(true),
                  onCanceled: () => _setOpen(false),
                  onSelected: (value) {
                    _setOpen(false);
                    widget.onChanged?.call(value);
                  },
                  itemBuilder: (_) {
                    return widget.options.entries.map((option) {
                      final selected = option.key == widget.value;

                      return PopupMenuItem<T>(
                        value: option.key,
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.value,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      selected ? _accent : AppColors.textDark,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_rounded,
                                  size: 19, color: _accent),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: SizedBox(
                    width: buttonWidth,
                    height: widget.iconOnly
                        ? 48
                        : widget.compact
                            ? 40
                            : 52,
                    child: widget.iconOnly
                        ? Icon(
                            widget.icon ?? Icons.more_vert,
                            size: 22,
                            color: !enabled
                                ? Colors.grey
                                : _open
                                    ? _accent
                                    : AppColors.textDark,
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: enabled
                                  ? Colors.white
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  if (widget.icon != null) ...[
                                    Icon(
                                      widget.icon,
                                      size: 18,
                                      color:
                                          _open ? _accent : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: widget.compact ? 12 : 14,
                                        color: enabled
                                            ? AppColors.textDark
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _open
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: enabled
                                        ? AppColors.textDark
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
````

## File: lib/features/auth/screens/change_email_screen.dart
````dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _linkSent = false;
  bool _isBusy = false;
  Timer? _cooldownTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _linkSent && !_isBusy) {
      _checkNewEmail(quiet: true);
    }
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate() || _isBusy || _resendSeconds > 0) {
      return;
    }
    setState(() => _isBusy = true);
    final error = await _authService.sendEmailChangeLink(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (error == null) {
        _linkSent = true;
        _resendSeconds = 60;
      }
    });
    if (error == null) _startCooldown();
    _showMessage(
      error ?? 'Verification link sent to ${_emailController.text.trim()}.',
      error: error != null,
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _checkNewEmail({bool quiet = false}) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final error = await _authService.refreshEmailChange(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (error == null) {
      _showMessage('Email changed and verified successfully.');
      Navigator.pop(context, true);
    } else if (!quiet) {
      _showMessage(error, error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change Email')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_linkSent
                      ? 'Open the verification link sent to your new email, then return here and confirm.'
                      : 'Firebase will send a verification link to your new email. Your address changes only after you open that link.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    readOnly: _linkSent,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                        labelText: 'New email', border: OutlineInputBorder()),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)
                          ? null
                          : 'Enter a valid email address';
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_linkSent) ...[
                    FilledButton.icon(
                      onPressed: _isBusy ? null : () => _checkNewEmail(),
                      icon: _isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh),
                      label: Text(_isBusy
                          ? 'Checking…'
                          : 'I Have Verified My New Email'),
                    ),
                    TextButton(
                      onPressed:
                          _isBusy || _resendSeconds > 0 ? null : _sendLink,
                      child: Text(_resendSeconds > 0
                          ? 'Resend in ${_resendSeconds}s'
                          : 'Resend verification email'),
                    ),
                  ] else
                    FilledButton(
                      onPressed: _isBusy ? null : _sendLink,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Send Verification Link'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/auth/screens/email_verification_screen.dart
````dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  bool _isSending = false;
  bool _isChecking = false;
  bool _messageIsError = false;
  String? _message;
  Timer? _cooldownTimer;
  int _resendSeconds = 0;

  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendLink());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isSending && !_isChecking) {
      _checkVerification(quiet: true);
    }
  }

  Future<void> _sendLink() async {
    if (!mounted || _isSending || _isChecking || _resendSeconds > 0) return;
    setState(() {
      _isSending = true;
      _message = null;
    });
    final error = await _authService.sendEmailVerificationLink();
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _messageIsError = error != null;
      _message = error ?? 'Verification email sent to $_email.';
      if (error == null) _resendSeconds = 60;
    });
    if (error == null) _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _checkVerification({bool quiet = false}) async {
    if (_isChecking || _isSending) return;
    setState(() {
      _isChecking = true;
      if (!quiet) _message = null;
    });
    final error = await _authService.refreshEmailVerification();
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      if (!quiet || error == null) {
        _messageIsError = error != null;
        _message = error ?? 'Email verified successfully.';
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_unread_outlined,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 20),
                    Text('Verify your email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a verification link to $_email. Open the email, tap the link, then return here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _messageIsError
                                  ? Colors.red
                                  : Colors.green.shade700)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isChecking || _isSending
                          ? null
                          : () => _checkVerification(),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh),
                      label: Text(_isChecking
                          ? 'Checking…'
                          : 'I Have Verified My Email'),
                    ),
                    TextButton(
                      onPressed: _isSending || _isChecking || _resendSeconds > 0
                          ? null
                          : _sendLink,
                      child: Text(_isSending
                          ? 'Sending email…'
                          : _resendSeconds > 0
                              ? 'Resend in ${_resendSeconds}s'
                              : 'Resend verification email'),
                    ),
                    TextButton(
                      onPressed: _isChecking ? null : _authService.signOut,
                      child: const Text('Use a different account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/customer/home/open_at_picker.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';

class OpeningTimeFilter {
  const OpeningTimeFilter(this.start, this.label, {this.end});
  final DateTime start;
  final DateTime? end;
  final String label;
}

Future<OpeningTimeFilter?> showOpeningTimePicker(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('When would you like to visit?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'Based on vendor schedules in Malaysia time (MYT). Actual opening may change.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 22),
                AppGroupedCard(children: [
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.nightlight_outlined,
                          color: AppColors.primary),
                      title: const Text('After 10 PM tonight'),
                      subtitle: const Text('10 PM to 6 AM'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'tonight')),
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.wb_sunny_outlined,
                          color: AppColors.primaryLight),
                      title: const Text('Tomorrow morning'),
                      subtitle: const Text('6 AM to 12 PM'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'morning')),
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.calendar_month, color: AppColors.primary),
                      title: const Text('Choose date and time'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'custom')),
                ]),
              ]),
            ),
          ));
  if (choice == null || !context.mounted) return null;
  final now = DateTime.now();
  final local = malaysiaTime(now);
  final today = DateTime(local.year, local.month, local.day);
  final tomorrow = today.add(const Duration(days: 1));
  if (choice == 'tonight') {
    final ten = malaysiaInstant(today.year, today.month, today.day, 22, 0);
    return OpeningTimeFilter(
        ten.isBefore(now) ? now : ten, 'After 10 PM tonight',
        end:
            malaysiaInstant(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0));
  }
  if (choice == 'morning') {
    return OpeningTimeFilter(
        malaysiaInstant(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0),
        'Tomorrow morning',
        end: malaysiaInstant(
            tomorrow.year, tomorrow.month, tomorrow.day, 12, 0));
  }
  final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)));
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
      helpText: 'Visit time (MYT)');
  if (time == null || !context.mounted) return null;
  final instant =
      malaysiaInstant(date.year, date.month, date.day, time.hour, time.minute);
  if (instant.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future date and time.')));
    return null;
  }
  return OpeningTimeFilter(instant,
      '${date.day}/${date.month}/${date.year} · ${formatStallTime(time.hour * 60 + time.minute)} MYT');
}
````

## File: lib/features/customer/home/price_range_picker.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import 'discovery_search_filters.dart';

Future<MenuPriceRange?> showPriceRangePicker(
  BuildContext context, {
  MenuPriceRange? initialRange,
}) =>
    showModalBottomSheet<MenuPriceRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _PriceRangePicker(initialRange: initialRange),
    );

class _PriceRangePicker extends StatefulWidget {
  const _PriceRangePicker({this.initialRange});

  final MenuPriceRange? initialRange;

  @override
  State<_PriceRangePicker> createState() => _PriceRangePickerState();
}

class _PriceRangePickerState extends State<_PriceRangePicker> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;

  @override
  void initState() {
    super.initState();
    _minimum = TextEditingController(
        text: widget.initialRange?.minimum?.toStringAsFixed(2) ?? '');
    _maximum = TextEditingController(
        text: widget.initialRange?.maximum?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  String? _validateAmount(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final amount = double.tryParse(text);
    if (amount == null || !amount.isFinite || amount < 0) {
      return 'Enter a valid price';
    }
    return null;
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      MenuPriceRange(
        minimum: double.tryParse(_minimum.text),
        maximum: double.tryParse(_maximum.text),
      ),
    );
  }

  Widget _amountField(TextEditingController controller,
          {required bool isMax}) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: isMax ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) =>
              RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(newValue.text)
                  ? newValue
                  : oldValue),
        ],
        decoration: InputDecoration(
          labelText: isMax ? 'Maximum' : 'Minimum',
          hintText: 'Any',
          prefixText: 'RM ',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          final error = _validateAmount(value);
          if (error != null || !isMax) return error;
          final min = double.tryParse(_minimum.text);
          final max = double.tryParse(value ?? '');
          if (min != null && max != null && max < min) {
            return 'Must be at least the minimum';
          }
          return null;
        },
        onFieldSubmitted: isMax ? (_) => _apply() : null,
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                      child: Text('Dish price range',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600)),
                    ),
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Close price filter',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ]),
                  const Text(
                    'Find stalls with a dish in your budget. Leave a price blank for any amount.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _amountField(_minimum, isMax: false)),
                    const SizedBox(width: 12),
                    Expanded(child: _amountField(_maximum, isMax: true)),
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, const MenuPriceRange()),
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply price range'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/shared/booking_payment_card.dart
````dart
import 'package:flutter/material.dart';

import '../../core/models/demo_order.dart';

String bookingPaymentLabel(DemoOrder booking) {
  if (booking.paymentStatus == 'paid' && booking.paymentRefundedCents > 0) {
    return 'Partially refunded · Test';
  }
  return switch (booking.paymentStatus) {
    'paid' => 'Paid · Test',
    'refund_pending' => 'Test refund pending',
    'refund_failed' => 'Test refund needs attention',
    'refunded' => 'Refunded · Test',
    'failed' => 'Payment failed · Test',
    'expired' => 'Payment window ended',
    'cancelled' => 'Payment cancelled',
    'unpaid' => booking.status == 'requested'
        ? 'Available after acceptance'
        : 'Awaiting payment',
    _ => 'Awaiting payment · Test',
  };
}

class BookingPaymentCard extends StatelessWidget {
  const BookingPaymentCard(
      {super.key,
      required this.booking,
      required this.isVendor,
      this.busy = false,
      this.busyLabel = 'Processing…',
      this.onPay,
      this.onRefresh});

  final DemoOrder booking;
  final bool isVendor;
  final bool busy;
  final String busyLabel;
  final VoidCallback? onPay;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final paid = booking.paymentStatus == 'paid';
    final problem = {'failed', 'refund_failed'}.contains(booking.paymentStatus);
    final color = paid
        ? const Color(0xFF137547)
        : problem
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF9A5B13);
    final remaining = booking.paymentExpiresAt?.difference(DateTime.now());
    final seconds = remaining?.inSeconds.clamp(0, 600) ?? 0;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.credit_card_outlined),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Payment',
                        style: Theme.of(context).textTheme.titleMedium)),
                const Chip(
                    label: Text('TEST MODE'),
                    visualDensity: VisualDensity.compact),
              ]),
              const SizedBox(height: 8),
              Text('RM ${(booking.totalCents / 100).toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(
                    paid
                        ? Icons.check_circle
                        : problem
                            ? Icons.error_outline
                            : Icons.schedule,
                    size: 19,
                    color: color),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(bookingPaymentLabel(booking),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 10),
              if (booking.status == 'requested')
                const Text('Payment opens when the stall accepts this booking.')
              else if (booking.awaitingPayment)
                Text(seconds > 0
                    ? isVendor
                        ? 'Waiting for the customer to pay. Preparation unlocks after confirmation.'
                        : 'Pay within ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}.'
                    : 'The payment window has ended. Check payment to confirm the final status.'),
              if (booking.paymentStatus == 'refund_pending')
                const Text(
                    'This booking was cancelled. The full test refund to the original payment method is pending.')
              else if (booking.paymentStatus == 'refund_failed')
                const Text(
                    'The simulated refund did not complete. Contact the prototype administrator.'),
              if (booking.paymentReference != null) ...[
                const SizedBox(height: 10),
                Text('Payment reference',
                    style: Theme.of(context).textTheme.labelSmall),
                SelectableText(booking.paymentReference!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (booking.paymentRefundedCents > 0)
                Text(
                    'Refunded: RM ${(booking.paymentRefundedCents / 100).toStringAsFixed(2)}'),
              if (!isVendor && booking.canPay) ...[
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: busy ? null : onPay,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: Text(busy
                            ? busyLabel
                            : 'Pay RM ${(booking.totalCents / 100).toStringAsFixed(2)}'))),
                const SizedBox(height: 8),
                const Text(
                    'Use test card 4242 4242 4242 4242, any future expiry and any 3-digit CVC.',
                    style: TextStyle(fontSize: 12)),
              ],
              if (booking.paymentStatus != 'unpaid' &&
                  booking.paymentStatus != 'refunded')
                TextButton.icon(
                    onPressed: busy ? null : onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(busy ? 'Checking…' : 'Check payment')),
              const Divider(height: 24),
              const Text(
                  'Simulated payment only. No real money is charged or paid to the stall.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
            ])));
  }
}
````

## File: lib/features/shared/delete_account_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _auth = AuthService();
  final _confirmation = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  bool get _usesPassword =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((provider) => provider.providerId == 'password') ??
      false;

  Future<void> _delete() async {
    if (_busy) return;
    if (_confirmation.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = 'Type DELETE to confirm.');
      return;
    }
    if (_usesPassword && _password.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.deleteAccount(
      currentPassword: _usesPassword ? _password.text : null,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    _confirmation.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AccountLayout(
        title: 'Delete Account',
        busy: _busy,
        children: [
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.delete_solid,
                color: AppColors.closedRed,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Delete your account?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your StallSeeker account and its data will be permanently removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 32),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What will be removed',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Text(
                    'Your profile, followed stalls and dishes, notification history, and any vendor stall data.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This cannot be undone.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.closedRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 10),
            child: Text(
              'CONFIRM DELETION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextField(
            controller: _confirmation,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            textInputAction:
                _usesPassword ? TextInputAction.next : TextInputAction.done,
            onSubmitted: _usesPassword ? null : (_) => _delete(),
            decoration: accountField('Type DELETE to confirm'),
          ),
          if (_usesPassword) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _delete(),
              decoration: accountField(
                'Current password',
                suffix: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 9, 16, 0),
            child: Text(
              'Type DELETE exactly to confirm this permanent action.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 22),
          AccountError(_error),
          AccountButton(
            label: 'Delete Account',
            busy: _busy,
            color: AppColors.closedRed,
            onPressed: _delete,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
                minimumSize: const Size.fromHeight(54),
                shape: const StadiumBorder(),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      );
}
````

## File: lib/features/shared/edit_profile_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';
import 'profile_header.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.name, required this.email});

  final String name;
  final String email;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _auth = AuthService();
  late final TextEditingController _name =
      TextEditingController(text: widget.name);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      setState(() => _error = 'Please sign in to edit your profile.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.updateFullName(user.uid, _name.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Form(
              key: _form,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  SizedBox(
                    height: 116,
                    child: Stack(alignment: Alignment.topCenter, children: [
                      Positioned(
                        top: 12,
                        child: ProfileAvatar(
                          name: widget.name,
                          photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
                          size: 100,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: ProfileTopAction(
                          label: 'Cancel',
                          onTap: _busy ? null : () => Navigator.pop(context),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: ProfileTopAction(
                          label: _busy ? 'Saving…' : 'Done',
                          onTap: _busy ? null : _save,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 46),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'Full name',
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 19),
                        ),
                        style: const TextStyle(fontSize: 17),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter your name.'
                            : null,
                        onFieldSubmitted: (_) => _save(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'This name appears on your StallSeeker account.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email address',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textMuted)),
                          const SizedBox(height: 5),
                          Text(widget.email,
                              style: const TextStyle(fontSize: 17)),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Your sign-in email cannot be changed here.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AccountError(_error),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/shared/live_booking_section.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_detail_screen.dart';
import 'demo_orders_screen.dart';

class LiveBookingSection extends StatefulWidget {
  const LiveBookingSection({super.key, required this.isVendor});
  final bool isVendor;

  @override
  State<LiveBookingSection> createState() => _LiveBookingSectionState();
}

class _LiveBookingSectionState extends State<LiveBookingSection> {
  final _service = DemoOrderService();
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<DemoOrder>> _bookings = widget.isVendor
      ? _service.watchVendorOrders(_uid)
      : _service.watchCustomerOrders(_uid);

  void _openAll() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DemoOrdersScreen(isVendor: widget.isVendor)));

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: StreamBuilder<List<DemoOrder>>(
            stream: _bookings,
            builder: (context, snapshot) {
              final active =
                  snapshot.data?.where((order) => order.isActive).toList() ??
                      const <DemoOrder>[];
              final unseen = (snapshot.data ?? const <DemoOrder>[])
                  .where((order) => widget.isVendor
                      ? order.effectiveStatus == 'requested' &&
                          order.vendorUnseenRequest
                      : order.customerUnseenReady)
                  .length;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.receipt_long_outlined),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text('Live bookings',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700))),
                      if (unseen > 0)
                        Badge(label: Text(unseen > 99 ? '99+' : '$unseen')),
                      TextButton(
                          onPressed: _openAll, child: const Text('View all')),
                    ]),
                    if (snapshot.hasError)
                      const Text(
                          'Could not load bookings. Check your connection.')
                    else if (!snapshot.hasData)
                      const LinearProgressIndicator()
                    else if (active.isEmpty)
                      Text(widget.isVendor
                          ? 'No active bookings.'
                          : 'No active bookings yet. Your progress will appear here.'),
                    for (final order in active.take(2))
                      BookingSummaryCard(
                        booking: order,
                        isVendor: widget.isVendor,
                        compact: true,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(
                                    bookingId: order.id,
                                    isVendor: widget.isVendor))),
                      ),
                    if (active.length > 2)
                      Text('${active.length - 2} more active bookings',
                          style: Theme.of(context).textTheme.bodySmall),
                  ]);
            },
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/shared/pin_location_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'manual_location_dialog.dart';

class PinLocationScreen extends StatefulWidget {
  const PinLocationScreen({super.key, required this.initialLocation});
  final LatLng initialLocation;

  @override
  State<PinLocationScreen> createState() => _PinLocationScreenState();
}

class _PinLocationScreenState extends State<PinLocationScreen> {
  GoogleMapController? _controller;
  late LatLng _position = widget.initialLocation;
  String? _address;
  bool _saving = false;
  bool _mapReady = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final location = await showManualLocationDialog(context,
        initialLocation: _position, title: 'Find a place to pin');
    if (!mounted || location == null) return;
    setState(() {
      _position = location.coordinates;
      _address = location.label;
    });
    await _controller
        ?.animateCamera(CameraUpdate.newLatLngZoom(location.coordinates, 17));
  }

  Future<void> _usePin() async {
    setState(() => _saving = true);
    final position = _position;
    var label = _address;
    if (label == null) {
      try {
        label = await describeLocation(position);
      } catch (_) {
        label = '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      }
    }
    if (mounted) {
      Navigator.pop(
          context, LocationSelection(coordinates: position, label: label));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pin a location')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                  onPressed: _saving ? null : _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Search for a place'))),
          Expanded(
              child: Stack(alignment: Alignment.center, children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _position, zoom: 16),
              onMapCreated: (controller) {
                _controller = controller;
                if (mounted) setState(() => _mapReady = true);
              },
              onCameraMove: (camera) {
                if (_saving) return;
                if ((_position.latitude - camera.target.latitude).abs() >
                        .00001 ||
                    (_position.longitude - camera.target.longitude).abs() >
                        .00001) {
                  _address = null;
                }
                _position = camera.target;
              },
              scrollGesturesEnabled: !_saving,
              zoomGesturesEnabled: !_saving,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
            const IgnorePointer(
                child: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.location_pin,
                        size: 48, color: AppColors.primary))),
            const Positioned(
                top: 12,
                left: 20,
                right: 20,
                child: IgnorePointer(
                    child: Card(
                        child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                                'Move the map to place the pin at the exact location.',
                                textAlign: TextAlign.center))))),
          ])),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: _saving || !_mapReady ? null : _usePin,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Use this pin'))))),
        ]),
      );
}
````

## File: lib/features/vendor/profile/stall_schedule_editor.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/models/stall_schedule.dart';

class StallScheduleEditor extends StatelessWidget {
  const StallScheduleEditor(
      {super.key,
      required this.hours,
      required this.closures,
      required this.onChanged});

  final Map<int, List<StallHoursInterval>> hours;
  final List<TemporaryClosure> closures;
  final void Function(
      Map<int, List<StallHoursInterval>>, List<TemporaryClosure>) onChanged;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Map<int, List<StallHoursInterval>> _copyHours() => {
        for (var day = 1; day <= 7; day++) day: [...?hours[day]],
      };

  Future<void> _pickTime(BuildContext context, int day, int index,
      {required bool opening}) async {
    final interval = hours[day]![index];
    final current = opening ? interval.openMinute : interval.closeMinute;
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60));
    if (picked == null || !context.mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    if (minutes == (opening ? interval.closeMinute : interval.openMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Opening and closing times must be different.')));
      return;
    }
    final next = _copyHours();
    next[day]![index] = StallHoursInterval(
      opening ? minutes : interval.openMinute,
      opening ? interval.closeMinute : minutes,
    );
    onChanged(next, closures);
  }

  Future<DateTime?> _pickDateTime(
      BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 730)));
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    // The stall operates in Malaysia time, independently of device timezone.
    return DateTime.utc(
        date.year, date.month, date.day, time.hour - 8, time.minute);
  }

  Future<void> _addClosure(BuildContext context) async {
    if (closures.length >= 20) return;
    final nowMy = DateTime.now().toUtc().add(const Duration(hours: 8));
    final start = await _pickDateTime(context, nowMy);
    if (start == null || !context.mounted) return;
    final end = await _pickDateTime(
        context, start.toUtc().add(const Duration(hours: 18)));
    if (end == null || !context.mounted) return;
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Closure end must be after its start.')));
      return;
    }
    onChanged(
        hours,
        [...closures, TemporaryClosure(start, end)]
          ..sort((a, b) => a.start.compareTo(b.start)));
  }

  String _formatClosure(DateTime value) {
    final my = value.toUtc().add(const Duration(hours: 8));
    return '${my.day}/${my.month}/${my.year} ${formatStallTime(my.hour * 60 + my.minute)}';
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly opening hours',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          const Text(
              'These are planned hours. Use the Open switch when you start serving.'),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(children: [
                for (var day = 1; day <= 7; day++) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_days[day - 1]),
                    subtitle: Text(
                        (hours[day] ?? []).isEmpty ? 'Closed' : 'Scheduled'),
                    value: (hours[day] ?? []).isNotEmpty,
                    onChanged: (enabled) {
                      final next = _copyHours();
                      next[day] = enabled
                          ? [const StallHoursInterval(9 * 60, 17 * 60)]
                          : [];
                      onChanged(next, closures);
                    },
                  ),
                  for (var index = 0;
                      index < (hours[day] ?? []).length;
                      index++)
                    Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
                        child: Row(children: [
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () => _pickTime(
                                      context, day, index, opening: true),
                                  child: Text(formatStallTime(
                                      hours[day]![index].openMinute)))),
                          const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Text('to')),
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () => _pickTime(
                                      context, day, index, opening: false),
                                  child: Text(formatStallTime(
                                      hours[day]![index].closeMinute)))),
                          IconButton(
                              tooltip: 'Remove time',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                final next = _copyHours();
                                next[day]!.removeAt(index);
                                onChanged(next, closures);
                              }),
                        ])),
                  if ((hours[day] ?? []).isNotEmpty && hours[day]!.length < 3)
                    TextButton.icon(
                        onPressed: () {
                          final next = _copyHours();
                          next[day]!
                              .add(const StallHoursInterval(18 * 60, 22 * 60));
                          onChanged(next, closures);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add time')),
                  if (day < 7) const Divider(height: .5, thickness: .5),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text('Temporary closures',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          const Text(
              'Choose dates and times for breaks or days off. Your stall will close during a break. Use the Open switch to reopen afterward.'),
          for (var index = 0; index < closures.length; index++)
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${_formatClosure(closures[index].start)} –'),
                subtitle: Text(_formatClosure(closures[index].end)),
                trailing: IconButton(
                    tooltip: 'Remove closure',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      final next = [...closures]..removeAt(index);
                      onChanged(hours, next);
                    })),
          TextButton.icon(
              onPressed:
                  closures.length >= 20 ? null : () => _addClosure(context),
              icon: const Icon(Icons.event_busy_outlined),
              label: const Text('Add closure')),
        ],
      );
}
````

## File: lib/firebase_options.dart
````dart
// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
    appId: '1:793011933510:web:e9cb5587fb777961911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    authDomain: 'stallseeker-c2ffe.firebaseapp.com',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    measurementId: 'G-KEBYKY2P8P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzTEscU-ljvVtKgSVFs-KN3J3BtDre2Cs',
    appId: '1:793011933510:android:7127576788f40c81911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrE5vzUXqYDTN5UQrbVKzx8LBwiA18mrc',
    appId: '1:793011933510:ios:29aa93bdf1ed90e6911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    iosClientId: '793011933510-gphe3f510j5v4u555g4uo4ls5bm7bnsm.apps.googleusercontent.com',
    iosBundleId: 'com.example.stallseeker',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCrE5vzUXqYDTN5UQrbVKzx8LBwiA18mrc',
    appId: '1:793011933510:ios:29aa93bdf1ed90e6911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    iosClientId: '793011933510-gphe3f510j5v4u555g4uo4ls5bm7bnsm.apps.googleusercontent.com',
    iosBundleId: 'com.example.stallseeker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
    appId: '1:793011933510:web:b99eecd2060151e1911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    authDomain: 'stallseeker-c2ffe.firebaseapp.com',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    measurementId: 'G-QFFLHPN0GT',
  );
}
````

## File: test/app_pill_navigation_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_pill_navigation.dart';

void main() {
  for (final width in [390.0, 960.0]) {
    testWidgets(
        'pill navigation fits ${width.toInt()}px viewport and switches tabs',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var selected = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(builder: (context, setState) {
          return Scaffold(
            extendBody: true,
            body: const ColoredBox(
              key: Key('page-content'),
              color: Colors.green,
              child: SizedBox.expand(),
            ),
            bottomNavigationBar: AppPillNavigation(
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  setState(() => selected = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.favorite), label: 'Following'),
                NavigationDestination(
                    icon: Icon(Icons.notifications), label: 'Notifications'),
                NavigationDestination(
                    icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          );
        }),
      ));

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(find.byKey(const Key('pill-navigation')));
      expect(bar.left, greaterThanOrEqualTo(12));
      expect(bar.right, lessThanOrEqualTo(width - 12));
      expect(bar.width, closeTo(width < 674 ? width - 24 : 650, 1));
      expect(tester.getRect(find.byKey(const Key('page-content'))).bottom,
          greaterThan(bar.bottom));
      expect(find.byTooltip('Search'), findsNothing);

      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 3);
      expect(tester.takeException(), isNull);
    });
  }
}
````

## File: test/discovery_filters_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/services/place_search_service.dart';
import 'package:stallseeker/features/shared/manual_location_dialog.dart';

class FakePlacesSdk extends places.FlutterGooglePlacesSdk {
  FakePlacesSdk({this.failure}) : super('test-key');

  final Object? failure;

  String? lastQuery;
  List<String>? requestedCountries;

  @override
  Future<places.FindAutocompletePredictionsResponse>
      findAutocompletePredictions(
    String query, {
    List<String>? countries,
    List<places.PlaceTypeFilter> placeTypesFilter = const [],
    bool? newSessionToken,
    places.LatLng? origin,
    places.LatLngBounds? locationBias,
    places.LatLngBounds? locationRestriction,
  }) async {
    lastQuery = query;
    requestedCountries = countries;

    final error = failure;
    if (error != null) throw error;

    return const places.FindAutocompletePredictionsResponse([
      places.AutocompletePrediction(
        distanceMeters: null,
        placeId: 'bangi',
        primaryText: 'Bangi',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi, Selangor, Malaysia',
      ),
      places.AutocompletePrediction(
        distanceMeters: null,
        placeId: 'bangi-square',
        primaryText: 'Bangi Square',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi Square, Selangor, Malaysia',
      ),
    ]);
  }
}

class FakePlaceSearchService extends PlaceSearchService {
  FakePlaceSearchService() : super(places: FakePlacesSdk());

  @override
  Future<List<PlaceSuggestion>> search(String query) async {
    return const [
      PlaceSuggestion(
        placeId: 'bangi',
        primaryText: 'Bangi',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi, Selangor, Malaysia',
        coordinates: LatLng(2.9, 101.7),
      ),
      PlaceSuggestion(
        placeId: 'bangi-square',
        primaryText: 'Bangi Square',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi Square, Selangor, Malaysia',
        coordinates: LatLng(2.91, 101.8),
      ),
    ];
  }
}

void main() {
  group('scheduled opening in Malaysia time', () {
    final hours = <int, List<StallHoursInterval>>{
      1: [const StallHoursInterval(20 * 60, 2 * 60)],
      2: [
        const StallHoursInterval(8 * 60, 12 * 60),
        const StallHoursInterval(14 * 60, 17 * 60),
      ],
      7: [const StallHoursInterval(23 * 60, 60)],
    };

    DateTime at(int day, int hour, [int minute = 0]) =>
        malaysiaInstant(2026, 9, day, hour, minute);

    test(
      'overnight hours include next day and Sunday to Monday rollover',
      () {
        expect(isWithinStallSchedule(at(21, 0, 30), hours, []), isTrue);
        expect(isWithinStallSchedule(at(21, 20), hours, []), isTrue);
        expect(isWithinStallSchedule(at(22, 1, 59), hours, []), isTrue);
        expect(isWithinStallSchedule(at(22, 2), hours, []), isFalse);
        expect(isWithinStallSchedule(at(22, 13), hours, []), isFalse);
      },
    );

    test(
      'no saved schedule is not assumed open at a future time',
      () {
        expect(isWithinStallSchedule(at(22, 10), {}, []), isFalse);
      },
    );

    test(
      'closures override an exact time at inclusive start and exclusive end',
      () {
        final closures = [
          TemporaryClosure(at(22, 9), at(22, 10)),
        ];

        expect(
          isWithinStallSchedule(at(22, 9), hours, closures),
          isFalse,
        );
        expect(
          isWithinStallSchedule(at(22, 10), hours, closures),
          isTrue,
        );
      },
    );

    test(
      'time windows match partial openings but exclude fully closed windows',
      () {
        expect(
          hasScheduledOpening(at(21, 22), at(22, 6), hours, []),
          isTrue,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [TemporaryClosure(at(22, 8), at(22, 12))],
          ),
          isFalse,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [TemporaryClosure(at(22, 8), at(22, 10))],
          ),
          isTrue,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [
              TemporaryClosure(at(22, 8), at(22, 10)),
              TemporaryClosure(at(22, 10), at(22, 12)),
            ],
          ),
          isFalse,
        );
      },
    );
  });

  test('Google Places search requests Malaysian suggestions', () async {
    final sdk = FakePlacesSdk();
    final service = PlaceSearchService(places: sdk);

    final results = await service.search(' bangi ');

    expect(sdk.lastQuery, 'bangi');
    expect(sdk.requestedCountries, ['my']);
    expect(results.length, 2);
    expect(results.last.placeId, 'bangi-square');
    expect(
      results.last.fullText,
      'Bangi Square, Selangor, Malaysia',
    );

    service.dispose();
  });

  test('Google Places errors propagate for fallback handling', () async {
    final service = PlaceSearchService(
      places: FakePlacesSdk(
        failure: StateError('Places API unavailable'),
      ),
    );

    await expectLater(
      service.search('ipoh'),
      throwsA(isA<StateError>()),
    );

    service.dispose();
  });

  testWidgets(
    'customer can change the selected location suggestion',
    (tester) async {
      final service = FakePlaceSearchService();
      LocationSelection? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showManualLocationDialog(
                    context,
                    placeSearch: service,
                  );
                },
                child: const Text('Pick location'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick location'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'bangi');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use location'));
      await tester.pumpAndSettle();

      expect(
        selected?.label,
        'Bangi Square, Selangor, Malaysia',
      );
      expect(selected?.coordinates, const LatLng(2.91, 101.8));
      expect(tester.takeException(), isNull);

      service.dispose();
    },
  );
}
````

## File: lib/core/models/menu_item_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String itemId;
  final String name;
  final double price;
  final String
      status; // 'available' (Green), 'low_stock' (Yellow), 'out_of_stock' (Red)
  final String imageUrl;
  final String section;
  final DateTime? statusUpdatedAt;

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    this.status = 'available',
    this.imageUrl = '',
    this.section = 'Main menu',
    this.statusUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
      'section': section,
      'statusUpdatedAt': statusUpdatedAt == null
          ? FieldValue.serverTimestamp() : Timestamp.fromDate(statusUpdatedAt!),
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      itemId: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'available',
      imageUrl: map['imageUrl'] ?? '',
      section: (map['section'] as String?)?.trim().isNotEmpty == true
          ? map['section'] as String : 'Main menu',
      statusUpdatedAt: (map['statusUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
````

## File: lib/core/models/notification_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel(
      {required this.id,
      required this.vendorId,
      required this.title,
      required this.body,
      required this.createdAt,
      required this.isRead,
      this.itemId,
      this.type = 'vendor_opened'});

  final String id;
  final String vendorId;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool isRead;
  final String? itemId;
  final String type;

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    final time = data['createdAt'];
    return NotificationModel(
      id: id,
      vendorId: data['vendorId'] is String ? data['vendorId'] as String : '',
      title: data['title'] is String ? data['title'] as String : 'Stall update',
      body: data['body'] is String ? data['body'] as String : '',
      createdAt: time is Timestamp ? time.toDate() : null,
      isRead: data['isRead'] == true,
      itemId: data['itemId'] is String ? data['itemId'] as String : null,
      type: data['type'] is String ? data['type'] as String : 'vendor_opened',
    );
  }
}

// represent saved notifcation
````

## File: lib/core/services/place_search_service.dart
````dart
import 'package:flutter/foundation.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    hide LatLng;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSelection {
  const LocationSelection({
    required this.coordinates,
    required this.label,
  });

  final LatLng coordinates;
  final String label;
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
    this.coordinates,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
  final LatLng? coordinates;
}

class PlaceSearchService {
  PlaceSearchService({FlutterGooglePlacesSdk? places})
      : _places = places ??
            FlutterGooglePlacesSdk(
              'AIzaSyDV0UDXXVwuXQw3dVAb8RHmcql3bTlysNE',
              useNewApi: true,
            );

  final FlutterGooglePlacesSdk _places;

  void dispose() {}

  Future<List<PlaceSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final response = await _places.findAutocompletePredictions(
        trimmed,
        countries: ['my'],
      ).timeout(const Duration(seconds: 12));

      return response.predictions.map((prediction) {
        return PlaceSuggestion(
          placeId: prediction.placeId,
          primaryText: prediction.primaryText,
          secondaryText: prediction.secondaryText,
          fullText: prediction.fullText,
        );
      }).toList();
    } catch (error, stackTrace) {
      debugPrint('Google Places search failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<LatLng?> getCoordinates(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      final response = await _places.fetchPlace(
        placeId,
        fields: [PlaceField.Location],
      ).timeout(const Duration(seconds: 12));

      final coordinates = response.place?.latLng;

      if (coordinates == null) return null;

      return LatLng(coordinates.lat, coordinates.lng);
    } catch (error, stackTrace) {
      debugPrint('Google Places details failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
````

## File: lib/core/services/storage_service.dart
````dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Opens the gallery picker. Returns null if the vendor backed out
  // without choosing anything.
  Future<File?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) { return null; }
    return File(picked.path);
  }

  // Uploads a stall's cover photo. Always uses the same file name per
  // vendor, so re-uploading overwrites the old photo instead of leaving
  // unused files in Storage.
  Future<String> uploadStallImage(String vendorId, File imageFile) async {
    final ref = _storage.ref().child('stall_images/$vendorId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Uploads a photo for one menu item. Named by itemId so each dish has
  // its own file, and re-uploading a photo for the same dish overwrites it.
  Future<String> uploadMenuItemImage(
    String vendorId,
    String itemId,
    File imageFile,
  ) async {
    final ref = _storage.ref().child('menu_images/$vendorId/$itemId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<List<File>> pickReviewImages(int remaining) async {
    final picked = await _picker.pickMultiImage(maxWidth: 1080, imageQuality: 75);
    return picked.take(remaining.clamp(0, 5))
        .map((image) => File(image.path)).toList();
  }

  Future<String> uploadReviewImage(String vendorId, String customerId,
      String imageId, File imageFile) async {
    final ref = _storage.ref().child('review_images/$vendorId/$customerId/$imageId.jpg');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }

  Future<void> deleteReviewImageUrl(String vendorId, String customerId,
      String url) async {
    final ref = _storage.refFromURL(url);
    if (!ref.fullPath.startsWith('review_images/$vendorId/$customerId/')) {
      throw ArgumentError('Review photo does not belong to this customer.');
    }
    await ref.delete();
  }
}
````

## File: lib/core/widgets/app_pill_navigation.dart
````dart
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Floating iOS-style tab bar shared by customer and vendor screens.
class AppPillNavigation extends StatelessWidget {
  const AppPillNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Container(
                key: const Key('pill-navigation'),
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 16,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(36),
                  clipBehavior: Clip.antiAlias,
                  child: Row(children: [
                    for (var index = 0; index < destinations.length; index++)
                      Expanded(
                        child: InkWell(
                          onTap: () => onDestinationSelected(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    size: 25,
                                    color: index == selectedIndex
                                        ? AppColors.primary
                                        : AppColors.textDark,
                                  ),
                                  child: index == selectedIndex
                                      ? (destinations[index].selectedIcon ??
                                          destinations[index].icon)
                                      : destinations[index].icon,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destinations[index].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.1,
                                    color: index == selectedIndex
                                        ? AppColors.primary
                                        : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/customer/following/followed_dishes_list.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/models/dish_follow_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/dish_follow_service.dart';
import '../../../core/services/vendor_service.dart';
import '../vendor_details/vendor_details_screen.dart';

class FollowedDishesList extends StatefulWidget {
  const FollowedDishesList({super.key, required this.uid});
  final String uid;

  @override
  State<FollowedDishesList> createState() => _FollowedDishesListState();
}

class _FollowedDishesListState extends State<FollowedDishesList> {
  final _service = DishFollowService();
  Stream<List<DishFollowModel>>? _stream;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(FollowedDishesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) _listen();
  }

  void _listen() {
    final user = FirebaseAuth.instance.currentUser;
    _stream = user?.uid == widget.uid && user?.emailVerified == true
        ? _service.watch(widget.uid)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Verify your email to follow dishes and get restock alerts.',
              textAlign: TextAlign.center));
    }
    return StreamBuilder<List<DishFollowModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Text('Could not load followed dishes.',
                    textAlign: TextAlign.center),
                TextButton(
                    onPressed: () => setState(_listen),
                    child: const Text('Retry')),
              ]));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()));
        }
        final follows = [...?snapshot.data]..sort((a, b) =>
            (b.followedAt ?? DateTime(1970))
                .compareTo(a.followedAt ?? DateTime(1970)));
        if (follows.isEmpty) {
          return const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                Text('No followed dishes yet',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text(
                    'Open a stall’s menu and tap Follow dish. Your dishes will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8E8E93))),
              ]));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Alerts arrive when a sold-out dish is restocked.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)))),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text('FOLLOWED DISHES · ${follows.length}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
          AppGroupedCard(children: [
            for (var index = 0; index < follows.length; index++) ...[
              _FollowedDishRow(
                  key: ValueKey(follows[index].id),
                  uid: widget.uid,
                  follow: follows[index]),
            ],
          ]),
        ]);
      },
    );
  }
}

class _FollowedDishRow extends StatefulWidget {
  const _FollowedDishRow({super.key, required this.uid, required this.follow});
  final String uid;
  final DishFollowModel follow;
  @override
  State<_FollowedDishRow> createState() => _FollowedDishRowState();
}

class _FollowedDishRowState extends State<_FollowedDishRow> {
  final _service = DishFollowService();
  final _vendors = VendorService();
  late Stream<MenuItemModel?> _dish;
  late Stream<VendorModel?> _vendor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dish = _service.watchDish(widget.follow.vendorId, widget.follow.itemId);
    _vendor = _vendors.watchVendorProfile(widget.follow.vendorId);
  }

  Future<void> _unfollow() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.unfollow(
          widget.uid, widget.follow.vendorId, widget.follow.itemId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not unfollow this dish. Please retry.')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<MenuItemModel?>(
        stream: _dish,
        builder: (context, dishSnapshot) => StreamBuilder<VendorModel?>(
            stream: _vendor,
            builder: (context, vendorSnapshot) {
              final dish = dishSnapshot.data;
              final vendor = vendorSnapshot.data;
              final loading =
                  dishSnapshot.connectionState == ConnectionState.waiting ||
                      vendorSnapshot.connectionState == ConnectionState.waiting;
              final error = dishSnapshot.hasError || vendorSnapshot.hasError;
              final available = dish != null && dish.status != 'out_of_stock';
              final status = loading
                  ? 'Loading…'
                  : error
                      ? 'Could not refresh this dish'
                      : dish == null || vendor == null
                          ? 'No longer available'
                          : dish.status == 'low_stock'
                              ? 'Low stock'
                              : available
                                  ? 'Available'
                                  : 'Sold out · waiting for restock';
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: AppIconTile(
                    icon: Icons.restaurant_rounded,
                    color: available
                        ? AppColors.primary
                        : const Color(0xFF949499)),
                title: Text(
                    dish?.name ??
                        (loading ? 'Loading dish…' : 'Unavailable dish'),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0)),
                subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vendor != null)
                            Text(vendor.stallName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8E8E93),
                                    letterSpacing: 0)),
                          const SizedBox(height: 3),
                          Text(
                              dish != null && !error && !loading
                                  ? '$status · RM ${dish.price.toStringAsFixed(2)}'
                                  : status,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: available && !error
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF8E8E93))),
                        ])),
                trailing: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        tooltip: 'Unfollow dish',
                        onPressed: _unfollow,
                        icon: const Icon(Icons.notifications_active_outlined,
                            color: AppColors.primary)),
                onTap: vendor == null || loading || error
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VendorDetailsScreen(
                                vendor: vendor,
                                initialDishId: widget.follow.itemId))),
              );
            }),
      );
}
````

## File: lib/features/customer/orders/demo_order_cart_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/demo_order.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/demo_order_service.dart';
import '../../../core/services/menu_service.dart';
import '../../shared/booking_detail_screen.dart';

class DemoOrderCartScreen extends StatefulWidget {
  const DemoOrderCartScreen({super.key, required this.vendor});
  final VendorModel vendor;

  @override
  State<DemoOrderCartScreen> createState() => _DemoOrderCartScreenState();
}

class _DemoOrderCartScreenState extends State<DemoOrderCartScreen> {
  final _quantities = <String, int>{};
  final _service = DemoOrderService();
  final _menuService = MenuService();
  late final Stream<List<MenuItemModel>> _menu;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _menu = _menuService.getMenuItems(widget.vendor.vendorId);
  }

  Future<void> _submit(List<MenuItemModel> items) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sign in with a verified customer account to book.')));
      return;
    }
    final selected = <DemoOrderItem>[];
    for (final item in items) {
      final quantity = _quantities[item.itemId] ?? 0;
      if (quantity > 0 && item.status != 'out_of_stock') {
        selected.add(DemoOrderItem(
            itemId: item.itemId,
            name: item.name,
            unitPriceCents: (item.price * 100).round(),
            quantity: quantity));
      }
    }
    if (selected.isEmpty) return;
    setState(() => _sending = true);
    try {
      final bookingId = await _service.requestOrder(widget.vendor, selected);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                  bookingId: bookingId,
                  isVendor: false,
                  openCheckoutOnStart: true)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                error is FirebaseFunctionsException && error.message != null
                    ? error.message!
                    : 'Could not save this booking. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your order')),
        body: StreamBuilder<List<MenuItemModel>>(
          stream: _menu,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load the menu.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return BookingCartView(
              stallName: widget.vendor.stallName,
              items: snapshot.data!,
              quantities: _quantities,
              sending: _sending,
              onQuantityChanged: (item, quantity) => setState(() {
                _quantities[item.itemId] = quantity;
              }),
              onSubmit: () => _submit(snapshot.data!),
            );
          },
        ),
      );
}

class BookingCartView extends StatelessWidget {
  const BookingCartView({
    super.key,
    required this.stallName,
    required this.items,
    required this.quantities,
    required this.sending,
    required this.onQuantityChanged,
    required this.onSubmit,
  });

  final String stallName;
  final List<MenuItemModel> items;
  final Map<String, int> quantities;
  final bool sending;
  final void Function(MenuItemModel, int) onQuantityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item.status == 'out_of_stock' ? 0 : (quantities[item.itemId] ?? 0)) *
              (item.price * 100).round(),
    );
    final itemCount = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item.status == 'out_of_stock' ? 0 : (quantities[item.itemId] ?? 0)),
    );
    final canContinue = total >= 200 && !sending;

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELF-COLLECT',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(stallName,
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.15)),
                    const SizedBox(height: 8),
                    const Text('Choose your food for pickup.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14)),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 21, color: AppColors.openGreen),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pay to confirm',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                                SizedBox(height: 3),
                                Text(
                                    'The stall gets your booking after payment.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text('Stripe test payment · No real charge',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                    const SizedBox(height: 30),
                    Row(children: [
                      const Text('Menu',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const Spacer(),
                      Text(
                          '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ]),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child:
                            Center(child: Text('No dishes on the menu yet.')),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                    height: 1, indent: 16, endIndent: 16),
                              _MenuItemRow(
                                item: items[i],
                                quantity: items[i].status == 'out_of_stock'
                                    ? 0
                                    : (quantities[items[i].itemId] ?? 0),
                                onChanged: (quantity) =>
                                    onQuantityChanged(items[i], quantity),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.cardColor,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                            itemCount == 0
                                ? 'Order total'
                                : '$itemCount ${itemCount == 1 ? 'item' : 'items'} · Total',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textMuted)),
                      ),
                      const SizedBox(width: 8),
                      Text('RM ${(total / 100).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ]),
                    if (itemCount > 0 && total < 200) ...[
                      const SizedBox(height: 5),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Minimum order RM2.00',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: canContinue ? onSubmit : null,
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      itemCount == 0
                                          ? 'Choose an item'
                                          : 'Continue to payment',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (itemCount > 0) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 18),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  final MenuItemModel item;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = item.status != 'out_of_stock';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: available
                          ? AppColors.textDark
                          : AppColors.textMuted)),
              const SizedBox(height: 5),
              Text(
                  available
                      ? 'RM ${item.price.toStringAsFixed(2)}'
                      : 'Out of stock',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: available ? FontWeight.w500 : FontWeight.w400,
                      color:
                          available ? AppColors.primary : AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: 'Remove ${item.name}',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              iconSize: 20,
              onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 24,
              child: Text('$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Add ${item.name}',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              iconSize: 20,
              onPressed: available && quantity < 20
                  ? () => onChanged(quantity + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ]),
        ),
      ]),
    );
  }
}
````

## File: lib/features/shared/about_screen.dart
````dart
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'info_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.65,
              color: Color(0xFF52525A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      title: 'About StallSeeker',
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/app_logo.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
                semanticLabel: 'StallSeeker logo',
              ),
              const SizedBox(height: 16),
              const Text(
                'StallSeeker',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Version 1.0.3 · Prototype',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _section(
          'Why StallSeeker exists',
          'Food stalls do not always operate from one fixed location or '
              'keep the same menu throughout the day. A stall may close early, '
              'move to another spot, or sell out of a dish. StallSeeker helps '
              'customers check vendor-provided details before making the trip.',
        ),
        _section(
          'Finding a stall',
          'Customers can explore stalls on a map, search for dishes, and '
              'filter results by location, category, distance, price, and '
              'opening status. Stall pages show information such as the menu, '
              'availability, reviews, and directions. Customers can also '
              'follow stalls or dishes for updates and request self-collect '
              'bookings where available.',
        ),
        _section(
          'Managing a stall',
          'Vendors can update their stall details, business hours, and '
              'temporary closures. They can add menu items, change prices, '
              'upload images, and mark items as out of stock. When their stall '
              'is open, they can share its current location and manage '
              'booking requests from customers.',
        ),
        _section(
          'Guest and account access',
          'Visitors can browse as guests without creating an account. '
              'Signing in allows the app to keep account-based information, '
              'such as followed stalls and dishes and booking activity, '
              'connected to the same user.',
        ),
        _section(
          'Checking the latest details',
          'Stall information is managed by vendors and can change during '
              'service. Opening status, location, prices, and availability '
              'should be checked again before travelling for a particular '
              'stall or dish.',
        ),
        const Divider(
          height: 1,
          color: Color(0xFFEEEEEE),
        ),
        const SizedBox(height: 20),
        const Text(
          'StallSeeker is a Final Year Project prototype. Its features '
          'and listings are being tested and may change during development.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
````

## File: lib/features/shared/booking_detail_screen.dart
````dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_payment_card.dart';

enum _PaymentTransition { openingCheckout, checkingPayment }

class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard(
      {super.key,
      required this.booking,
      required this.isVendor,
      required this.onTap,
      this.compact = false});

  final DemoOrder booking;
  final bool isVendor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final unseen =
        isVendor ? booking.vendorUnseenRequest : booking.customerUnseenReady;
    final color = booking.status == 'ready'
        ? const Color(0xFF137547)
        : booking.status == 'requested'
            ? const Color(0xFFB65A16)
            : Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (unseen) ...[
                const CircleAvatar(
                    radius: 4, backgroundColor: Color(0xFFE84E36)),
                const SizedBox(width: 8),
              ],
              Expanded(
                  child: Text(
                      isVendor ? booking.customerName : booking.stallName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16))),
              Text('RM ${(booking.totalCents / 100).toStringAsFixed(2)}'),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ]),
            const SizedBox(height: 8),
            Text(bookingStatusLabel(booking),
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            if (booking.hasTestPayment) ...[
              const SizedBox(height: 4),
              Text(bookingPaymentLabel(booking),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                  booking.items
                      .map((item) => '${item.quantity}× ${item.name}')
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (booking.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(_dateTime(booking.createdAt!),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ]),
        ),
      ),
    );
  }
}

String _dateTime(DateTime date) => '${date.day}/${date.month}/${date.year} '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen(
      {super.key,
      required this.bookingId,
      required this.isVendor,
      this.openCheckoutOnStart = false});
  final String bookingId;
  final bool isVendor;
  final bool openCheckoutOnStart;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen>
    with WidgetsBindingObserver {
  final _service = DemoOrderService();
  late final Stream<DemoOrder?> _booking =
      _service.watchBooking(widget.bookingId);
  bool _busy = false;
  bool _viewing = false;
  bool _initialPaymentCheck = false;
  bool _hasTestPayment = false;
  bool _checkoutLaunched = false;
  bool _refreshOnResume = false;
  bool _refreshWithTransition = false;
  _PaymentTransition? _paymentTransition;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.openCheckoutOnStart && !widget.isVendor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
              _runPaymentTransition(_pay, _PaymentTransition.openingCheckout));
        }
      });
    }
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _hasTestPayment) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasTestPayment) {
      final showTransition = _checkoutLaunched && !widget.isVendor;
      _checkoutLaunched = false;
      if (_busy) {
        _refreshOnResume = true;
        _refreshWithTransition |= showTransition;
      } else {
        unawaited(showTransition
            ? _checkPayment()
            : _act(() => _service.refreshPayment(widget.bookingId)));
      }
    }
  }

  Future<void> _checkPayment() => _runPaymentTransition(
        () => _service.refreshPayment(widget.bookingId),
        _PaymentTransition.checkingPayment,
      );

  Future<void> _runPaymentTransition(
      Future<void> Function() action, _PaymentTransition transition) async {
    if (!mounted || _busy) return;
    setState(() => _paymentTransition = transition);
    try {
      await _act(action);
    } finally {
      if (mounted) setState(() => _paymentTransition = null);
    }
  }

  Future<void> _pay() async {
    final uri = await _service.createTestCheckout(widget.bookingId);
    await _launchCheckout(uri);
  }

  Future<void> _launchCheckout(Uri uri) async {
    bool opened;
    _checkoutLaunched = true;
    try {
      opened = await launchUrl(uri,
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    } catch (_) {
      opened = false;
    }
    if (!opened) _checkoutLaunched = false;
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not open Stripe checkout.'),
          action: SnackBarAction(
              label: 'Try again',
              onPressed: () {
                unawaited(_runPaymentTransition(() => _launchCheckout(uri),
                    _PaymentTransition.openingCheckout));
              })));
    }
  }

  void _viewIfNeeded(DemoOrder booking) {
    final unseen = widget.isVendor
        ? booking.vendorUnseenRequest
        : booking.customerUnseenReady;
    if (!unseen || _viewing) return;
    _viewing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _service.markViewed(widget.bookingId);
      } catch (_) {
        // The booking remains unread and can be retried when reopened.
      } finally {
        _viewing = false;
      }
    });
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                error is FirebaseFunctionsException && error.message != null
                    ? error.message!
                    : 'Could not update this booking. Please try again.')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_refreshOnResume) {
          final showTransition = _refreshWithTransition;
          _refreshOnResume = false;
          _refreshWithTransition = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(showTransition
                  ? _checkPayment()
                  : _act(() => _service.refreshPayment(widget.bookingId)));
            }
          });
        }
      }
    }
  }

  Widget _paymentTransitionView() {
    final opening = _paymentTransition == _PaymentTransition.openingCheckout;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 38, color: AppColors.primary),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  opening
                      ? 'Opening secure checkout'
                      : 'Checking payment status',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  opening
                      ? 'Please wait while we open Stripe.'
                      : 'Confirming your payment with Stripe.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Test mode · No real charge',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(String label, Future<void> Function() action,
      {bool primary = true}) {
    return primary
        ? FilledButton(
            onPressed: _busy ? null : () => _act(action), child: Text(label))
        : OutlinedButton(
            onPressed: _busy ? null : () => _act(action), child: Text(label));
  }

  Future<void> _confirmCancellation(DemoOrder booking) async {
    final paid = booking.paymentStatus == 'paid';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(paid
            ? 'The full test payment will be refunded to the original payment method. Refund status may take time to update.'
            : 'The booking will be cancelled. Any open test checkout will close.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(paid ? 'Cancel and refund' : 'Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _service.cancel(booking.id);
  }

  List<Widget> _actions(DemoOrder booking) {
    final status = booking.effectiveStatus;
    if (!widget.isVendor) {
      return booking.canCustomerCancel
          ? [
              _action(
                  booking.paymentStatus == 'paid'
                      ? 'Cancel and refund'
                      : 'Cancel booking',
                  () => _confirmCancellation(booking),
                  primary: false)
            ]
          : [];
    }
    return switch (status) {
      'requested' => [
          _action('Accept', () => _service.respond(booking.id, accept: true)),
          _action('Reject', () => _service.respond(booking.id, accept: false),
              primary: false),
        ],
      'confirmed' => [
          if (booking.canPrepare)
            _action(
                'Start preparing', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      'preparing' => [
          _action('Mark ready', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      'ready' => [
          _action('Mark collected', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      _ => [],
    };
  }

  Widget _progress(DemoOrder booking) {
    final steps = [
      if (booking.checkoutFirst)
        'checkout_started'
      else ...[
        'requested',
        'confirmed',
      ],
      if (booking.hasTestPayment) 'payment_confirmed',
      'preparing',
      'ready',
      'collected'
    ];
    var position = steps.indexOf(booking.effectiveStatus);
    if (booking.checkoutFirst && booking.status == 'confirmed') {
      position = steps.indexOf(booking.paymentStatus == 'paid'
          ? 'payment_confirmed'
          : 'checkout_started');
    } else if (booking.hasTestPayment &&
        booking.status == 'confirmed' &&
        booking.paymentStatus == 'paid') {
      position = steps.indexOf('payment_confirmed');
    }
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(i <= position ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: i <= position ? const Color(0xFF137547) : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    steps[i] == 'payment_confirmed'
                        ? 'Test payment confirmed'
                        : steps[i] == 'checkout_started'
                            ? 'Checkout started'
                            : demoOrderStatusLabel(steps[i]),
                    style: TextStyle(
                        fontWeight: i == position ? FontWeight.bold : null))),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: const Text('Booking details')),
            body: StreamBuilder<DemoOrder?>(
              stream: _booking,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text(
                          'Could not load this booking. Check your connection.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final booking = snapshot.data;
                if (booking == null) {
                  return const Center(child: Text('Booking not found.'));
                }
                _viewIfNeeded(booking);
                _hasTestPayment = booking.hasTestPayment;
                if (!_initialPaymentCheck &&
                    booking.hasTestPayment &&
                    booking.paymentStatus != 'unpaid') {
                  _initialPaymentCheck = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_busy) {
                      unawaited(
                          _act(() => _service.refreshPayment(booking.id)));
                    }
                  });
                }
                return ListView(padding: const EdgeInsets.all(18), children: [
                  Text(
                      widget.isVendor
                          ? booking.customerName
                          : booking.stallName,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  if (booking.createdAt != null)
                    Text(
                        '${booking.checkoutFirst ? 'Started' : 'Requested'} ${_dateTime(booking.createdAt!)}'),
                  const SizedBox(height: 18),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Progress',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 10),
                                if (booking.isActive ||
                                    booking.status == 'collected')
                                  _progress(booking)
                                else
                                  Text(
                                      demoOrderStatusLabel(
                                          booking.effectiveStatus),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                if (booking.effectiveStatus == 'requested' &&
                                    booking.expiresAt != null)
                                  Text(
                                      'Vendor reply due by ${_dateTime(booking.expiresAt!)}'),
                              ]))),
                  const SizedBox(height: 12),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Items',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                for (final item in booking.items)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3),
                                      child: Row(children: [
                                        Expanded(
                                            child: Text(
                                                '${item.quantity}× ${item.name}')),
                                        Text(
                                            'RM ${(item.subtotalCents / 100).toStringAsFixed(2)}'),
                                      ])),
                                const Divider(),
                                Row(children: [
                                  const Expanded(child: Text('Total')),
                                  Text(
                                      'RM ${(booking.totalCents / 100).toStringAsFixed(2)}')
                                ]),
                              ]))),
                  if (booking.hasTestPayment) ...[
                    const SizedBox(height: 12),
                    BookingPaymentCard(
                        booking: booking,
                        isVendor: widget.isVendor,
                        busy: _busy,
                        busyLabel: switch (_paymentTransition) {
                          _PaymentTransition.openingCheckout =>
                            'Opening checkout…',
                          _PaymentTransition.checkingPayment =>
                            'Checking payment…',
                          null => 'Processing…',
                        },
                        onPay: () => _runPaymentTransition(
                            _pay, _PaymentTransition.openingCheckout),
                        onRefresh: () => _checkPayment()),
                  ],
                  if (booking.pickupLatitude != null &&
                      booking.pickupLongitude != null)
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${booking.pickupLatitude},${booking.pickupLongitude}')),
                      icon: const Icon(Icons.place_outlined),
                      label: const Text('Self-collect location'),
                    ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 4, children: _actions(booking)),
                  const SizedBox(height: 8),
                  if (!booking.hasTestPayment)
                    const Text(
                        'This earlier booking uses payment arranged directly with the stall.'),
                ]);
              },
            ),
          ),
          if (_paymentTransition != null)
            Positioned.fill(
              child: AbsorbPointer(
                child: Material(
                  color: AppColors.background,
                  child: SafeArea(child: _paymentTransitionView()),
                ),
              ),
            ),
        ],
      );
}
````

## File: lib/features/shared/demo_orders_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_detail_screen.dart';

class DemoOrdersScreen extends StatefulWidget {
  const DemoOrdersScreen(
      {super.key, required this.isVendor, this.accountId, this.liveBookings});
  final bool isVendor;
  final String? accountId;
  final Stream<List<DemoOrder>>? liveBookings;

  @override
  State<DemoOrdersScreen> createState() => _DemoOrdersScreenState();
}

class _DemoOrdersScreenState extends State<DemoOrdersScreen> {
  late final _service = DemoOrderService();
  late final String _uid =
      widget.accountId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<DemoOrder>> _live = widget.liveBookings ??
      (widget.isVendor
          ? _service.watchVendorOrders(_uid)
          : _service.watchCustomerOrders(_uid));

  Widget _list(List<DemoOrder> bookings) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings in this section yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingSummaryCard(
          booking: booking,
          isVendor: widget.isVendor,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(
                      bookingId: booking.id, isVendor: widget.isVendor))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.isVendor ? 'Stall bookings' : 'My bookings'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E2E7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.textDark,
                    unselectedLabelColor: AppColors.textMuted,
                    tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
                  ),
                ),
              ),
            ),
          ),
          body: StreamBuilder<List<DemoOrder>>(
            stream: _live,
            builder: (context, snapshot) {
              final active =
                  snapshot.data?.where((item) => item.isActive).toList() ??
                      const <DemoOrder>[];
              final history =
                  snapshot.data?.where((item) => !item.isActive).toList() ??
                      const <DemoOrder>[];
              final unavailable = snapshot.hasError
                  ? const Center(
                      child: Text(
                          'Could not load bookings. Check your connection and try again.'))
                  : const Center(child: CircularProgressIndicator());
              return TabBarView(children: [
                snapshot.hasData ? _list(active) : unavailable,
                snapshot.hasData ? _list(history) : unavailable,
              ]);
            },
          ),
        ),
      );
}
````

## File: lib/features/shared/personal_information_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'profile_header.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.isVendor,
  });

  final String name;
  final String email;
  final bool isVendor;

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late String _name = widget.name;

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(name: _name, email: widget.email),
      ),
    );
    if (changed != true || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await AuthService().getUserData(uid);
    if (mounted) {
      setState(() => _name = data?.fullName ??
          FirebaseAuth.instance.currentUser?.displayName ??
          _name);
    }
  }

  Widget _detail(String label, String value, {bool accent = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textDark)),
            const SizedBox(height: 3),
            SelectableText(
              value.isEmpty ? 'Not available' : value,
              style: TextStyle(
                fontSize: 17,
                color: accent ? AppColors.primary : AppColors.textDark,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providers =
        user?.providerData.map((p) => p.providerId).toSet() ?? <String>{};
    final methods = providers
        .map((p) => p == 'google.com'
            ? 'Google'
            : p == 'password'
                ? 'Email and password'
                : p)
        .join(', ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SizedBox(
              height: 116,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 12,
                    child: ProfileAvatar(
                        name: _name, photoUrl: user?.photoURL, size: 100),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: ProfileTopAction(
                      label: 'Back',
                      icon: CupertinoIcons.back,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: ProfileTopAction(label: 'Edit', onTap: _edit),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 28,
                height: 1.1,
                letterSpacing: -.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isVendor ? 'Vendor account' : 'Customer account',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            const SizedBox(height: 46),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detail('name', _name),
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail('email', widget.email, accent: true),
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail(
                      'account type', widget.isVendor ? 'Vendor' : 'Customer'),
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail('sign-in method', methods),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/core/models/user_model.dart
````dart
class UserModel { // represent 1 registered user
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'customer' or 'vendor'
  final DateTime createdAt;
  final double? customerLatitude; // ni yang save custtomer location
  final double? customerLongitude; // ni jugak
  final String? customerLocationLabel; // dan ini
  final bool customerLocationIsManual;  //ini kalau manual / xletak apa2 (nu;ll)

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.customerLatitude,
    this.customerLongitude,
    this.customerLocationLabel,
    this.customerLocationIsManual = false,
  });

  bool get hasCustomerLocation => // check cust location valid or tak
      customerLatitude != null &&
      customerLongitude != null &&
      customerLatitude!.isFinite &&
      customerLongitude!.isFinite &&
      customerLatitude! >= -90 &&
      customerLatitude! <= 90 &&
      customerLongitude! >= -180 &&
      customerLongitude! <= 180;

  // Convert Firestore Document to UserModel Object
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final customerLocation = map['customerLocation'];
    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'customer',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      customerLatitude: customerLocation is Map
          ? (customerLocation['latitude'] as num?)?.toDouble()
          : null,
      customerLongitude: customerLocation is Map
          ? (customerLocation['longitude'] as num?)?.toDouble()
          : null,
      customerLocationLabel:
          customerLocation is Map ? customerLocation['label'] as String? : null,
      customerLocationIsManual: customerLocation is Map
          ? customerLocation['isManual'] == true
          : false,
    );
  }

  // Convert UserModel Object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt,
      if (hasCustomerLocation)
        'customerLocation': {
          'latitude': customerLatitude,
          'longitude': customerLongitude,
          'label': customerLocationLabel ?? 'Selected location',
          'isManual': customerLocationIsManual,
        },
    };
  }
}
````

## File: lib/features/shared/account_ui.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared spacing, fields and actions for account pages.
class AccountLayout extends StatelessWidget {
  const AccountLayout(
      {super.key,
      required this.title,
      required this.children,
      this.busy = false,
      this.background = AppColors.background});
  final String title;
  final List<Widget> children;
  final bool busy;
  final Color background;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !busy,
        child: Scaffold(
          backgroundColor: background,
          appBar: AppBar(
              title: Text(title),
              centerTitle: true,
              backgroundColor: background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  letterSpacing: 0),
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Back',
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                    onPressed: busy ? null : () => Navigator.maybePop(context),
                  ),
                ),
              )),
          body: SafeArea(
              top: false,
              child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: children)))),
        ),
      );
}

class AccountIntro extends StatelessWidget {
  const AccountIntro(
      {super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: AppColors.mint, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 30)),
        const SizedBox(height: 24),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.3)),
        const SizedBox(height: 10),
        Text(body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, height: 1.5, color: Color(0xFF707078))),
        const SizedBox(height: 32),
      ]);
}

InputDecoration accountField(String label, {Widget? suffix, String? helper}) =>
    InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      errorMaxLines: 3,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF707078), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: AppColors.primary)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: Color(0xFFB3261E))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5)),
    );

class AccountButton extends StatelessWidget {
  const AccountButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.busy = false,
      this.color = AppColors.primary});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              minimumSize: const Size(48, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28))),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600))));
}

class AccountError extends StatelessWidget {
  const AccountError(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
              liveRegion: true,
              child: Text(message!,
                  style:
                      const TextStyle(color: Color(0xFFB3261E), height: 1.4))));
}
````

## File: lib/features/shared/notification_settings_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import 'account_ui.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _enabled = true;
  bool _busy = true;
  AuthorizationStatus _systemStatus = AuthorizationStatus.notDetermined;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Sign in to manage notifications.';
        });
      }
      return;
    }
    try {
      final values = await Future.wait([
        NotificationService.instance.isEnabledForCurrentUser(),
        FirebaseMessaging.instance.getNotificationSettings(),
      ]);
      if (mounted) {
        setState(() {
          _enabled = values[0] as bool;
          _systemStatus =
              (values[1] as NotificationSettings).authorizationStatus;
          _busy = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not load notification settings.';
        });
      }
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error =
        await NotificationService.instance.setEnabledForCurrentUser(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        _enabled = value;
      } else {
        _error = error;
      }
    });
    if (error == null) {
      await _load();
    }
  }

  String get _permissionText {
    if (_systemStatus == AuthorizationStatus.authorized) {
      return 'Allowed by this device';
    }
    if (_systemStatus == AuthorizationStatus.provisional) {
      return 'Quiet notifications allowed';
    }
    if (_systemStatus == AuthorizationStatus.denied) {
      return 'Blocked in phone settings';
    }
    return 'Permission not requested';
  }

  @override
  Widget build(BuildContext context) => AccountLayout(
        title: 'Notifications',
        busy: _busy,
        background: AppColors.background,
        children: [
          Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(26)),
              child: SwitchListTile.adaptive(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                activeThumbColor: AppColors.primary,
                value: _enabled,
                onChanged: _busy ? null : _toggle,
                secondary: const Icon(Icons.notifications_active_outlined,
                    color: AppColors.primary),
                title: const Text('Stall & dish notifications',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                        'Get an alert when a followed stall opens or a followed dish is restocked.')),
              )),
          const SizedBox(height: 22),
          Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(26)),
              child: Row(children: [
                const Icon(Icons.phone_android_rounded,
                    color: Color(0xFF8E8E93)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Device permission',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(_permissionText,
                          style: const TextStyle(color: Color(0xFF707078))),
                    ])),
              ])),
          if (_systemStatus == AuthorizationStatus.denied) ...[
            const SizedBox(height: 12),
            const Text(
                'Allow notifications in your phone settings, then return to StallSeeker.',
                style: TextStyle(color: Color(0xFF707078), height: 1.4)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            AccountError(_error),
          ],
          const SizedBox(height: 18),
          const Text(
              'Notification history stays in the app even when alerts are turned off.',
              style: TextStyle(
                  fontSize: 13, height: 1.45, color: Color(0xFF8E8E93))),
        ],
      );
}
````

## File: lib/features/splash/splash_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_logo.png', width: 104, height: 104),
            const SizedBox(height: 20),
            const Text(
              'StallSeeker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find nearby food stalls, live.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/shared/legal_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'info_page.dart';

enum LegalPage { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.page});
  final LegalPage page;

  @override
  Widget build(BuildContext context) {
    final privacy = page == LegalPage.privacy;
    final sections = privacy ? _privacySections : _termSections;

    return InfoPage(
      title: privacy ? 'Privacy Policy' : 'Terms of Use',
      children: [
        const Text(
          'Last updated: 20 October 2026',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.value,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: Color(0xFF52525A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static const _privacySections = <MapEntry<String, String>>[
    MapEntry('Information we collect',
        'We store your name, email address, account type, followed stalls, search history, notification history, self-collect bookings and device notification token. Live bookings are shared between the customer and vendor through Firebase. Older same-phone demo bookings remain on that device only. Guest search history stays on the guest’s device until it is merged into a customer account after sign-in. Vendors may share their stall details and live location while using the service. New bookings use Stripe sandbox checkout. We store test payment references, amounts and payment status; card details are entered on Stripe and are not stored by StallSeeker.'),
    MapEntry('How we use it',
        'We use this information to run your account, show nearby stalls and dishes, provide search suggestions, save favourites, send stall updates and keep the service secure.'),
    MapEntry('Location',
        'Customer location is used to show nearby stalls. Vendor location may be shown to customers when the stall is active. StallSeeker does not need location when these features are not being used.'),
    MapEntry('Sharing and storage',
        'Account and app data are stored using Firebase services. We do not sell personal information. Data may be processed by service providers needed to operate the app.'),
    MapEntry('Your choices',
        'You can turn off alerts in Notification settings, remove phone permissions in device settings, or delete your StallSeeker account from the Profile page.'),
    MapEntry('Data deletion',
        'Deleting your account removes your account and related StallSeeker data. Some security or legal records may be kept only when required by law.'),
    MapEntry('Contact',
        'For privacy questions, contact the StallSeeker team at support@stallseeker.my.'),
  ];

  static const _termSections = <MapEntry<String, String>>[
    MapEntry('Service purpose',
        'StallSeeker helps customers find food stalls and helps vendors share their status, menu and location.'),
    MapEntry('Account responsibility',
        'Use correct information, protect your password and do not use another person’s account. You are responsible for activity under your account.'),
    MapEntry('Vendor information',
        'Vendors are responsible for keeping their location, opening status, menu, prices and stock information accurate.'),
    MapEntry('Prototype payments',
        'Payments and refunds use Stripe Test Mode. Use test payment details only. No real money is charged, deposited or paid out to vendors. Demo sales are simulated amounts. Payment must be confirmed before preparation; cancelled paid bookings request a simulated refund, whose status is shown in the booking.'),
    MapEntry('Acceptable use',
        'Do not misuse the service, post harmful or false content, interfere with the app, scrape private data or break applicable laws.'),
    MapEntry('Availability',
        'Stall locations, stock and opening status can change. StallSeeker cannot guarantee that every listing or live update is always correct or available.'),
    MapEntry('Account action',
        'We may limit or remove accounts that abuse the service or put other users at risk. You may delete your account from the Profile page.'),
    MapEntry('Changes and contact',
        'These terms may change as the service develops. For questions, contact support@stallseeker.my.'),
  ];
}
````

## File: lib/features/shared/manual_location_dialog.dart
````dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/place_search_service.dart';
import '../../core/widgets/ios_grouped.dart';

export '../../core/services/place_search_service.dart'
    show LocationSelection, PlaceSuggestion;

Future<LocationSelection?> showManualLocationDialog(
  BuildContext context, {
  LatLng? initialLocation,
  String title = 'Enter Location Manually',
  PlaceSearchService? placeSearch,
}) {
  return showDialog<LocationSelection>(
    context: context,
    builder: (_) => _ManualLocationDialog(
      title: title,
      initialLocation: initialLocation,
      placeSearch: placeSearch,
    ),
  );
}

Future<String> describeLocation(LatLng coordinates) async {
  final placemarks = await Geocoding()
      .placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      )
      .timeout(const Duration(seconds: 8));

  if (placemarks.isEmpty) return 'Selected location';

  return _formatPlacemark(placemarks.first);
}

String _formatPlacemark(Placemark placemark) {
  final candidates = <String?>[
    placemark.name,
    placemark.subLocality,
    placemark.locality,
    placemark.subAdministrativeArea,
    placemark.administrativeArea,
    placemark.postalCode,
    placemark.country,
  ];

  final parts = <String>[];
  final seen = <String>{};

  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';

    if (value.isNotEmpty && seen.add(value.toLowerCase())) {
      parts.add(value);
    }
  }

  return parts.isEmpty ? 'Selected location' : parts.join(', ');
}

class _ManualLocationDialog extends StatefulWidget {
  const _ManualLocationDialog({
    required this.title,
    required this.initialLocation,
    this.placeSearch,
  });

  final String title;
  final LatLng? initialLocation;
  final PlaceSearchService? placeSearch;

  @override
  State<_ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<_ManualLocationDialog> {
  final _placeController = TextEditingController();

  late final _placeSearch = widget.placeSearch ?? PlaceSearchService();

  Timer? _debounce;

  List<PlaceSuggestion> _suggestions = const [];
  LocationSelection? _selection;

  String? _errorText;
  String? _fallbackMessage;

  bool _isSearching = false;
  bool _isFetchingCoords = false;
  bool _usingDeviceFallback = false;

  int _requestId = 0;

  bool _isCurrent(int requestId) => mounted && requestId == _requestId;

  @override
  void dispose() {
    _requestId++;
    _debounce?.cancel();
    _placeController.dispose();

    if (widget.placeSearch == null) {
      _placeSearch.dispose();
    }

    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _requestId++;

    setState(() {
      _selection = null;
      _suggestions = const [];
      _errorText = null;
      _fallbackMessage = null;
      _usingDeviceFallback = false;
      _isSearching = false;
      _isFetchingCoords = false;
    });

    final query = value.trim();
    if (query.length < 2) return;

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _findSuggestions(query),
    );
  }

  Future<void> _findSuggestions(String value) async {
    _debounce?.cancel();

    final query = value.trim();
    if (!mounted || query.length < 2) return;

    final requestId = ++_requestId;

    setState(() {
      _isSearching = true;
      _isFetchingCoords = false;
      _selection = null;
      _suggestions = const [];
      _errorText = null;
      _fallbackMessage = null;
      _usingDeviceFallback = false;
    });

    var googleFailed = false;
    List<PlaceSuggestion> results = const [];

    try {
      results = await _placeSearch.search(query);
    } catch (_) {
      // The service logs the actual Google Places error.
      googleFailed = true;
    }

    if (!_isCurrent(requestId)) return;

    if (results.isNotEmpty) {
      setState(() {
        _suggestions = results.take(5).toList();
        _isSearching = false;
      });
      return;
    }

    final fallbackResults = await _findDeviceSuggestions(query, requestId);

    if (!_isCurrent(requestId)) return;

    setState(() {
      _isSearching = false;
      _usingDeviceFallback = true;
      _suggestions = fallbackResults;

      if (fallbackResults.isNotEmpty) {
        _fallbackMessage = googleFailed
            ? 'Google search is unavailable. These are limited device '
                'results; check the address before selecting.'
            : 'No Google suggestions found. Showing limited device results.';
      } else {
        _errorText = googleFailed
            ? 'Location search is unavailable. Try again or check '
                'your connection.'
            : 'No matching places found. Try a more specific name, '
                'such as Bukit Bintang, Kuala Lumpur.';
      }
    });
  }

  Future<List<PlaceSuggestion>> _findDeviceSuggestions(
    String query,
    int requestId,
  ) async {
    try {
      final searchQuery =
          query.toLowerCase().contains('malaysia') ? query : '$query, Malaysia';

      final locations = await Geocoding()
          .locationFromAddress(searchQuery)
          .timeout(const Duration(seconds: 8));

      if (!_isCurrent(requestId)) return [];

      final ordered = List<Location>.from(locations);
      final origin = widget.initialLocation;

      if (origin != null) {
        ordered.sort(
          (a, b) => _distanceSquared(a, origin)
              .compareTo(_distanceSquared(b, origin)),
        );
      }

      final suggestions = <PlaceSuggestion>[];
      final seen = <String>{};

      for (final location in ordered.take(3)) {
        if (!_isCurrent(requestId)) return [];

        final coordinates = LatLng(
          location.latitude,
          location.longitude,
        );

        String label;

        try {
          label = await describeLocation(coordinates);
        } catch (_) {
          label = '$query '
              '(${coordinates.latitude.toStringAsFixed(5)}, '
              '${coordinates.longitude.toStringAsFixed(5)})';
        }

        if (!_isCurrent(requestId)) return [];

        if (seen.add(label.toLowerCase())) {
          suggestions.add(
            PlaceSuggestion(
              placeId: '',
              primaryText: label,
              secondaryText: 'Device result',
              fullText: label,
              coordinates: coordinates,
            ),
          );
        }
      }

      return suggestions;
    } catch (error) {
      debugPrint('Device location search failed: $error');
      return [];
    }
  }

  double _distanceSquared(Location location, LatLng origin) {
    final latitude = location.latitude - origin.latitude;
    final longitude = location.longitude - origin.longitude;

    return latitude * latitude + longitude * longitude;
  }

  Future<void> _handleSuggestionTap(
    PlaceSuggestion suggestion,
  ) async {
    _debounce?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();

    final requestId = ++_requestId;

    if (suggestion.coordinates != null) {
      _selectSuggestion(
        LocationSelection(
          coordinates: suggestion.coordinates!,
          label: suggestion.fullText,
        ),
      );
      return;
    }

    setState(() {
      _selection = null;
      _isSearching = false;
      _isFetchingCoords = true;
      _errorText = null;
    });

    try {
      final coordinates = await _placeSearch.getCoordinates(suggestion.placeId);

      if (!_isCurrent(requestId)) return;

      if (coordinates == null) {
        setState(() {
          _isFetchingCoords = false;
          _errorText =
              'Could not load this place. Please select another result.';
        });
        return;
      }

      _selectSuggestion(
        LocationSelection(
          coordinates: coordinates,
          label: suggestion.fullText,
        ),
      );
    } catch (_) {
      if (!_isCurrent(requestId)) return;

      setState(() {
        _isFetchingCoords = false;
        _errorText = 'Could not load location details. Please try again.';
      });
    }
  }

  void _selectSuggestion(LocationSelection selection) {
    if (!mounted) return;

    setState(() {
      _selection = selection;
      _isSearching = false;
      _isFetchingCoords = false;
      _errorText = null;
    });
  }

  void _submit() {
    final selection = _selection;
    if (selection == null) return;

    _requestId++;
    _debounce?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.pop(context, selection);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSearching || _isFetchingCoords;

    return AlertDialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      scrollable: true,
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search for a place in Malaysia, then select its address.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _placeController,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: _findSuggestions,
              decoration: InputDecoration(
                labelText: 'Search location',
                hintText: 'Bukit Bintang, Kuala Lumpur',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: busy
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppGroupedCard(
                dividerIndent: 56,
                children: [
                  for (final suggestion in _suggestions)
                    _suggestionTile(suggestion),
                ],
              ),
            ],
            if (_isFetchingCoords)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Getting location details…',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            if (_fallbackMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _fallbackMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.closedRed,
                ),
              ),
            ],
            if (_usingDeviceFallback && !busy)
              TextButton(
                onPressed: () => _findSuggestions(_placeController.text),
                child: const Text('Retry Google search'),
              ),
            if (_selection != null) ...[
              const SizedBox(height: 12),
              Text(
                'Selected: ${_selection!.label}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
            if (!_usingDeviceFallback && _suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Powered by Google Places',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            _requestId++;
            _debounce?.cancel();
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy || _selection == null ? null : _submit,
          child: const Text('Use location'),
        ),
      ],
    );
  }

  Widget _suggestionTile(PlaceSuggestion suggestion) {
    final selected = _selection?.label == suggestion.fullText;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      selected: selected,
      leading: const AppIconTile(
        icon: Icons.location_on_outlined,
        color: AppColors.primary,
      ),
      title: Text(
        suggestion.primaryText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: suggestion.secondaryText.isEmpty
          ? null
          : Text(
              suggestion.secondaryText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
            )
          : null,
      onTap: _isSearching || _isFetchingCoords
          ? null
          : () => _handleSuggestionTap(suggestion),
    );
  }
}
````

## File: lib/features/shared/saved_locations_sheet.dart
````dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/ios_grouped.dart';
import '../../core/models/saved_location.dart';
import '../../core/services/saved_location_service.dart';
import 'manual_location_dialog.dart';
import 'pin_location_screen.dart';
import '../../core/widgets/app_dropdown.dart';

Future<LocationSelection?> showSavedLocationsSheet(
  BuildContext context, {
  required LatLng initialLocation,
  String? initialType,
}) =>
    showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (_) => _SavedLocationsSheet(
          initialLocation: initialLocation, initialType: initialType),
    );

class _SavedLocationsSheet extends StatefulWidget {
  const _SavedLocationsSheet({required this.initialLocation, this.initialType});
  final LatLng initialLocation;
  final String? initialType;

  @override
  State<_SavedLocationsSheet> createState() => _SavedLocationsSheetState();
}

class _SavedLocationsSheetState extends State<_SavedLocationsSheet> {
  final _service = SavedLocationService();
  List<SavedLocation> _locations = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final locations = await _service.load();
      if (mounted) {
        setState(() {
          _locations = locations;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Could not load saved places. Check your connection and retry.';
        });
      }
    }
  }

  Future<void> _edit({required bool home, SavedLocation? existing}) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search address'),
            onTap: () => Navigator.pop(context, 'search')),
        ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Pin on map'),
            subtitle: const Text('Choose the exact spot'),
            onTap: () => Navigator.pop(context, 'pin')),
        ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Use current search location'),
            onTap: () => Navigator.pop(context, 'current')),
      ])),
    );
    if (!mounted || method == null) return;
    final initial = existing?.coordinates ?? widget.initialLocation;
    LocationSelection? selection;
    if (method == 'search') {
      selection = await showManualLocationDialog(context,
          initialLocation: initial,
          title: home ? 'Set Home location' : 'Set custom location');
    } else if (method == 'pin') {
      selection = await Navigator.push<LocationSelection>(
          context,
          MaterialPageRoute(
              builder: (_) => PinLocationScreen(initialLocation: initial)));
    } else {
      var label = '${widget.initialLocation.latitude.toStringAsFixed(5)}, '
          '${widget.initialLocation.longitude.toStringAsFixed(5)}';
      try {
        label = await describeLocation(widget.initialLocation);
      } catch (_) {
        // Coordinates still identify the exact search location offline.
      }
      selection =
          LocationSelection(coordinates: widget.initialLocation, label: label);
    }
    if (!mounted || selection == null) return;
    final name = home ? 'Home' : await _name(existing?.name ?? '');
    if (!mounted || name == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.save(
          name: name,
          address: selection.label,
          coordinates: selection.coordinates,
          isHome: home,
          id: existing?.id);
      await _load();
    } catch (error, stackTrace) {
      debugPrint('Saved place failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = 'Could not save this place:\n$error';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<String?> _name(String initial) async {
    final controller = TextEditingController(text: initial);
    final key = GlobalKey<FormState>();
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Name this place'),
              content: Form(
                  key: key,
                  child: TextFormField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Work, campus, favourite area'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a name for this place.'
                        : null,
                  )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (key.currentState!.validate()) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    child: const Text('Save place')),
              ],
            ));
    // Dispose after the closing route has finished using the text field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    return name;
  }

  Future<void> _delete(SavedLocation location) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.delete(location.id);
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not remove this place. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _pin(SavedLocation location) => ListTile(
        leading: AppIconTile(
            icon: location.isHome ? Icons.home_rounded : Icons.place_rounded,
            color:
                location.isHome ? AppColors.primary : const Color(0xFFAD55E8)),
        title: Text(location.name),
        subtitle: Text(location.address,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap:
            _saving ? null : () => Navigator.pop(context, location.selection),
        trailing: AppDropdown<String>(
          iconOnly: true,
          icon: Icons.more_vert,
          hint: 'Manage ${location.name}',
          options: const {
            'edit': 'Edit place',
            'delete': 'Remove place',
          },
          onChanged: _saving
              ? null
              : (value) {
                  if (value == 'edit') {
                    _edit(
                      home: location.isHome,
                      existing: location,
                    );
                  } else {
                    _delete(location);
                  }
                },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final homes = _locations.where((location) => location.isHome).toList();
    final custom = _locations.where((location) => !location.isHome).toList();
    return SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(
                    widget.initialType == 'home'
                        ? 'Home location'
                        : widget.initialType == 'custom'
                            ? 'Custom locations'
                            : 'Saved places',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Choose a place to search for nearby stalls.',
                    style: TextStyle(color: Color(0xFF8E8E93))),
                const SizedBox(height: 24),
                if (_loading || _saving) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        Expanded(child: Text(_error!)),
                        TextButton(onPressed: _load, child: const Text('Retry'))
                      ])),
                if (!_loading) ...[
                  _group('HOME', [
                    if (homes.isNotEmpty)
                      _pin(homes.first)
                    else
                      ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: const Text('Save Home location'),
                          subtitle: const Text(
                              'Keep your home pin for quick searches'),
                          onTap: _saving ? null : () => _edit(home: true)),
                  ]),
                  const SizedBox(height: 24),
                  _group('CUSTOM PLACES', [
                    ...custom.map(_pin),
                    ListTile(
                        leading: const Icon(Icons.add_location_alt_outlined),
                        title: const Text('Add custom location'),
                        onTap: _saving ? null : () => _edit(home: false)),
                  ]),
                ],
              ],
            )));
  }

  Widget _group(String label, List<Widget> rows) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        const SizedBox(height: 10),
        Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i != 0)
                  const Divider(
                      height: .5, thickness: .5, indent: 60, endIndent: 16),
                rows[i],
              ],
            ])),
      ]);
}
````

## File: lib/core/services/menu_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// customer tengok menu vendor
  Stream<List<MenuItemModel>> getMenuItems(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

// create id baru bila add menu baru
  String newMenuItemId(String vendorId) {
    return _db.collection('vendors').doc(vendorId).collection('menu').doc().id;
  }

// validate dan save menu
  Future<void> addMenuItem(
    String vendorId,
    String name,
    double price, {
    String? itemId,
    String? imageUrl,
    String section = 'Main menu',
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) { throw ArgumentError('Invalid dish'); }
    final docRef = itemId != null
        ? _db.collection('vendors').doc(vendorId).collection('menu').doc(itemId)
        : _db.collection('vendors').doc(vendorId).collection('menu').doc();

    final newItem = MenuItemModel(
      itemId: docRef.id,
      name: name,
      price: price,
      status: 'available',
      imageUrl: imageUrl ?? '',
      section: section,
    );

    await docRef.set(newItem.toMap()).timeout(const Duration(seconds: 15));
  }

// update menu item (name, price, image)
  Future<void> updateMenuItem(
    String vendorId,
    String itemId,
    String name,
    double price, {
    String? imageUrl,
    String section = 'Main menu',
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) { throw ArgumentError('Invalid dish'); }
    final data = <String, dynamic>{
      'name': name,
      'price': price,
      'section': section,
    };
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }

    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update(data).timeout(const Duration(seconds: 15));
  }
// change menu aiavlaibility
  Future<void> updateItemStatus(
      String vendorId, String itemId, String newStatus) async {
    if (!{'available', 'low_stock', 'out_of_stock'}.contains(newStatus)) { throw ArgumentError('Invalid status'); }
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update({'status': newStatus, 'statusUpdatedAt': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 15));
  }

  // Delete item
  Future<void> deleteMenuItem(String vendorId, String itemId) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .delete().timeout(const Duration(seconds: 15));
  }
}
````

## File: lib/core/services/notification_service.dart
````dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/vendor_model.dart';
import 'vendor_service.dart';
import '../../features/customer/vendor_details/vendor_details_screen.dart';
import '../../features/shared/booking_detail_screen.dart';

// Runs in its own isolate when a push arrives while the app is backgrounded
// or fully closed. Android shows the system notification on its own from
// the message's payload -- this only needs to exist so FCM has something
// to call.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final VendorService _vendorService = VendorService();

  static const _channel = AndroidNotificationChannel(
    'stallseeker_channel',
    'StallSeeker Notifications',
    description: 'Stall, dish, and self-collect booking alerts.',
    importance: Importance.high,
  );

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;
  String? _syncedUid;
  String? _configuredUid;
  String? _configuredRole;
  String? _pendingVendorId;
  String? _pendingItemId;
  String? _pendingBookingId;
  String? _pendingBookingRecipient;
  bool _pendingBookingVendor = false;
  bool _navigationReady = false;
  Future<void> _tokenWork = Future<void>.value();

  Future<void> _queueTokenSave(String uid, String token) {
    _tokenWork = _tokenWork.catchError((Object _) {}).then((_) async {
      if (_syncedUid == uid && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _saveToken(uid, token);
      }
    });
    return _tokenWork;
  }

  void setNavigationReady(bool ready) {
    _navigationReady = ready;
    if (ready && _pendingBookingId != null) {
      final id = _pendingBookingId!;
      final recipient = _pendingBookingRecipient;
      final isVendor = _pendingBookingVendor;
      _pendingBookingId = null;
      _pendingBookingRecipient = null;
      unawaited(_openBooking(id, recipientId: recipient, isVendor: isVendor));
    }
    if (ready && _pendingVendorId != null) {
      final id = _pendingVendorId!;
      final itemId = _pendingItemId;
      _pendingVendorId = null;
      _pendingItemId = null;
      unawaited(_openVendorDetails(id, itemId: itemId));
    }
  }

  // One-time setup: creates the notification channel and wires up listeners
  // for taps in every app state. Permission is requested only after the
  // signed-in account is confirmed.
  // (foreground, background, terminated). Safe to call more than once.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) {
      return;
    }

    _navigatorKey = navigatorKey;

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _openPayload(payload);
        }
      },
    );

    _initialized = true;

    // FCM does not show a system notification by itself while the app is
    // in the foreground, so display one manually using the same channel.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final vendorId = message.data['vendorId'];
      final bookingId = message.data['bookingId'];
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: bookingId is String
              ? jsonEncode({
                  'bookingId': bookingId,
                  'recipientId': message.data['recipientId'],
                  'role': message.data['role'],
                })
              : vendorId == null
                  ? null
                  : jsonEncode({
                      'vendorId': vendorId,
                      if (message.data['itemId'] is String)
                        'itemId': message.data['itemId'],
                    }),
        );
      }
    });

    // App was backgrounded and the user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final bookingId = message.data['bookingId'];
      if (bookingId is String) {
        unawaited(_openBooking(bookingId,
            recipientId: message.data['recipientId'] as String?,
            isVendor: message.data['role'] == 'vendor'));
        return;
      }
      final vendorId = message.data['vendorId'];
      if (vendorId != null) {
        _openVendorDetails(vendorId,
            itemId: message.data['itemId'] is String
                ? message.data['itemId'] as String
                : null);
      }
    });

    // App was fully closed and got launched by tapping the notification.
    final initialMessage = await _messaging.getInitialMessage();
    final initialBookingId = initialMessage?.data['bookingId'];
    if (initialBookingId is String) {
      unawaited(_openBooking(initialBookingId,
          recipientId: initialMessage?.data['recipientId'] as String?,
          isVendor: initialMessage?.data['role'] == 'vendor'));
      return;
    }
    final vendorId = initialMessage?.data['vendorId'];
    if (vendorId != null) {
      _openVendorDetails(vendorId,
          itemId: initialMessage!.data['itemId'] is String
              ? initialMessage.data['itemId'] as String
              : null);
    }
  }

  Future<void> configureForRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    if (_configuredUid == user.uid && _configuredRole == role) {
      return;
    }
    _configuredUid = user.uid;
    _configuredRole = role;

    if (role != 'customer' && role != 'vendor') {
      _syncedUid = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      await _tokenWork
          .timeout(const Duration(seconds: 5))
          .catchError((Object _) {});
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
        await _messaging.deleteToken().timeout(const Duration(seconds: 5));
        await _localNotifications.cancelAll();
      } catch (_) {
        debugPrint('Could not disable notifications.');
        _configuredUid = null;
        _configuredRole = null;
      }
      return;
    }

    try {
      if (!await isEnabledForCurrentUser()) {
        await _removeCurrentDeviceToken(user);
        return;
      }
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await _removeCurrentDeviceToken(user);
        return;
      }
      _syncedUid = null;
      await syncTokenForCurrentUser(skipPreferenceCheck: true);
    } catch (_) {
      debugPrint('Could not configure notifications.');
      _configuredUid = null;
      _configuredRole = null;
    }
  }

  // Fetches this device's FCM token and saves it on the signed-in account,
  // and keeps it updated if it ever rotates.
  Future<void> syncTokenForCurrentUser(
      {bool skipPreferenceCheck = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || _syncedUid == user.uid) {
      return;
    }
    if (_configuredRole != null &&
        _configuredRole != 'customer' &&
        _configuredRole != 'vendor') {
      return;
    }
    if (!skipPreferenceCheck && !await isEnabledForCurrentUser()) {
      await _removeCurrentDeviceToken(user);
      return;
    }
    _syncedUid = user.uid;
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      final uid = _syncedUid;
      if (uid != null) {
        unawaited(_queueTokenSave(uid, token).catchError((Object e) {
          debugPrint('Could not refresh notification registration.');
        }));
      }
    });
    try {
      final token =
          await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        await _queueTokenSave(user.uid, token);
      }
    } catch (_) {
      _syncedUid = null;
      debugPrint('Notification registration unavailable.');
    }
  }

  Future<bool> isEnabledForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return false;
    }
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return profile.data()?['notificationsEnabled'] != false;
  }

  Future<String?> setEnabledForCurrentUser(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return 'Sign in to manage notifications.';
    }
    if (_configuredRole != 'customer' && _configuredRole != 'vendor') {
      return 'Sign in to manage notifications.';
    }
    try {
      if (enabled) {
        final settings = await _messaging.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          return 'Notifications are blocked in your phone settings.';
        }
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'notificationsEnabled': enabled,
        if (!enabled) 'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      if (enabled) {
        _syncedUid = null;
        await syncTokenForCurrentUser(skipPreferenceCheck: true);
      } else {
        await _removeCurrentDeviceToken(user);
        await _localNotifications.cancelAll();
      }
      return null;
    } catch (_) {
      return 'Could not update notification settings. Please try again.';
    }
  }

  Future<void> _removeCurrentDeviceToken(User user) async {
    _syncedUid = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    await _tokenWork
        .timeout(const Duration(seconds: 5))
        .catchError((Object _) {});
    try {
      final token =
          await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        final ref =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(ref);
          if (doc.data()?['fcmToken'] == token) {
            tx.update(ref, {'fcmToken': FieldValue.delete()});
          }
        }).timeout(const Duration(seconds: 5));
      }
    } finally {
      await _messaging
          .deleteToken()
          .timeout(const Duration(seconds: 5))
          .catchError((Object _) {});
    }
  }

  Future<void> clearCurrentDevice() async {
    _navigationReady = false;
    _pendingVendorId = null;
    _pendingItemId = null;
    _pendingBookingId = null;
    _pendingBookingRecipient = null;
    _configuredUid = null;
    _configuredRole = null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    try {
      await _removeCurrentDeviceToken(user);
    } catch (_) {
      debugPrint('Could not remove notification registration.');
    } finally {
      await _localNotifications.cancelAll();
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true)).timeout(const Duration(seconds: 5));
  }

  void _openPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['bookingId'] is String) {
        unawaited(_openBooking(data['bookingId'] as String,
            recipientId: data['recipientId'] as String?,
            isVendor: data['role'] == 'vendor'));
        return;
      }
      if (data is Map && data['vendorId'] is String) {
        unawaited(_openVendorDetails(data['vendorId'] as String,
            itemId:
                data['itemId'] is String ? data['itemId'] as String : null));
        return;
      }
    } on FormatException {
      // Existing notifications used the plain vendor ID as their payload.
    }
    unawaited(_openVendorDetails(payload));
  }

  Future<void> _openVendorDetails(String vendorId, {String? itemId}) async {
    final navState = _navigatorKey?.currentState;
    if (!_navigationReady || navState == null) {
      _pendingVendorId = vendorId;
      _pendingItemId = itemId;
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final VendorModel? vendor = await _vendorService.getVendorProfile(vendorId);
    if (vendor == null ||
        !_navigationReady ||
        FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }

    navState.push(
      MaterialPageRoute(
          builder: (_) =>
              VendorDetailsScreen(vendor: vendor, initialDishId: itemId)),
    );
  }

  Future<void> _openBooking(String bookingId,
      {String? recipientId, required bool isVendor}) async {
    final navState = _navigatorKey?.currentState;
    if (!_navigationReady || navState == null) {
      _pendingBookingId = bookingId;
      _pendingBookingRecipient = recipientId;
      _pendingBookingVendor = isVendor;
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || (recipientId != null && uid != recipientId)) return;
    navState.push(MaterialPageRoute(
        builder: (_) =>
            BookingDetailScreen(bookingId: bookingId, isVendor: isVendor)));
  }
}
````

## File: lib/core/services/vendor_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/vendor_model.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _vendorsRef => _firestore.collection('vendors');

// read store id
  Future<VendorModel?> getVendorProfile(String vendorId) async {
    try {
      DocumentSnapshot doc = await _vendorsRef.doc(vendorId).get();
      if (doc.exists && doc.data() != null) {
        return VendorModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching vendor profile: $e');
      return null;
    }
  }

// update stall infroamtion
  Future<void> saveVendorProfile(VendorModel vendor) async {
    try {
      await _vendorsRef.doc(vendor.vendorId).set(
            vendor.toProfileMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error saving vendor profile: $e');
      rethrow;
    }
  }

// open/closed
  Future<void> toggleStallStatus(String vendorId, bool isOpen) async {
    try {
      await _vendorsRef.doc(vendorId).set({
        'vendorId': vendorId,
        'isOpen': isOpen,
        if (!isOpen) 'locationSharingActive': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error toggling stall status: $e');
      rethrow;
    }
  }

// update location
  Future<void> updateVendorLocation(
    String vendorId,
    double latitude,
    double longitude,
    {bool sharingActive = true}
  ) async {
    try {
      await _vendorsRef.doc(vendorId).set({
        'vendorId': vendorId,
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'locationSharingActive': sharingActive,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating vendor location: $e');
      rethrow;
    }
  }

  Stream<VendorModel?> watchVendorProfile(String vendorId) {
    return _vendorsRef.doc(vendorId).snapshots().map((doc) =>
        doc.exists && doc.data() != null
            ? VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
            : null);
  }

  Future<void> setSelfCollectEnabled(String vendorId, bool enabled) =>
      _vendorsRef.doc(vendorId).update({'selfCollectEnabled': enabled});

  Stream<List<VendorModel>> getOpenVendors() {
    return _vendorsRef.where('isOpen', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<VendorModel>> getAllVendors() {
    return _vendorsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
}
````

## File: lib/features/customer/notifications/customer_notifications_screen.dart
````dart
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  final _history = NotificationHistoryService();
  final _vendors = VendorService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  late Stream<List<NotificationModel>> _stream;
  final Set<String> _opening = {};
  final Set<String> _removedIds = {};
  int _limit = 50;
  bool _marking = false;
  bool _onlyUnread = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final uid = _uid;
    _stream =
        uid == null || FirebaseAuth.instance.currentUser?.isAnonymous == true
            ? Stream.value(<NotificationModel>[])
            : _history.watch(uid, limit: _limit);
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _open(NotificationModel item) async {
    final uid = _uid;
    if (uid == null || _opening.contains(item.id)) {
      return;
    }
    setState(() => _opening.add(item.id));
    try {
      if (!item.isRead) {
        try {
          await _history.markRead(uid, item.id);
        } catch (_) {
          _message('Could not mark this alert as read.');
        }
      }
      if (item.vendorId.isEmpty) {
        _message('This alert has no stall link.');
        return;
      }
      final vendor = await _vendors
          .getVendorProfile(item.vendorId)
          .timeout(const Duration(seconds: 10));
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }
      if (vendor == null) {
        _message('This stall is unavailable or could not be loaded.');
        return;
      }
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VendorDetailsScreen(
                  vendor: vendor, initialDishId: item.itemId)));
    } catch (_) {
      _message('Could not open the stall. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _opening.remove(item.id));
      }
    }
  }

  Future<void> _markRead(List<NotificationModel> items) async {
    final uid = _uid;
    if (uid == null || _marking) {
      return;
    }
    setState(() => _marking = true);
    try {
      await _history.markDisplayedRead(uid, items);
    } catch (_) {
      _message('Could not mark alerts as read. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _marking = false);
      }
    }
  }

  Future<void> _remove(NotificationModel item) async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _removedIds.add(item.id));
    try {
      await _history.remove(uid, item.id);
    } catch (_) {
      if (mounted) {
        setState(() => _removedIds.remove(item.id));
        _message('Could not remove this notification. Please retry.');
      }
    }
  }

  String _date(DateTime? value) {
    if (value == null) {
      return 'Date unavailable';
    }
    final local = value.toLocal();
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '${local.day}/${local.month}/${local.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final horizontalInset =
        math.max(16.0, (MediaQuery.sizeOf(context).width - 960) / 2);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return _empty('Your stall updates, in one place',
          'Sign in and follow stalls or dishes to keep their updates here.',
          action: TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in')));
    }
    return ColoredBox(
        color: AppColors.background,
        child: StreamBuilder<List<NotificationModel>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _errorState(snapshot.error!);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = (snapshot.data ?? [])
                .where((item) => !_removedIds.contains(item.id))
                .toList();
            final visible =
                _onlyUnread ? all.where((item) => !item.isRead).toList() : all;
            return RefreshIndicator(
                onRefresh: () async {
                  setState(_listen);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      horizontalInset, 20, horizontalInset, 112),
                  children: [
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          CupertinoSlidingSegmentedControl<bool>(
                            backgroundColor: const Color(0xFFE2E2E7),
                            thumbColor: Colors.white,
                            groupValue: _onlyUnread,
                            children: const {
                              false: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 18),
                                  child: Text('All')),
                              true: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 18),
                                  child: Text('Unread')),
                            },
                            onValueChanged: (value) {
                              if (value != null) {
                                setState(() => _onlyUnread = value);
                              }
                            },
                          ),
                          TextButton(
                              onPressed:
                                  _marking || !all.any((item) => !item.isRead)
                                      ? null
                                      : () => _markRead(all),
                              child: Text(_marking
                                  ? 'Updating…'
                                  : 'Mark shown as read')),
                        ]),
                    const Padding(
                        padding: EdgeInsets.fromLTRB(8, 16, 8, 12),
                        child: Text('STALL UPDATES',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF8E8E93)))),
                    if (visible.isEmpty)
                      Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(children: [
                            const Icon(Icons.notifications_none_rounded,
                                size: 42, color: Color(0xFF8E8E93)),
                            const SizedBox(height: 12),
                            Text(
                                _onlyUnread
                                    ? 'No unread updates in this list'
                                    : 'No notifications yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text(
                                'Updates appear here when a followed stall opens or a followed dish is restocked.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF8E8E93))),
                          ]))
                    else
                      for (final item in visible) ...[
                        Dismissible(
                          key: ValueKey('notification-${item.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: AppColors.closedRed,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    color: Colors.white),
                                SizedBox(width: 6),
                                Text('Remove',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          onDismissed: (_) => _remove(item),
                          child: _tile(item),
                        ),
                        const SizedBox(height: 12),
                      ],
                    if (all.length >= _limit)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton(
                              onPressed: () => setState(() {
                                    _limit += 50;
                                    _listen();
                                  }),
                              child: const Text('Load older updates'))),
                  ],
                ));
          },
        ));
  }

  Widget _tile(NotificationModel item) => Material(
        color: item.isRead ? Colors.white : const Color(0xFFFFF5EC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: item.isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: .18),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          leading: AppIconTile(
              icon: item.type == 'dish_available'
                  ? Icons.restaurant_rounded
                  : Icons.storefront_rounded,
              color: item.isRead ? const Color(0xFF949499) : AppColors.primary),
          title: Text(item.title,
              style: TextStyle(
                  fontSize: 17,
                  letterSpacing: 0,
                  fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w500)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.body.isNotEmpty)
                      Text(item.body,
                          style:
                              const TextStyle(fontSize: 14, letterSpacing: 0)),
                    const SizedBox(height: 5),
                    Text(_date(item.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8E8E93))),
                  ])),
          trailing: _opening.contains(item.id)
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(item.isRead ? Icons.chevron_right : Icons.circle,
                  size: item.isRead ? 20 : 8,
                  color: item.isRead
                      ? const Color(0xFFAEAEB2)
                      : AppColors.primary),
          onTap: () => _open(item),
        ),
      );

  Widget _errorState(Object error) {
    final code = error is FirebaseException ? error.code : 'unknown';
    // Preserve the real error in the debug console instead of blaming Wi-Fi.
    debugPrint('Notification history [$code]: $error');
    String title;
    String body;
    switch (code) {
      case 'permission-denied':
        title = 'Notification access is blocked';
        body =
            'Your account cannot read notification history yet. Please contact support.';
        break;
      case 'unauthenticated':
        title = 'Please sign in again';
        body =
            'Your session has expired. Sign out and sign in to load your updates.';
        break;
      case 'unavailable':
      case 'deadline-exceeded':
        title = 'Cannot reach notifications';
        body = 'Check your connection, then try again.';
        break;
      case 'failed-precondition':
        title = 'Notifications are not ready';
        body =
            'Notification history needs a service update. Please contact support.';
        break;
      default:
        title = 'Could not load notifications';
        body =
            'Try again. If this continues, share the error code with support.';
    }
    return _empty(title, body,
        action: Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton(
              onPressed: () => setState(_listen), child: const Text('Retry')),
          SelectableText('Error: $code',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ]));
  }

  Widget _empty(String title, String body, {Widget? action}) => Center(
          child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_none_rounded,
              size: 44, color: Color(0xFF8E8E93)),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          if (action != null) action,
        ]),
      ));
}
````

## File: lib/core/constants/app_colors.dart
````dart
import 'package:flutter/material.dart';

class AppColors {
  // Colors sampled from the StallSeeker logo.
  static const Color logoOrange = Color(0xFFFB8D24);
  static const Color logoRedOrange = Color(0xFFFA3A1E);

  // A darker orange for readable text and selected navigation icons.
  static const Color primary = Color(0xFFB83D11);
  static const Color primaryLight = logoOrange;

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [logoOrange, logoRedOrange],
  );

  static const Color background = Color(0xFFFFF8F2);
  static const Color cardColor = Colors.white;

  // Keep this name because existing screens already use AppColors.mint.
  static const Color mint = Color(0xFFFFF0E5);

  static const Color border = Color(0xFFF0E1D6);
  static const Color textDark = Color(0xFF241E1B);
  static const Color textMuted = Color(0xFF7D706B);

  // Status colors retain their meanings.
  static const Color openGreen = Color(0xFF2E7D32);
  static const Color closedRed = Color(0xFFC62828);
  static const Color limitedYellow = Color(0xFFF57F17);
}
````

## File: lib/core/models/vendor_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stall_schedule.dart';

class VendorModel {
  // file ni represent 1 stall
  final String vendorId;
  final String stallName;
  final String description;
  final String category;
  final String openingHours;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String phoneNumber;
  final Map<int, List<StallHoursInterval>> weeklyHours;
  final List<TemporaryClosure> temporaryClosures;
  final DateTime? locationUpdatedAt;
  final bool locationSharingActive;
  final bool selfCollectEnabled;

  bool get isTemporarilyClosed =>
      temporaryClosures.any((c) => c.contains(DateTime.now()));
  bool get isOpenNow => isOpen && !isTemporarilyClosed;
  bool isScheduledOpenAt(DateTime instant) =>
      isWithinStallSchedule(instant, weeklyHours, temporaryClosures);

  String get hoursToday {
    final day = malaysiaTime(DateTime.now()).weekday;
    if (weeklyHours.isEmpty) return openingHours;
    final intervals = weeklyHours[day] ?? [];
    if (intervals.isEmpty) return 'Closed today';
    return intervals
        .map((i) => '${formatStallTime(i.openMinute)} – '
            '${formatStallTime(i.closeMinute)}${i.closeMinute < i.openMinute ? ' (next day)' : ''}')
        .join(', ');
  }

  bool get hasValidLocation =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  bool get hasFreshLocation {
    // check kalau stall ada usable coordinates
    final updated = locationUpdatedAt;
    if (!locationSharingActive || updated == null) {
      return false;
    }
    final age = DateTime.now().difference(updated);
    return !age.isNegative && age < const Duration(minutes: 2);
  }

  // location update setiap 15sec, tapi kalau vendor punya gps fail/phone off lebih dua minit stall tutup

  VendorModel({
    required this.vendorId,
    required this.stallName,
    required this.description,
    required this.category,
    required this.openingHours,
    this.isOpen = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imageUrl = '',
    this.phoneNumber = '',
    this.weeklyHours = const {},
    this.temporaryClosures = const [],
    this.locationUpdatedAt,
    this.locationSharingActive = false,
    this.selfCollectEnabled = false,
  });

  /// Editable information only. Operational state belongs to the selling session.
  Map<String, dynamic> toProfileMap() => {
        'vendorId': vendorId,
        'stallName': stallName,
        'description': description,
        'category': category,
        'openingHours': openingHours,
        'imageUrl': imageUrl,
        'phoneNumber': phoneNumber,
        'weeklyHours': serializeWeeklyHours(weeklyHours),
        'temporaryClosures': temporaryClosures.map((c) => c.toMap()).toList(),
      };

  // Convert VendorModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'stallName': stallName,
      'description': description,
      'category': category,
      'openingHours': openingHours,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'weeklyHours': serializeWeeklyHours(weeklyHours),
      'temporaryClosures': temporaryClosures.map((c) => c.toMap()).toList(),
      'selfCollectEnabled': selfCollectEnabled,
    };
  }

  // Create VendorModel from Firestore Document Snapshot
  factory VendorModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VendorModel(
      vendorId: documentId,
      stallName: map['stallName'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      openingHours: map['openingHours'] ?? '',
      isOpen: map['isOpen'] ?? false,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      weeklyHours: parseWeeklyHours(map['weeklyHours']),
      temporaryClosures: (map['temporaryClosures'] is List
              ? map['temporaryClosures'] as List
              : const [])
          .map(TemporaryClosure.fromMap)
          .whereType<TemporaryClosure>()
          .toList(),
      locationUpdatedAt: (map['locationUpdatedAt'] as Timestamp?)?.toDate(),
      locationSharingActive: map['locationSharingActive'] == true,
      selfCollectEnabled: map['selfCollectEnabled'] == true,
    );
  }

  // CopyWith method for easy state updates
  VendorModel copyWith({
    String? stallName,
    String? description,
    String? category,
    String? openingHours,
    bool? isOpen,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? phoneNumber,
    Map<int, List<StallHoursInterval>>? weeklyHours,
    List<TemporaryClosure>? temporaryClosures,
    bool? selfCollectEnabled,
  }) {
    return VendorModel(
      vendorId: vendorId,
      stallName: stallName ?? this.stallName,
      description: description ?? this.description,
      category: category ?? this.category,
      openingHours: openingHours ?? this.openingHours,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      temporaryClosures: temporaryClosures ?? this.temporaryClosures,
      locationUpdatedAt: locationUpdatedAt,
      locationSharingActive: locationSharingActive,
      selfCollectEnabled: selfCollectEnabled ?? this.selfCollectEnabled,
    );
  }
}
````

## File: lib/features/auth/screens/welcome_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onGuestAccessGranted});

  final VoidCallback? onGuestAccessGranted;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _auth = AuthService();
  bool _busy = false;
  bool _loginOpen = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null && error != 'cancelled') {
      _showError(error);
    }
  }

  Future<void> _guest() async {
    if (_busy) {
      return;
    }

    if (_auth.currentUser?.isAnonymous == true) {
      widget.onGuestAccessGranted?.call();
      return;
    }

    setState(() => _busy = true);
    final error = await _auth.signInAsGuest();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      _showError(error);
      return;
    }

    widget.onGuestAccessGranted?.call();
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), backgroundColor: const Color(0xFFB3261E)));

  Future<void> _openLogin() async {
    setState(() => _loginOpen = true);
    await showLoginSheet(context);
    if (mounted) {
      setState(() => _loginOpen = false);
    }
  }

  Widget _button(
          {required Widget icon,
          required String label,
          required Color color,
          required Color textColor,
          required VoidCallback? onPressed}) =>
      SizedBox(
        height: 58,
        child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textColor,
                disabledBackgroundColor: color.withValues(alpha: .65),
                disabledForegroundColor: textColor.withValues(alpha: .88),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              icon,
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ])),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF18181A),
        body: Stack(children: [
          Positioned.fill(
              child: ColoredBox(
                  color: Colors.white,
                  child: SafeArea(
                      bottom: false,
                      child: Stack(children: [
                        if (!_loginOpen)
                          Positioned(
                              top: 12,
                              right: 18,
                              child: IconButton(
                                  tooltip: 'Continue as guest',
                                  onPressed: _busy ? null : _guest,
                                  style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFEAEAEC)),
                                  icon: const Icon(Icons.close_rounded,
                                      color: Color(0xFF73737A)))),
                        Center(
                            child: Transform.translate(
                                offset: const Offset(0, -20),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset('assets/app_logo.png',
                                          width: 112, height: 112),
                                      const SizedBox(height: 18),
                                      const Text('StallSeeker',
                                          style: TextStyle(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                              letterSpacing: -1.1)),
                                      const SizedBox(height: 12),
                                      const Text(
                                          'Find nearby food stalls, live.',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF77777E))),
                                    ]))),
                      ])))),
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  padding: EdgeInsets.fromLTRB(
                      24, 28, 24, MediaQuery.paddingOf(context).bottom + 20),
                  decoration: const BoxDecoration(
                      color: Color(0xFF18181A),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(40))),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            _button(
                                icon: Image.asset('assets/google_logo.png',
                                    width: 21, height: 21),
                                label: 'Continue with Google',
                                color: Colors.white,
                                textColor: Colors.black,
                                onPressed: _busy ? null : _google),
                            const SizedBox(height: 12),
                            _button(
                                icon: const Icon(Icons.mail_outline_rounded,
                                    size: 22),
                                label: 'Log in or sign up',
                                color: const Color(0xFF2D2D30),
                                textColor: Colors.white,
                                onPressed: _busy ? null : _openLogin),
                            if (_busy) ...[
                              const SizedBox(height: 16),
                              const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary)),
                            ],
                          ]))))),
        ]),
      );
}
````

## File: lib/features/shared/logout_helper.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

Future<void> confirmAndLogout(
  BuildContext context,
  AuthService authService,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final signedOut = await showCupertinoModalPopup<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    builder: (_) => _LogoutSheet(authService: authService),
  );
  if (signedOut == true && navigator.mounted) {
    navigator.popUntil((route) => route.isFirst);
  }
}

class _LogoutSheet extends StatefulWidget {
  const _LogoutSheet({required this.authService});

  final AuthService authService;

  @override
  State<_LogoutSheet> createState() => _LogoutSheetState();
}

class _LogoutSheetState extends State<_LogoutSheet> {
  bool _busy = false;
  String? _error;
  late final bool _guest =
      FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

  Future<void> _logout() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authService.signOut();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not finish logging out. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: CupertinoTheme(
          data: const CupertinoThemeData(primaryColor: AppColors.primary),
          child: CupertinoActionSheet(
            title: Text(_guest ? 'Leave Guest Mode?' : 'Log Out?'),
            message: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_guest
                    ? 'You can continue browsing or sign in at any time.'
                    : 'Are you sure you want to log out of StallSeeker?'),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: CupertinoColors.systemRed)),
                ],
              ],
            ),
            actions: [
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: _busy ? () {} : _logout,
                child: _busy
                    ? const CupertinoActivityIndicator()
                    : Text(_guest ? 'Leave Guest Mode' : 'Log Out'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: _busy ? () {} : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
}
````

## File: lib/features/shared/faq_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'account_ui.dart';
import 'info_page.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, required this.isVendor});
  final bool isVendor;
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqEntry {
  const _FaqEntry(this.group, this.question, this.answer);
  final String group;
  final String question;
  final String answer;
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _customer = [
    _FaqEntry(
        'FINDING STALLS',
        'How do I find stalls or a specific dish near me?',
        'Open Home to see the map. Allow location access to find your area, or choose a saved place. Search by dish, stall name or food category. Suggestions appear as you type. Dish results show the price, stock, stall, distance and stall status.'),
    _FaqEntry('FINDING STALLS', 'Can I filter by price?',
        'On Home, tap Price and enter a minimum, maximum, or both in RM. Stalls must have a matching dish within that range. Tap the price chip to change the range or clear it.'),
    _FaqEntry('FINDING STALLS', 'How do I save Home or a custom map pin?',
        'Open Settings, then Home location or Custom pins. Search an address, pin the exact spot on the map, or use your current search location. Name custom places and select a saved place to find nearby stalls. Guest places stay on that device.'),
    _FaqEntry('FINDING STALLS', 'Does search remember what I looked for?',
        'Yes. Recent searches appear when you tap the search box. Guest history stays on that device and is merged into a customer account after sign-in. You can remove one search or clear them all.'),
    _FaqEntry('FINDING STALLS', 'Why can’t I see a stall on the map?',
        'The stall may be closed, outside the area shown, or hidden by a filter. Clear your filters and zoom out. Vendors need to share a valid location.'),
    _FaqEntry('FINDING STALLS', 'Where can I see the menu and stock?',
        'Open a stall’s details to see its menu and available stock. Stock is updated by the vendor, so check with them if you need to be certain.'),
    _FaqEntry('FOLLOWING & UPDATES', 'How do I follow or unfollow a stall?',
        'Sign in and open the stall’s details. Tap the follow or heart button. Your saved stalls appear in Following. Tap the button again to unfollow.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Can I get alerts for one dish?',
        'Sign in with a verified customer account, open the stall’s menu, and tap Follow dish. See your saved dishes in Following. An alert is created when a sold-out dish becomes available or low stock again. You can unfollow at any time.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Where are my past notifications?',
        'Open Notifications for saved stall-opening and dish-restock updates. Use All or Unread to filter the list. Tap a dish alert to open its menu. Older pushes sent before history was enabled are not added automatically.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Why am I not getting alerts?',
        'Check that you follow the stall or dish, are signed in, and have enabled alerts in Settings and your phone settings. Stall alerts arrive when it changes from closed to open. Dish alerts arrive when a sold-out dish is restocked. Your phone or network may delay delivery.'),
  ];
  static const _vendor = [
    _FaqEntry('YOUR STALL', 'How do I mark my stall as open?',
        'Use the stall status switch on your Dashboard. Allow location access and turn on your phone’s location services so customers can find you.'),
    _FaqEntry('YOUR STALL', 'Why is my stall missing from the map?',
        'Check that your stall is open and its location has updated. Customers may also need to clear filters or move the map to your area.'),
    _FaqEntry('MENU & STOCK', 'How do I update my menu and stock?',
        'Open Manage Menu & Stock from the Dashboard. Edit a dish’s details or change its stock status. Keep this updated when items sell out.'),
    _FaqEntry('MENU & STOCK', 'How do I change my stall photo?',
        'Open Settings, then My stall to edit your stall details and photo. Menu item photos can be changed in Manage Menu & Stock.'),
    _FaqEntry('STALL UPDATES', 'When are followers notified?',
        'An opening update is created when your stall changes from closed to open. Dish followers are alerted when you change a sold-out dish to available or low stock. Changing prices or moving your location alone does not send an alert. Push delivery depends on customer settings and connectivity.'),
  ];
  static const _account = [
    _FaqEntry('ACCOUNT', 'How do I change my name?',
        'Open Settings and tap Edit Profile. Enter your full name and save. Your avatar uses your account photo when available, or the first word of your name.'),
    _FaqEntry('ACCOUNT', 'I forgot my password. What should I do?',
        'Tap Forgot Password on Sign In and enter your account email. Follow the link in the email to set a new password. If you signed up with Google, use Continue with Google.'),
    _FaqEntry('ACCOUNT', 'Why is the reset email missing?',
        'Check the email address and look in Spam or Junk. If you requested the email and recognise the sender, mark it as not spam. Wait for the resend countdown before requesting another link.'),
    _FaqEntry('ACCOUNT', 'Will logging out delete my account?',
        'No. Logging out ends your session on this device. Your account and saved follows stay available when you sign in again.'),
  ];

  @override
  Widget build(BuildContext context) {
    final all = [...(widget.isVendor ? _vendor : _customer), ..._account];
    final entries = all
        .where(
            (e) => '${e.question} ${e.answer}'.toLowerCase().contains(_query))
        .toList();
    final groups = entries.map((e) => e.group).toSet();
    return InfoPage(title: 'Help & FAQ', children: [
      const Text('How can we help?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Find quick answers about your account and stalls.',
          style:
              TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
      const SizedBox(height: 20),
      TextField(
          controller: _search,
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: accountField('Search questions',
              suffix: _query.isEmpty
                  ? const Icon(Icons.search_rounded)
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded)))),
      const SizedBox(height: 28),
      if (entries.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text('No matching answers. Try a different word.',
                textAlign: TextAlign.center)),
      for (final group in groups) ...[
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(group,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF707078)))),
        _group(entries.where((e) => e.group == group).toList()),
        const SizedBox(height: 26),
      ],
    ]);
  }

  Widget _group(List<_FaqEntry> entries) => Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0)
            const Divider(
                height: .5,
                thickness: .5,
                indent: 18,
                endIndent: 18,
                color: AppColors.border),
          ExpansionTile(
              key: PageStorageKey(entries[i].question),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              shape: const Border(),
              collapsedShape: const Border(),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              iconColor: AppColors.primary,
              collapsedIconColor: const Color(0xFF8E8E93),
              title: Text(entries[i].question,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF222222),
                      height: 1.4)),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(entries[i].answer,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF707078))))
              ]),
        ],
      ]));
}
````

## File: lib/features/vendor/profile/edit_stall_screen.dart
````dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stall_categories.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/vendor_phone.dart';
import 'stall_schedule_editor.dart';
import '../../../core/widgets/app_dropdown.dart';

class EditStallScreen extends StatefulWidget {
  const EditStallScreen({super.key});

  @override
  State<EditStallScreen> createState() => _EditStallScreenState();
}

class _EditStallScreenState extends State<EditStallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  final _stallNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCategory = 'Beverages';
  final List<String> _categories = stallCategories;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOpen = false;
  Map<int, List<StallHoursInterval>> _weeklyHours = {};
  List<TemporaryClosure> _temporaryClosures = [];

  // Existing photo URL loaded from Firestore, and a newly picked local
  // file (not yet uploaded) if the vendor chose a new photo this session.
  String _existingImageUrl = '';
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadExistingVendorData();
  }

  // Fetch vendor info from Firestore to pre-fill the form
  Future<void> _loadExistingVendorData() async {
    final user = _auth.currentUser;
    if (user != null) {
      VendorModel? vendor = await _vendorService.getVendorProfile(user.uid);
      if (vendor != null) {
        _stallNameController.text = vendor.stallName;
        _descriptionController.text = vendor.description;
        _openingHoursController.text = vendor.openingHours;
        _weeklyHours = vendor.weeklyHours;
        _temporaryClosures = vendor.temporaryClosures;
        _phoneController.text = vendor.phoneNumber;
        _isOpen = vendor.isOpen;
        _existingImageUrl = vendor.imageUrl;
        if (_categories.contains(vendor.category)) {
          _selectedCategory = vendor.category;
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() {
        _pickedImage = file;
      });
    }
  }

  // Save updated stall profile to Firestore
  Future<void> _saveStallProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Only upload if the vendor picked a new photo this session.
      // Otherwise keep whatever URL was already saved.
      String imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl =
            await _storageService.uploadStallImage(user.uid, _pickedImage!);
      }

      final vendor = VendorModel(
        vendorId: user.uid,
        stallName: _stallNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        openingHours: _openingHoursController.text.trim(),
        isOpen: _isOpen,
        imageUrl: imageUrl,
        phoneNumber: normalizeVendorPhone(_phoneController.text) ?? '',
        weeklyHours: _weeklyHours,
        temporaryClosures: _temporaryClosures,
      );

      await _vendorService.saveVendorProfile(vendor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stall profile saved successfully!')),
        );
        Navigator.pop(context); // Return to Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stallNameController.dispose();
    _descriptionController.dispose();
    _openingHoursController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker() {
    Widget imageContent;
    if (_pickedImage != null) {
      imageContent = Image.file(_pickedImage!, fit: BoxFit.cover);
    } else if (_existingImageUrl.isNotEmpty) {
      imageContent = Image.network(
        _existingImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.storefront, size: 48, color: Colors.grey),
      );
    } else {
      imageContent = const Icon(Icons.storefront, size: 48, color: Colors.grey);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(26),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageContent,
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 88,
        leading: TextButton(
          onPressed: _isSaving ? null : () => Navigator.maybePop(context),
          child: const Text('Cancel'),
        ),
        title: const Text('Edit stall'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveStallProfile,
            child: Text(_isSaving ? 'Saving…' : 'Done'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    // Stall Photo
                    _buildImagePicker(),
                    const SizedBox(height: 16),

                    // Stall Name
                    TextFormField(
                      controller: _stallNameController,
                      decoration: const InputDecoration(
                        labelText: 'Stall Name',
                        hintText: 'e.g. Uncle John Drink Stall',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter stall name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    AppDropdown<String>(
                      label: 'Food category',
                      value: _selectedCategory,
                      hint: 'Choose a category',
                      options: {
                        for (final category in _categories) category: category,
                      },
                      onChanged: (value) => setState(() {
                        _selectedCategory = value;
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your food/drinks offered...',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    if (_openingHoursController.text.isNotEmpty &&
                        _weeklyHours.isEmpty)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                              'Previous hours: ${_openingHoursController.text}. Set your weekly hours below.')),
                    StallScheduleEditor(
                        hours: _weeklyHours,
                        closures: _temporaryClosures,
                        onChanged: (hours, closures) => setState(() {
                              _weeklyHours = hours;
                              _temporaryClosures = closures;
                            })),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Business phone number',
                        hintText: 'e.g. 012-345 6789',
                      ),
                      validator: (value) =>
                          normalizeVendorPhone(value ?? '') == null
                              ? 'Enter a valid Malaysian phone number.'
                              : null,
                    ),
                    const SizedBox(height: 24),

                    if (_isSaving) const LinearProgressIndicator(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
````

## File: lib/core/theme/app_theme.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily:
          defaultTargetPlatform == TargetPlatform.iOS ? '.SF Pro Text' : null,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.cardColor,
        surfaceContainerLow: AppColors.background,
        surfaceContainer: AppColors.mint,
        outline: AppColors.border,
        onSurface: AppColors.textDark,
        error: const Color(0xFFFF453A),
      ),
      // Use the platform sans-serif consistently, without per-page Poppins overrides.
      textTheme: Typography.material2021().black.apply(
            bodyColor: AppColors.textDark,
            displayColor: AppColors.textDark,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            letterSpacing: 0),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: .5),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      )),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardColor,
        selectedColor: AppColors.mint,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(color: AppColors.textDark, fontSize: 12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardColor,
        indicatorColor: AppColors.mint,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textDark)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textDark,
            size: 25)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72.0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(26)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(26)),
        ),
      ),
    );
  }
}
````

## File: lib/features/auth/screens/register_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/vendor_phone.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'customer';
  bool _busy = false;
  bool _hidePassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await _auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        role: _role,
        vendorPhone: _role == 'vendor' ? _phone.text : null);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error), backgroundColor: const Color(0xFFB3261E)));
    }
  }

  Future<void> _guest() async {
    if (_busy) return;
    if (FirebaseAuth.instance.currentUser?.isAnonymous == true) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _busy = true);
    final error = await _auth.signInAsGuest();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.maybePop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error), backgroundColor: const Color(0xFFB3261E)));
    }
  }

  InputDecoration _field(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: Color(0xFFB3261E))),
      );

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                              tooltip: 'Continue as guest',
                              onPressed: _busy ? null : _guest,
                              style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0F0F2)),
                              icon: const Icon(Icons.close_rounded,
                                  color: Color(0xFF6E6E73)))),
                      const SizedBox(height: 18),
                      const Icon(Icons.storefront_rounded,
                          size: 46, color: AppColors.primary),
                      const SizedBox(height: 14),
                      const Text('Create your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.4)),
                      const SizedBox(height: 7),
                      const Text(
                          'Save favourite stalls and receive live updates.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Color(0xFF707078))),
                      const SizedBox(height: 28),
                      TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: _field('Full name'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name.'
                              : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _field('Email address'),
                          validator: (v) => v == null || !v.trim().contains('@')
                              ? 'Enter a valid email address.'
                              : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _field('Password',
                              suffix: IconButton(
                                  onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined))),
                          validator: (v) => v == null || v.length < 6
                              ? 'Use at least 6 characters.'
                              : null),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _confirm,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          decoration: _field('Confirm password'),
                          validator: (v) => v != _password.text
                              ? 'Passwords do not match.'
                              : null),
                      const SizedBox(height: 18),
                      const Text('Account type',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF707078))),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'customer',
                                icon: Icon(Icons.person_outline),
                                label: Text('Customer')),
                            ButtonSegment(
                                value: 'vendor',
                                icon: Icon(Icons.storefront_outlined),
                                label: Text('Vendor')),
                          ],
                          selected: {
                            _role
                          },
                          onSelectionChanged: _busy
                              ? null
                              : (v) => setState(() => _role = v.first),
                          style: ButtonStyle(
                              shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16))))),
                      if (_role == 'vendor') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: _field('Business phone number'),
                            validator: (value) =>
                                normalizeVendorPhone(value ?? '') == null
                                    ? 'Enter a valid Malaysian phone number.'
                                    : null),
                        const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                                'Customers can see and call this number from your stall listing.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF707078)))),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                          height: 56,
                          child: FilledButton(
                              onPressed: _busy ? null : _register,
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28))),
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('Create account',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)))),
                      const SizedBox(height: 18),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? ',
                                style: TextStyle(color: Color(0xFF707078))),
                            TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const LoginScreen())),
                                child: const Text('Sign in',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600))),
                          ]),
                    ]))),
      ))));
}
````

## File: lib/features/customer/following/customer_following_screen.dart
````dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/follow_service.dart';
import '../../auth/screens/login_screen.dart';
import '../vendor_details/vendor_details_screen.dart';
import 'followed_dishes_list.dart';

class CustomerFollowingScreen extends StatefulWidget {
  const CustomerFollowingScreen({super.key});
  @override
  State<CustomerFollowingScreen> createState() =>
      _CustomerFollowingScreenState();
}

class _CustomerFollowingScreenState extends State<CustomerFollowingScreen> {
  final _follows = FollowService();
  final _vendors = VendorService();
  final _profiles = <String, VendorModel>{};
  final _subscriptions = <String, StreamSubscription<VendorModel?>>{};
  final _pending = <String>{};
  final _failed = <String>{};
  StreamSubscription<List<String>>? _followSubscription;
  bool _loading = true;
  bool _loadFailed = false;
  bool _openOnly = false;
  bool _ascending = true;
  int _generation = 0;
  bool _restarting = false;
  bool _showDishes = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    ++_generation;
    _followSubscription?.cancel();
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _listen() async {
    if (_restarting) {
      return;
    }
    _restarting = true;
    try {
      final generation = ++_generation;
      await _followSubscription?.cancel();
      for (final sub in _subscriptions.values) {
        await sub.cancel();
      }
      _subscriptions.clear();
      _pending.clear();
      _failed.clear();
      _profiles.clear();
      if (!mounted || generation != _generation) {
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
      _followSubscription =
          _follows.getFollowedVendorIds(user.uid).listen((ids) {
        if (!mounted || generation != _generation) {
          return;
        }
        final active = ids.toSet();
        for (final id in _subscriptions.keys.toList()) {
          if (!active.contains(id)) {
            _subscriptions.remove(id)?.cancel();
            _profiles.remove(id);
            _pending.remove(id);
            _failed.remove(id);
          }
        }
        setState(() {
          _loading = false;
          _loadFailed = false;
        });
        for (final id in active) {
          if (_subscriptions.containsKey(id)) {
            continue;
          }
          _pending.add(id);
          _subscriptions[id] = _vendors.watchVendorProfile(id).listen((vendor) {
            if (!mounted ||
                generation != _generation ||
                !_subscriptions.containsKey(id)) {
              return;
            }
            setState(() {
              _pending.remove(id);
              _failed.remove(id);
              if (vendor == null) {
                _profiles.remove(id);
              } else {
                _profiles[id] = vendor;
              }
            });
          }, onError: (Object error) {
            if (!mounted ||
                generation != _generation ||
                !_subscriptions.containsKey(id)) {
              return;
            }
            setState(() {
              _pending.remove(id);
              _failed.add(id);
              _profiles.remove(id);
            });
          });
        }
      }, onError: (Object error) {
        if (mounted && generation == _generation) {
          setState(() {
            _loading = false;
            _loadFailed = true;
          });
        }
      });
    } finally {
      _restarting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final guest = user == null || user.isAnonymous;
    final sorted = _profiles.values.toList()
      ..sort((a, b) {
        final comparison =
            a.stallName.toLowerCase().compareTo(b.stallName.toLowerCase());
        return _ascending ? comparison : -comparison;
      });
    final open = sorted.where((vendor) => vendor.isOpenNow).toList();
    final closed = sorted.where((vendor) => !vendor.isOpenNow).toList();
    return ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
              onRefresh: _listen,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
                children: [
                  Center(
                      child: CupertinoSlidingSegmentedControl<bool>(
                    backgroundColor: const Color(0xFFE2E2E7),
                    thumbColor: Colors.white,
                    groupValue: _showDishes,
                    children: const {
                      false: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: Text('Stalls')),
                      true: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: Text('Dishes')),
                    },
                    onValueChanged: (value) {
                      if (value != null) setState(() => _showDishes = value);
                    },
                  )),
                  const SizedBox(height: 20),
                  if (!_showDishes)
                    Row(children: [
                      IconButton(
                          tooltip: _ascending ? 'Sort Z to A' : 'Sort A to Z',
                          onPressed: () =>
                              setState(() => _ascending = !_ascending),
                          icon: const Icon(Icons.sort_by_alpha_rounded,
                              color: AppColors.primary)),
                      Expanded(
                          child: Center(
                              child: CupertinoSlidingSegmentedControl<bool>(
                        backgroundColor: const Color(0xFFE2E2E7),
                        thumbColor: Colors.white,
                        groupValue: _openOnly,
                        children: const {
                          false: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text('All stalls')),
                          true: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text('Open now')),
                        },
                        onValueChanged: (value) {
                          if (value != null) {
                            setState(() => _openOnly = value);
                          }
                        },
                      ))),
                      IconButton(
                          tooltip: 'Refresh followed stalls',
                          onPressed: _listen,
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.primary)),
                    ]),
                  if (!_showDishes) const SizedBox(height: 24),
                  if (guest)
                    _notice('Keep your favourites here',
                        'Sign in, then follow a stall or a dish on its menu.',
                        action: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen())),
                            child: const Text('Sign in')))
                  else if (_showDishes)
                    FollowedDishesList(key: ValueKey(user.uid), uid: user.uid)
                  else if (_loading || (_pending.isNotEmpty && sorted.isEmpty))
                    const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()))
                  else if (_loadFailed)
                    _notice('Could not load followed stalls',
                        'Check your connection and retry.',
                        action: TextButton(
                            onPressed: _listen, child: const Text('Retry')))
                  else ...[
                    if (_failed.isNotEmpty)
                      _notice(
                          'Some stalls could not load', 'Pull down to retry.'),
                    if (open.isNotEmpty) _group('OPEN NOW', open),
                    if (!_openOnly && closed.isNotEmpty)
                      _group('CLOSED', closed),
                    if (_openOnly && open.isEmpty)
                      _notice('No followed stalls are open',
                          'Check again later, or switch to All stalls.'),
                    if (!_openOnly && sorted.isEmpty && _failed.isEmpty)
                      _notice('No followed stalls yet',
                          'Find a stall on the map and tap Follow to save it here.'),
                  ],
                ],
              )),
        ));
  }

  Widget _group(String label, List<VendorModel> vendors) => Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text('$label · ${vendors.length}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
          AppGroupedCard(children: [
            for (var index = 0; index < vendors.length; index++) ...[
              _stallRow(vendors[index]),
            ],
          ]),
        ]),
      );

  Widget _stallRow(VendorModel vendor) => ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: AppIconTile(
            icon: Icons.storefront_rounded,
            color:
                vendor.isOpenNow ? AppColors.primary : const Color(0xFF949499)),
        title: Text(
            vendor.stallName.isEmpty ? 'Unnamed stall' : vendor.stallName,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(vendor.category,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF8E8E93), letterSpacing: 0))),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(vendor.isOpenNow ? 'Open' : 'Closed',
              style: TextStyle(
                  fontSize: 12,
                  color: vendor.isOpenNow
                      ? const Color(0xFF15803D)
                      : const Color(0xFF8E8E93))),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2), size: 20),
        ]),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VendorDetailsScreen(vendor: vendor))),
      );

  Widget _notice(String title, String body, {Widget? action}) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8E8E93))),
          if (action != null) action,
        ]),
      );
}
````

## File: lib/features/shared/profile_page.dart
````dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// iOS-style grouped settings, with StallSeeker's existing account actions.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    required this.isVendor,
    required this.isGuest,
    required this.canChangePassword,
    required this.location,
    required this.isLoadingLocation,
    required this.onRefresh,
    required this.onLocation,
    required this.onEdit,
    required this.onPassword,
    required this.onFaq,
    required this.onAbout,
    required this.onLogout,
    required this.onSignIn,
    required this.onNotificationSettings,
    required this.onPrivacyPolicy,
    required this.onTerms,
    required this.onDeleteAccount,
    this.onEditStall,
    this.onOrders,
    this.bookingSection,
    this.onPersonalInformation,
    this.onHomeLocation,
    this.onCustomLocation,
    this.homeLocation = 'Choose or save your home pin',
    this.customLocation = 'Manage your saved places',
  });

  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isVendor;
  final bool isGuest;
  final bool canChangePassword;
  final String location;
  final bool isLoadingLocation;
  final Future<void> Function() onRefresh;
  final VoidCallback onLocation;
  final VoidCallback onEdit;
  final VoidCallback onPassword;
  final VoidCallback onFaq;
  final VoidCallback onAbout;
  final VoidCallback onLogout;
  final VoidCallback onSignIn;
  final VoidCallback onNotificationSettings;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTerms;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onEditStall;
  final VoidCallback? onOrders;
  final Widget? bookingSection;
  final VoidCallback? onPersonalInformation;
  final VoidCallback? onHomeLocation;
  final VoidCallback? onCustomLocation;
  final String homeLocation;
  final String customLocation;

  static const background = AppColors.background;
  static const accent = AppColors.primary;
  static const muted = Color(0xFF8E8E93);
  static const divider = Color(0xFFE5E5E8);

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  Widget _avatar() => ClipOval(
        child: SizedBox(
          width: 100,
          height: 100,
          child: photoUrl == null || photoUrl!.trim().isEmpty
              ? const ColoredBox(
                  color: Color(0xFFF3DED1),
                  child:
                      Icon(CupertinoIcons.person_fill, size: 60, color: accent),
                )
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(_initial,
                        style: const TextStyle(fontSize: 45, color: accent)),
                  ),
                ),
        ),
      );

  Widget _header() {
    final contact = [
      if (phoneNumber?.trim().isNotEmpty == true) phoneNumber!.trim(),
      if (email.trim().isNotEmpty) email.trim(),
    ].join(' · ');
    return Column(children: [
      SizedBox(
        height: 116,
        child: Stack(alignment: Alignment.topCenter, children: [
          Positioned(top: 12, child: _avatar()),
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.white,
              shape: const StadiumBorder(),
              elevation: 5,
              shadowColor: const Color(0x18000000),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: isGuest ? onSignIn : onEdit,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                  child: Text(isGuest ? 'Sign in' : 'Edit',
                      style:
                          const TextStyle(fontSize: 17, color: Colors.black)),
                ),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 9),
      Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.1,
          letterSpacing: -0.6,
          color: Colors.black,
        ),
      ),
      if (contact.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(
          contact,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, height: 1.2, color: muted),
        ),
      ],
    ]);
  }

  Widget _group(List<Widget> rows) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.only(left: 60, right: 16),
                child: Divider(height: .5, thickness: .5, color: divider),
              ),
            rows[index],
          ],
        ]),
      );

  Widget _row(
    IconData icon,
    Color iconColor,
    String label,
    VoidCallback onTap, {
    String? value,
    String? subtitle,
    Widget? trailing,
  }) =>
      InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: iconColor == AppColors.primary
                      ? AppColors.logoGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(Colors.white, iconColor, .78)!,
                            iconColor,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: Colors.black),
                    ),
                    if (subtitle != null)
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: muted)),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, color: muted)),
                ),
              ],
              const SizedBox(width: 8),
              trailing ??
                  const Icon(CupertinoIcons.chevron_right,
                      size: 17, color: Color(0xFFB6B6B8)),
            ]),
          ),
        ),
      );

  Widget _editAction() => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isGuest ? onSignIn : onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            child: Row(children: [
              const Icon(CupertinoIcons.camera_on_rectangle,
                  color: accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isGuest ? 'Sign in to edit profile' : 'Edit Profile',
                  style: const TextStyle(fontSize: 17, color: accent),
                ),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .28, .6],
              colors: [Colors.white, background, background],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
                children: [
                  _header(),
                  const SizedBox(height: 45),
                  _editAction(),
                  const SizedBox(height: 24),
                  if (!isGuest) ...[
                    _group([
                      _row(
                          CupertinoIcons.person_crop_circle_fill,
                          const Color(0xFFFF5956),
                          'My Profile',
                          onPersonalInformation ?? onEdit),
                    ]),
                    const SizedBox(height: 24),
                  ],
                  if (bookingSection != null) ...[
                    bookingSection!,
                    const SizedBox(height: 24),
                  ],
                  _group([
                    _row(CupertinoIcons.location_solid, const Color(0xFF43CE72),
                        'Current Location', onLocation,
                        subtitle: location,
                        trailing: isLoadingLocation
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null),
                    if (onHomeLocation != null)
                      _row(CupertinoIcons.house_fill, AppColors.primary,
                          'Home location', onHomeLocation!),
                    if (onCustomLocation != null)
                      _row(CupertinoIcons.map_fill, AppColors.primaryLight,
                          'Custom pins', onCustomLocation!),
                    if (isVendor && onEditStall != null)
                      _row(CupertinoIcons.bag_fill, const Color(0xFFFFAE22),
                          'My Stall', onEditStall!),
                    if (onOrders != null)
                      _row(CupertinoIcons.square_list_fill,
                          const Color(0xFFFFAE22), 'My Bookings', onOrders!),
                  ]),
                  if (!isGuest) ...[
                    const SizedBox(height: 24),
                    _group([
                      _row(CupertinoIcons.bell_fill, const Color(0xFFFF5555),
                          'Notifications and Sounds', onNotificationSettings),
                      _row(CupertinoIcons.lock_fill, const Color(0xFF949499),
                          'Privacy Policy', onPrivacyPolicy),
                      _row(CupertinoIcons.doc_text_fill,
                          const Color(0xFF42C96D), 'Terms of Use', onTerms),
                      if (canChangePassword)
                        _row(
                            CupertinoIcons.padlock_solid,
                            AppColors.primaryLight,
                            'Change password',
                            onPassword),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _group([
                    _row(CupertinoIcons.question_circle_fill,
                        const Color(0xFFAD55E8), 'Help & FAQ', onFaq),
                    _row(CupertinoIcons.info_circle_fill,
                        const Color(0xFF8288EF), 'About StallSeeker', onAbout),
                  ]),
                  if (!isGuest) ...[
                    const SizedBox(height: 24),
                    _group([
                      _row(CupertinoIcons.trash_fill, const Color(0xFFFF5956),
                          'Delete account', onDeleteAccount),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _group([
                    _row(
                        CupertinoIcons.square_arrow_right,
                        const Color(0xFF949499),
                        isGuest ? 'Leave guest mode' : 'Logout',
                        onLogout),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/vendor/menu/vendor_menu_screen.dart
````dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_dropdown.dart';

class VendorMenuScreen extends StatefulWidget {
  const VendorMenuScreen({super.key});
  @override
  State<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends State<VendorMenuScreen> {
  final _menu = MenuService();
  final _storage = StorageService();
  final _busyItems = <String>{};
  late Stream<List<MenuItemModel>> _items;
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  static const _statuses = {
    'available': ('Available', Colors.green),
    'low_stock': ('Low stock', Colors.orange),
    'out_of_stock': ('Sold out', Colors.red),
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = _uid == null
        ? Stream.value(<MenuItemModel>[])
        : _menu.getMenuItems(_uid);
  }

  void _error(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _status(MenuItemModel item, String status) async {
    if (_uid == null ||
        _busyItems.contains(item.itemId) ||
        item.status == status) {
      return;
    }
    setState(() => _busyItems.add(item.itemId));
    try {
      await _menu.updateItemStatus(_uid, item.itemId, status);
    } catch (_) {
      _error('Could not update stock. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _busyItems.remove(item.itemId));
      }
    }
  }

  Future<void> _delete(MenuItemModel item) async {
    if (_uid == null || _busyItems.contains(item.itemId)) {
      return;
    }
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Delete dish?'),
              content: Text(
                  'Delete ${item.name} from your menu? This cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete')),
              ],
            ));
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busyItems.add(item.itemId));
    try {
      await _menu.deleteMenuItem(_uid, item.itemId);
    } catch (_) {
      _error('Could not delete this dish. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _busyItems.remove(item.itemId));
      }
    }
  }

  Future<void> _edit([MenuItemModel? item]) async {
    if (_uid == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) =>
          _MenuEditor(uid: _uid, item: item, menu: _menu, storage: _storage),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Menu & stock')),
        floatingActionButton: _uid == null
            ? null
            : FloatingActionButton.extended(
                onPressed: _edit,
                icon: const Icon(Icons.add),
                label: const Text('Add dish')),
        body: StreamBuilder<List<MenuItemModel>>(
            stream: _items,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Could not load your menu.'),
                  TextButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Retry')),
                ]));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                    child: Text(
                        'Your menu is empty.\nTap Add dish to get started.',
                        textAlign: TextAlign.center));
              }
              return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final busy = _busyItems.contains(item.itemId);
                    return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: item.imageUrl.isEmpty
                                              ? const Icon(Icons.restaurant,
                                                  size: 32)
                                              : Image.network(item.imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                          Icons.restaurant,
                                                          size: 32)))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(item.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        Text(
                                            'RM ${item.price.toStringAsFixed(2)}'),
                                        Text(item.section,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ])),
                                  AppDropdown<String>(
                                    iconOnly: true,
                                    icon: Icons.more_vert,
                                    hint: 'Dish options',
                                    options: const {
                                      'edit': 'Edit dish',
                                      'delete': 'Delete dish',
                                    },
                                    onChanged: busy
                                        ? null
                                        : (value) {
                                            if (value == 'edit') {
                                              _edit(item);
                                            } else {
                                              _delete(item);
                                            }
                                          },
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: _statuses.entries
                                        .map((entry) => ChoiceChip(
                                              label: Text(entry.value.$1),
                                              avatar: Icon(Icons.circle,
                                                  size: 12,
                                                  color: entry.value.$2),
                                              selected:
                                                  item.status == entry.key,
                                              onSelected: busy
                                                  ? null
                                                  : (_) =>
                                                      _status(item, entry.key),
                                            ))
                                        .toList()),
                                if (busy) const LinearProgressIndicator(),
                              ]),
                        ));
                  });
            }),
      );
}

class _MenuEditor extends StatefulWidget {
  const _MenuEditor(
      {required this.uid,
      required this.item,
      required this.menu,
      required this.storage});
  final String uid;
  final MenuItemModel? item;
  final MenuService menu;
  final StorageService storage;
  @override
  State<_MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends State<_MenuEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _section;
  late final String _itemId;
  File? _image;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _price = TextEditingController(
        text: widget.item?.price.toStringAsFixed(2) ?? '');
    _section = TextEditingController(text: widget.item?.section ?? 'Main menu');
    // Reuse the same ID on retries so an uncertain network result cannot duplicate a dish.
    _itemId = widget.item?.itemId ?? widget.menu.newMenuItemId(widget.uid);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _section.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final image = await widget.storage.pickImage();
      if (mounted && image != null) {
        setState(() => _image = image);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open your photos. Please retry.');
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await widget.storage
            .uploadMenuItemImage(widget.uid, _itemId, _image!);
      }
      if (widget.item == null) {
        await widget.menu.addMenuItem(
            widget.uid, _name.text.trim(), double.parse(_price.text.trim()),
            itemId: _itemId, imageUrl: imageUrl, section: _section.text.trim());
      } else {
        await widget.menu.updateMenuItem(widget.uid, _itemId, _name.text.trim(),
            double.parse(_price.text.trim()),
            imageUrl: imageUrl, section: _section.text.trim());
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not save this dish. Your changes are still here. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Form(
              key: _form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      TextButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      Expanded(
                        child: Text(
                          widget.item == null ? 'Add dish' : 'Edit dish',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving…' : 'Done'),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (_image != null)
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_image!,
                              height: 140, fit: BoxFit.cover))
                    else if (widget.item?.imageUrl.isNotEmpty == true)
                      Image.network(widget.item!.imageUrl,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.restaurant)),
                    TextButton.icon(
                        onPressed: _saving ? null : _pick,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Choose photo')),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _name,
                        enabled: !_saving,
                        maxLength: 80,
                        decoration:
                            const InputDecoration(labelText: 'Dish name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a dish name.'
                                : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _section,
                        enabled: !_saving,
                        maxLength: 40,
                        decoration: const InputDecoration(
                            labelText: 'Menu section',
                            hintText: 'e.g. Drinks, Mains, Desserts'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a menu section.'
                                : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _price,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Price', prefixText: 'RM '),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          final price = double.tryParse(text);
                          if (price == null ||
                              !price.isFinite ||
                              price <= 0 ||
                              !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
                            return 'Enter a positive price with up to 2 decimal places.';
                          }
                          return null;
                        }),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    if (_saving) const LinearProgressIndicator(),
                  ])),
        ),
      );
}
````

## File: lib/features/vendor/profile/vendor_profile_screen.dart
````dart
import 'edit_stall_screen.dart';
import '../../shared/profile_page.dart';
import '../../shared/edit_profile_screen.dart';
import '../../shared/personal_information_screen.dart';
import '../../shared/change_password_screen.dart';
import '../../shared/notification_settings_screen.dart';
import '../../shared/legal_screen.dart';
import '../../shared/delete_account_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../shared/faq_screen.dart';
import '../../shared/about_screen.dart';
import '../../shared/logout_helper.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _authService = AuthService();
  final _geocoding = Geocoding();

  UserModel? _userModel;
  String _phoneNumber = '';
  bool _isLoading = true;

  // Current Location section state -- shows the vendor's live GPS
  // position (turned into a readable address via reverse geocoding),
  // same pattern as the customer profile screen.
  String _locationText = 'Tap to find your current area';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      final vendor = await VendorService().getVendorProfile(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userData;
          _phoneNumber = vendor?.phoneNumber ?? '';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    if (!mounted || _isLoadingLocation) {
      return;
    }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) {
        return;
      }
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services are turned off.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) {
        return;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission not granted.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));

      final placemarks = await _geocoding
          .placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          )
          .timeout(const Duration(seconds: 8));
      final address =
          _formatPlacemark(placemarks.isNotEmpty ? placemarks.first : null);

      if (mounted) {
        setState(() {
          _locationText = address;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _formatPlacemark(Placemark? p) {
    if (p == null) {
      return 'Location unavailable';
    }
    final parts = [p.subLocality, p.locality, p.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => EditProfileScreen(
                name: _userModel?.fullName ?? user?.displayName ?? '',
                email: _userModel?.email ?? user?.email ?? '')));
    if (saved == true && mounted) {
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    }
  }

  Future<void> _personalInformation() async {
    final user = FirebaseAuth.instance.currentUser;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PersonalInformationScreen(
                name: _userModel?.fullName ?? user?.displayName ?? '',
                email: _userModel?.email ?? user?.email ?? '',
                isVendor: true)));
    if (mounted) {
      await _loadUserData();
    }
  }

  void _changePassword() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
                email: _userModel?.email ??
                    FirebaseAuth.instance.currentUser?.email ??
                    '')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest
        ? 'Guest'
        : _userModel?.fullName.isNotEmpty == true
            ? _userModel!.fullName
            : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name,
      email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      photoUrl: guest ? null : user?.photoURL,
      phoneNumber: guest ? null : _phoneNumber,
      isVendor: true,
      isGuest: guest,
      canChangePassword: user?.providerData
              .any((provider) => provider.providerId == 'password') ??
          false,
      location: _locationText,
      isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _loadLocation,
      onEdit: _editProfile,
      onPersonalInformation: _personalInformation,
      onPassword: _changePassword,
      onFaq: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: true))),
      onAbout: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onNotificationSettings: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen())),
      onPrivacyPolicy: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const LegalScreen(page: LegalPage.privacy))),
      onTerms: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const LegalScreen(page: LegalPage.terms))),
      onDeleteAccount: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      onEditStall: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const EditStallScreen())),
    );
  }
}
````

## File: lib/features/vendor/vendor_main_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_pill_navigation.dart';
import '../../core/services/demo_order_service.dart';
import 'dashboard/vendor_dashboard_screen.dart';
import 'profile/vendor_profile_screen.dart';
import '../shared/profile_page.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _selectedIndex = 0;
  late final Stream<int> _newBookings = DemoOrderService().watchUnseenCount(
      FirebaseAuth.instance.currentUser?.uid ?? '',
      isVendor: true);

  static const _titles = ['Vendor Dashboard', 'Settings'];

  // Key to call dashboard refresh method
  final _dashboardKey = GlobalKey<VendorDashboardScreenState>();

  void _refreshDashboard() {
    _dashboardKey.currentState?.fetchVendorDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor:
          _selectedIndex == 1 ? ProfilePage.background : AppColors.background,
      appBar: _selectedIndex == 1
          ? null
          : AppBar(
              title: Text(
                _titles[_selectedIndex],
              ),
              centerTitle: true,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              actions: [
                // Refresh button only on Dashboard
                if (_selectedIndex == 0)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.textDark),
                    tooltip: 'Refresh',
                    onPressed: _refreshDashboard,
                  ),
              ],
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          VendorDashboardScreen(key: _dashboardKey),
          const VendorProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppPillNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: _dashboardIcon(false),
            selectedIcon: _dashboardIcon(true),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(CupertinoIcons.gear),
            selectedIcon: Icon(CupertinoIcons.gear_solid),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _dashboardIcon(bool selected) => StreamBuilder<int>(
      stream: _newBookings,
      builder: (context, snapshot) => Badge(
            isLabelVisible: (snapshot.data ?? 0) > 0,
            label: Text(
                (snapshot.data ?? 0) > 99 ? '99+' : '${snapshot.data ?? 0}'),
            child: Icon(
                selected
                    ? CupertinoIcons.square_grid_2x2_fill
                    : CupertinoIcons.square_grid_2x2,
                color: selected ? AppColors.textDark : AppColors.textMuted),
          ));
}
````

## File: lib/features/customer/vendor_details/vendor_details_screen.dart
````dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/stall_review.dart';
import '../../../core/models/dish_follow_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/stall_review_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/dish_follow_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';
import '../orders/demo_order_cart_screen.dart';

class VendorDetailsScreen extends StatefulWidget {
  final VendorModel vendor;
  final String? initialDishId;

  const VendorDetailsScreen(
      {super.key, required this.vendor, this.initialDishId});

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  final _menuService = MenuService();
  final _followService = FollowService();
  final _dishFollows = DishFollowService();
  final _vendorService = VendorService();
  final _reviews = StallReviewService();

  // Local copy of the vendor, refreshable independently of the
  // instance passed in -- the one passed in is a snapshot from
  // whenever the customer tapped the marker/card, and doesn't update
  // on its own if the vendor changes their status while this screen
  // is open.
  late VendorModel _vendor;
  bool _isRefreshing = false;
  String? _vendorError;
  bool _vendorDeleted = false;
  bool _isFollowSaving = false;
  StreamSubscription<VendorModel?>? _vendorSub;
  Timer? _freshnessTimer;
  late Stream<List<MenuItemModel>> _menuStream;
  late Stream<List<StallReview>> _reviewStream;
  final _dishSearch = TextEditingController();
  String _dishQuery = '';
  String? _focusedDishId;
  final _followedDishIds = <String>{};
  final _savingDishes = <String>{};
  StreamSubscription<List<DishFollowModel>>? _dishFollowSub;
  StreamSubscription<User?>? _dishAuthSub;
  bool _dishFollowLoading = true;
  bool _dishFollowError = false;
  bool _customerAccount = false;

  // Local follow state, kept in sync with Firestore via a listener but
  // updated OPTIMISTICALLY (immediately, before the write completes)
  // when the user taps the heart -- this is what makes the icon flip
  // instantly instead of waiting on a round-trip.
  bool _isFollowing = false;
  StreamSubscription<bool>? _followSub;

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
    _focusedDishId = widget.initialDishId;
    _menuStream = _menuService.getMenuItems(_vendor.vendorId);
    _reviewStream = _reviews.watchReviews(_vendor.vendorId);
    _vendorSub = _vendorService.watchVendorProfile(_vendor.vendorId).listen(
      (vendor) {
        if (!mounted) {
          return;
        }
        setState(() {
          _vendorDeleted = vendor == null;
          if (vendor != null) {
            _vendor = vendor;
          }
          _vendorError = null;
        });
      },
      onError: (Object error) {
        if (mounted) {
          setState(() => _vendorError =
              'Could not update this stall. Showing last known details.');
        }
      },
    );
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    final customerId = user?.uid;
    if (customerId != null && user?.isAnonymous == false) {
      _followSub = _followService
          .isFollowing(customerId, _vendor.vendorId)
          .listen((value) {
        if (mounted) {
          setState(() => _isFollowing = value);
        }
      });
    }
    _dishAuthSub = FirebaseAuth.instance.userChanges().listen((_) {
      unawaited(_listenDishFollows());
    });
  }

  @override
  void dispose() {
    _followSub?.cancel();
    _dishFollowSub?.cancel();
    _dishAuthSub?.cancel();
    _vendorSub?.cancel();
    _freshnessTimer?.cancel();
    _dishSearch.dispose();
    super.dispose();
  }

  Future<void> _refreshVendor() async {
    setState(() => _isRefreshing = true);
    final updated = await _vendorService.getVendorProfile(_vendor.vendorId);
    if (mounted) {
      setState(() {
        if (updated != null) {
          _vendor = updated;
        }
        _isRefreshing = false;
      });
    }
  }

  Future<void> _listenDishFollows() async {
    await _dishFollowSub?.cancel();
    _dishFollowSub = null;
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _followedDishIds.clear();
        _customerAccount = false;
        _dishFollowError = false;
        _dishFollowLoading = false;
      });
    }
    if (user == null || user.isAnonymous || !user.emailVerified) {
      return;
    }
    if (mounted) {
      setState(() {
        _dishFollowLoading = true;
        _dishFollowError = false;
      });
    }
    try {
      final profile = await AuthService()
          .getUserData(user.uid)
          .timeout(const Duration(seconds: 10));
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      if (profile?.role != 'customer') {
        setState(() {
          _dishFollowLoading = false;
          _dishFollowError = profile == null;
        });
        return;
      }
      _customerAccount = true;
      _dishFollowSub = _dishFollows
          .watch(user.uid, vendorId: _vendor.vendorId)
          .listen((follows) {
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
          return;
        }
        setState(() {
          _followedDishIds
            ..clear()
            ..addAll(follows.map((follow) => follow.itemId));
          _dishFollowLoading = false;
          _dishFollowError = false;
        });
      }, onError: (Object error) {
        if (mounted) {
          setState(() {
            _dishFollowLoading = false;
            _dishFollowError = true;
          });
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _dishFollowLoading = false;
          _dishFollowError = true;
        });
      }
    }
  }

  Future<void> _toggleDishFollow(MenuItemModel item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _showLoginRequiredDialog(context, action: 'Following dishes');
      return;
    }
    if (!user.emailVerified || !_customerAccount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!user.emailVerified
              ? 'Verify your email before following dishes.'
              : 'Only customer accounts can follow dishes.')));
      return;
    }
    if (_savingDishes.contains(item.itemId) ||
        _dishFollowLoading ||
        _dishFollowError) {
      return;
    }
    final following = _followedDishIds.contains(item.itemId);
    setState(() => _savingDishes.add(item.itemId));
    try {
      if (following) {
        await _dishFollows.unfollow(user.uid, _vendor.vendorId, item.itemId);
      } else {
        await _dishFollows.follow(user.uid, _vendor.vendorId, item.itemId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(following
                ? 'Dish unfollowed.'
                : 'Following ${item.name}. We’ll alert you when it is restocked.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not update dish following. Please retry.')));
      }
    } finally {
      if (mounted) {
        setState(() => _savingDishes.remove(item.itemId));
      }
    }
  }

  Future<void> _toggleFollow(String customerId) async {
    if (_isFollowSaving) {
      return;
    }
    _isFollowSaving = true;
    final wasFollowing = _isFollowing;
    // Flip immediately -- don't wait for Firestore to confirm. If the
    // write fails for some reason, it gets reverted in the catch below.
    setState(() => _isFollowing = !wasFollowing);

    try {
      if (wasFollowing) {
        await _followService.unfollowVendor(customerId, _vendor.vendorId);
      } else {
        await _followService.followVendor(customerId, _vendor.vendorId);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFollowing = wasFollowing);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not update following. Please retry.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowSaving = false);
      }
    }
  }

  Future<void> _openNavigation() async {
    final coordinates = '${_vendor.latitude},${_vendor.longitude}';
    final isApplePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final googleMapsUri = isApplePlatform
        ? Uri.parse(
            'comgooglemaps://?daddr=$coordinates&directionsmode=driving')
        : Uri.parse('google.navigation:q=$coordinates&mode=d');
    final wazeUri = Uri.parse('waze://?ll=$coordinates&navigate=yes');
    final browserUri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {'api': '1', 'destination': coordinates},
    );
    var googleMapsAvailable = false;
    var wazeAvailable = false;
    if (!kIsWeb) {
      try {
        googleMapsAvailable = await canLaunchUrl(googleMapsUri);
        wazeAvailable = await canLaunchUrl(wazeUri);
      } catch (_) {
        // The browser fallback remains available when app detection fails.
      }
    }
    if (!mounted) {
      return;
    }

    Future<void> launchNavigation(Uri uri) async {
      Navigator.pop(context);
      var launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open that navigation app.')));
      }
    }

    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: const Text('Choose navigation app'),
                  subtitle: Text(_vendor.stallName.isEmpty
                      ? 'Stall location'
                      : _vendor.stallName)),
              if (googleMapsAvailable)
                ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('Google Maps'),
                    onTap: () => launchNavigation(googleMapsUri)),
              if (wazeAvailable)
                ListTile(
                    leading: const Icon(Icons.navigation_outlined),
                    title: const Text('Waze'),
                    onTap: () => launchNavigation(wazeUri)),
              ListTile(
                  leading: const Icon(Icons.open_in_browser),
                  title: const Text('Google Maps in browser'),
                  onTap: () => launchNavigation(browserUri)),
              if (!googleMapsAvailable && !wazeAvailable)
                const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                        'Google Maps and Waze were not detected. Browser directions are still available.',
                        style: TextStyle(color: Colors.grey))),
            ])));
  }

  void _showLoginRequiredDialog(BuildContext context,
      {String action = 'Following vendors'}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create an Account'),
        content: Text(
          '$action requires an account. Log in or register to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF15803D);
      case 'low_stock':
        return const Color(0xFF92400E);
      case 'out_of_stock':
        return const Color(0xFFB42318);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'low_stock':
        return 'Low Stock';
      case 'out_of_stock':
        return 'Sold out';
      default:
        return status;
    }
  }

  Future<void> _editReview(StallReview? existing) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _showLoginRequiredDialog(context, action: 'Writing reviews');
      return;
    }
    final profile = await AuthService().getUserData(user.uid);
    if (!mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _ReviewEditor(
            vendorId: _vendor.vendorId,
            customerId: user.uid,
            customerName: profile?.fullName ?? user.displayName ?? 'Customer',
            existing: existing));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final customerId = currentUser?.uid;
    final isGuest = currentUser?.isAnonymous ?? true;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stall details'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh stall status',
            onPressed: _isRefreshing ? null : _refreshVendor,
          ),
          if (customerId != null)
            isGuest
                ? IconButton(
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Follow',
                    onPressed: () => _showLoginRequiredDialog(context),
                  )
                : IconButton(
                    icon: Icon(
                      _isFollowing ? Icons.favorite : Icons.favorite_border,
                      color: _isFollowing ? Colors.red : null,
                    ),
                    tooltip: _isFollowing ? 'Unfollow' : 'Follow',
                    onPressed: _isFollowSaving || _vendorDeleted
                        ? null
                        : () => _toggleFollow(customerId),
                  ),
        ],
      ),
      // On tablet: buttons sit neatly in the left sidebar. On phone: sticky bottom bar.
      bottomNavigationBar: isTablet
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: _buildActionButtons(isGuest: isGuest),
            ),
      body: isTablet
          ? _buildTabletLayout(context, isGuest: isGuest)
          : _buildMobileLayout(context),
    );
  }

  // ---------------------------------------------------------------------------
  // Responsive Layouts (Mobile vs Tablet)
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        ..._buildStallInfoWidgets(isTablet: false),
        const SizedBox(height: 26),
        ..._buildMenuAndReviewWidgets(),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, {required bool isGuest}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Stall Identity & Info & Actions
        SizedBox(
          width: 380,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 24),
            children: [
              ..._buildStallInfoWidgets(isTablet: true),
              const SizedBox(height: 20),
              _buildActionButtons(isGuest: isGuest),
            ],
          ),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: Color(0xFFE9ECF0),
        ),
        // Right Column: Menu & Reviews
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: _buildMenuAndReviewWidgets(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Component Blocks
  // ---------------------------------------------------------------------------

  Widget _buildStallPhoto({double height = 210}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: _vendor.imageUrl.isNotEmpty
            ? Image.network(
                _vendor.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _photoPlaceholder(),
              )
            : _photoPlaceholder(),
      ),
    );
  }

  List<Widget> _buildStallInfoWidgets({required bool isTablet}) {
    return [
      if (_vendorDeleted || _vendorError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _vendorDeleted
                ? 'This stall is no longer available.'
                : _vendorError!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      _buildStallPhoto(height: isTablet ? 220 : 200),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _badge(
            _vendor.isOpenNow ? 'Open now' : 'Closed',
            _vendor.isOpenNow
                ? const Color(0xFF15803D)
                : const Color(0xFFB42318),
            Icons.circle,
          ),
          if (_vendor.category.isNotEmpty)
            _badge(_vendor.category, const Color(0xFF64748B),
                Icons.restaurant_outlined),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        _vendor.stallName.isEmpty ? 'Unnamed stall' : _vendor.stallName,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: Color(0xFF17202D),
        ),
      ),
      if (_vendor.description.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          _vendor.description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            _info(
              Icons.schedule_rounded,
              'Opening hours',
              _vendor.hoursToday.isEmpty
                  ? 'Not provided by this vendor'
                  : _vendor.hoursToday,
            ),
            if (_vendor.isTemporarilyClosed) ...[
              const Divider(height: 24, indent: 36),
              _info(
                Icons.event_busy_outlined,
                'Temporary closure',
                'This stall is temporarily closed.',
              ),
            ],
            if (_vendor.phoneNumber.isNotEmpty) ...[
              const Divider(height: 24, indent: 36),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.call_outlined, color: Color(0xFF64748B)),
                title: const Text('Vendor phone'),
                subtitle: Text(_vendor.phoneNumber),
                trailing: const Icon(Icons.call),
                onTap: () =>
                    launchUrl(Uri(scheme: 'tel', path: _vendor.phoneNumber)),
              ),
            ],
            const Divider(height: 24, indent: 36),
            _info(
              Icons.location_on_outlined,
              _vendor.hasFreshLocation
                  ? 'Location updated recently'
                  : 'Last known location',
              _vendor.hasFreshLocation
                  ? 'The vendor is sharing their location.'
                  : 'This location may be outdated. Check before travelling.',
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildActionButtons({required bool isGuest}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_vendorDeleted &&
            _vendor.selfCollectEnabled &&
            _vendor.isOpenNow &&
            _vendor.hasValidLocation) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isGuest
                  ? () => _showLoginRequiredDialog(context,
                      action: 'self-collect bookings')
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              DemoOrderCartScreen(vendor: _vendor))),
              icon: const Icon(Icons.shopping_bag_outlined),
              label:
                  Text(isGuest ? 'Sign in to book' : 'Book for self-collect'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: !_vendorDeleted && _vendor.hasValidLocation
                ? _openNavigation
                : null,
            icon: const Icon(Icons.directions),
            label: const Text('Get directions'),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuAndReviewWidgets() {
    return [
      const Text(
        'On the menu',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF17202D),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Availability is updated by the vendor',
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 4),
      const Text(
        'Follow a dish to hear when it is back in stock.',
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      if (_dishFollowError)
        Row(children: [
          const Expanded(child: Text('Could not load dish following.')),
          TextButton(
            onPressed: _listenDishFollows,
            child: const Text('Retry'),
          ),
        ]),
      if (_focusedDishId != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Expanded(child: Text('Showing your followed dish')),
            TextButton(
              onPressed: () => setState(() => _focusedDishId = null),
              child: const Text('Show all dishes'),
            ),
          ]),
        ),
      const SizedBox(height: 14),
      TextField(
        controller: _dishSearch,
        onChanged: (value) => setState(() {
          _focusedDishId = null;
          _dishQuery = value.trim().toLowerCase();
        }),
        decoration: InputDecoration(
          hintText: 'Search dishes',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _dishQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear dish search',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _dishSearch.clear();
                    setState(() => _dishQuery = '');
                  },
                ),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 14),
      StreamBuilder<List<MenuItemModel>>(
        stream: _menuStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('Could not load the menu.'),
                TextButton(
                  onPressed: () => setState(() => _menuStream =
                      _menuService.getMenuItems(_vendor.vendorId)),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('The vendor has not added a menu yet.'),
            );
          }
          final filtered = items
              .where((item) =>
                  (_focusedDishId == null || item.itemId == _focusedDishId) &&
                  item.name.toLowerCase().contains(_dishQuery))
              .toList();
          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_focusedDishId != null
                  ? 'This dish is no longer on the menu.'
                  : 'No dishes match your search.'),
            );
          }
          final sections = <String, List<MenuItemModel>>{};
          for (final item in filtered) {
            sections.putIfAbsent(item.section, () => []).add(item);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in sections.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...entry.value.map(_menuCard),
              ],
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      StreamBuilder<List<StallReview>>(
        stream: _reviewStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Could not load reviews.');
          }
          final reviews = snapshot.data ?? [];
          final uid = FirebaseAuth.instance.currentUser?.uid;
          StallReview? mine;
          for (final review in reviews) {
            if (review.customerId == uid) {
              mine = review;
              break;
            }
          }
          final average = reviews.isEmpty
              ? 0.0
              : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
                  reviews.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    'Reviews (${reviews.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (reviews.isNotEmpty)
                  Text(
                    '${average.toStringAsFixed(1)} ★',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ]),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _editReview(mine),
                icon: const Icon(Icons.rate_review_outlined),
                label:
                    Text(mine == null ? 'Write a review' : 'Edit your review'),
              ),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No reviews yet.'),
                ),
              for (final review in reviews) _reviewCard(review),
            ],
          );
        },
      ),
    ];
  }

  Widget _photoPlaceholder() => Container(
      color: AppColors.mint,
      alignment: Alignment.center,
      child: const Icon(Icons.storefront_rounded,
          size: 60, color: AppColors.primary));

  Widget _badge(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color))),
        ]),
      );

  Widget _info(IconData icon, String title, String detail) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF64748B), size: 21),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF17202D))),
          const SizedBox(height: 4),
          Text(detail,
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
        ])),
      ]);

  Widget _menuCard(MenuItemModel item) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                  width: 68,
                  height: 68,
                  child: item.imageUrl.isEmpty
                      ? _photoPlaceholder()
                      : Image.network(item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder()))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17202D))),
                const SizedBox(height: 4),
                Text('RM ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                const SizedBox(height: 8),
                _badge(_statusLabel(item.status), _statusColor(item.status),
                    Icons.circle),
                if (item.statusUpdatedAt != null) ...[
                  const SizedBox(height: 5),
                  Text(
                      'Stock updated ${_formatStockTime(item.statusUpdatedAt!)}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B))),
                ],
                const SizedBox(height: 6),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft),
                  onPressed: _vendorDeleted ||
                          _savingDishes.contains(item.itemId) ||
                          _dishFollowLoading ||
                          _dishFollowError
                      ? null
                      : () => _toggleDishFollow(item),
                  icon: _savingDishes.contains(item.itemId)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          _followedDishIds.contains(item.itemId)
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_none_outlined,
                          size: 18),
                  label: Text(_followedDishIds.contains(item.itemId)
                      ? 'Following dish'
                      : 'Follow dish'),
                ),
              ])),
        ]),
      );

  String _formatStockTime(DateTime value) {
    final my = value.toUtc().add(const Duration(hours: 8));
    final hour = my.hour % 12 == 0 ? 12 : my.hour % 12;
    final minute = my.minute.toString().padLeft(2, '0');
    return '${my.day}/${my.month}/${my.year} $hour:$minute ${my.hour < 12 ? 'AM' : 'PM'}';
  }

  Widget _reviewCard(StallReview review) => Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(review.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('${review.rating} ★')
            ]),
            if (review.text.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(review.text)),
            if (review.photoUrls.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                      height: 90,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: review.photoUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(review.photoUrls[index],
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                      width: 90,
                                      child: Icon(
                                          Icons.broken_image_outlined))))))),
          ])));
}

class _ReviewEditor extends StatefulWidget {
  const _ReviewEditor(
      {required this.vendorId,
      required this.customerId,
      required this.customerName,
      required this.existing});
  final String vendorId;
  final String customerId;
  final String customerName;
  final StallReview? existing;
  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  final _storage = StorageService();
  final _service = StallReviewService();
  final _text = TextEditingController();
  final _photos = <File>[];
  final _existingUrls = <String>[];
  int _rating = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _text.text = widget.existing?.text ?? '';
    _existingUrls.addAll(widget.existing?.photoUrls ?? []);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = 5 - _existingUrls.length - _photos.length;
    if (remaining <= 0) {
      return;
    }
    final picked = await _storage.pickReviewImages(remaining);
    if (mounted) setState(() => _photos.addAll(picked));
  }

  Future<void> _save() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Choose a star rating.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final urls = [..._existingUrls];
      for (var i = 0; i < _photos.length; i++) {
        urls.add(await _storage.uploadReviewImage(
            widget.vendorId,
            widget.customerId,
            '${DateTime.now().microsecondsSinceEpoch}_$i',
            _photos[i]));
      }
      await _service.saveReview(widget.vendorId, widget.customerId,
          widget.customerName, _rating, _text.text, urls);
      final removed = (widget.existing?.photoUrls ?? <String>[])
          .where((url) => !urls.contains(url));
      for (final url in removed) {
        try {
          await _storage.deleteReviewImageUrl(
              widget.vendorId, widget.customerId, url);
        } catch (_) {
          // The review was saved; account deletion also cleans up old photos.
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save your review. Please retry.')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
                widget.existing == null
                    ? 'Review this stall'
                    : 'Edit your review',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                    tooltip: '$star stars',
                    onPressed:
                        _saving ? null : () => setState(() => _rating = star),
                    icon: Icon(star <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber))
            ]),
            TextField(
                controller: _text,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Your experience (optional)',
                    border: OutlineInputBorder())),
            Text('Photos (${_existingUrls.length + _photos.length}/5)'),
            Wrap(spacing: 8, children: [
              for (var i = 0; i < _existingUrls.length; i++)
                InputChip(
                    label: Text('Photo ${i + 1}'),
                    onDeleted: _saving
                        ? null
                        : () => setState(() => _existingUrls.removeAt(i))),
              for (var i = 0; i < _photos.length; i++)
                InputChip(
                    label: Text('New photo ${i + 1}'),
                    onDeleted: _saving
                        ? null
                        : () => setState(() => _photos.removeAt(i))),
            ]),
            TextButton.icon(
                onPressed: _saving ? null : _addPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add photos')),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save review')),
          ])));
}
````

## File: lib/main.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app's background is light (white/cream), so the status bar's
  // time/battery/signal icons need to render dark to stay visible --
  // otherwise they default to light and blend into the light
  // background, becoming nearly invisible. Set globally here so it
  // applies even on screens that override AppBar styling directly.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    runApp(MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
            'StallSeeker could not start. Check your connection and retry.'),
        TextButton(onPressed: main, child: const Text('Retry')),
      ]),
    )))));
    return;
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const StallSeekerApp());
  unawaited(NotificationService.instance
      .initialize(navigatorKey)
      .catchError((Object error) {
    debugPrint('Notifications are currently unavailable.');
  }));
}

class StallSeekerApp extends StatelessWidget {
  const StallSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'StallSeeker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
````

## File: lib/features/auth/screens/login_screen.dart
````dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

Future<void> showLoginSheet(BuildContext context) {
  final media = MediaQuery.of(context);
  final useDialog = media.size.shortestSide >= 600;

  if (useDialog) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .32),
      builder: (dialogContext) {
        final dialogMedia = MediaQuery.of(dialogContext);
        final availableHeight = dialogMedia.size.height -
            dialogMedia.padding.vertical -
            dialogMedia.viewInsets.bottom -
            64;
        final dialogHeight = availableHeight.clamp(480.0, 660.0).toDouble();

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: 520,
            height: dialogHeight,
            child: const LoginScreen(embeddedInDialog: true),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .28),
    builder: (sheetContext) => AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .90,
        minChildSize: .55,
        maxChildSize: .96,
        snap: true,
        snapSizes: const [.55, .90],
        builder: (_, controller) => LoginScreen(
          embeddedInSheet: true,
          scrollController: controller,
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen(
      {super.key,
      this.embeddedInSheet = false,
      this.embeddedInDialog = false,
      this.scrollController})
      : assert(!(embeddedInSheet && embeddedInDialog));
  final bool embeddedInSheet;
  final bool embeddedInDialog;
  final ScrollController? scrollController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<User?>? _authSub;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null &&
          !user.isAnonymous &&
          mounted &&
          Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    final error =
        await _auth.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      _showError(error);
    }
  }

  Future<void> _google() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null && error != 'cancelled') {
      _showError(error);
    }
  }

  void _close() {
    if (!_busy) {
      Navigator.maybePop(context);
    }
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), backgroundColor: const Color(0xFFB3261E)));

  @override
  void dispose() {
    _authSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: Color(0xFFB3261E))),
      );

  Widget _divider() => const Row(children: [
        Expanded(child: Divider(color: Color(0xFFE3E3E5))),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('OR',
                style: TextStyle(fontSize: 13, color: Color(0xFF77777E)))),
        Expanded(child: Divider(color: Color(0xFFE3E3E5))),
      ]);

  Widget _panel(BuildContext context) => Material(
        color: AppColors.background,
        borderRadius: widget.embeddedInDialog
            ? BorderRadius.circular(28)
            : widget.embeddedInSheet
                ? const BorderRadius.vertical(top: Radius.circular(28))
                : BorderRadius.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          if (widget.embeddedInSheet) ...[
            const SizedBox(height: 10),
            Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: const Color(0xFFD2D2D5),
                    borderRadius: BorderRadius.circular(3))),
          ],
          Expanded(
              child: SingleChildScrollView(
            controller: widget.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
                24,
                widget.embeddedInSheet ? 6 : 18,
                24,
                widget.embeddedInDialog
                    ? 24
                    : MediaQuery.paddingOf(context).bottom + 28),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                            tooltip: 'Close',
                            onPressed: _busy ? null : _close,
                            style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFEAEAEC)),
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF73737A)))),
                    Center(
                        child: Image.asset('assets/app_logo.png',
                            width: 54, height: 54)),
                    const SizedBox(height: 10),
                    const Text('Log in or sign up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.4)),
                    const SizedBox(height: 8),
                    const Text(
                        'Follow favourite stalls and receive live updates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF707078))),
                    const SizedBox(height: 28),
                    TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: _field('Email address'),
                        validator: (value) =>
                            value == null || !value.trim().contains('@')
                                ? 'Enter a valid email address.'
                                : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        decoration: _field('Password',
                            suffix: IconButton(
                                onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword),
                                icon: Icon(_hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined))),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : null),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ForgotPasswordScreen(
                                            initialEmail: _email.text.trim()))),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)))),
                    SizedBox(
                        height: 56,
                        child: FilledButton(
                            onPressed: _busy ? null : _login,
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28))),
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Continue',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)))),
                    const SizedBox(height: 22),
                    _divider(),
                    const SizedBox(height: 18),
                    SizedBox(
                        height: 56,
                        child: OutlinedButton(
                            onPressed: _busy ? null : _google,
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side:
                                    const BorderSide(color: Color(0xFFD5D5D8)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/google_logo.png',
                                      width: 21, height: 21),
                                  const SizedBox(width: 12),
                                  const Text('Continue with Google',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ]))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Color(0xFF707078))),
                      TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                          child: const Text('Sign up',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  ],
                )),
          )),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInSheet || widget.embeddedInDialog) {
      return _panel(context);
    }
    return Scaffold(
        backgroundColor: Colors.white, body: SafeArea(child: _panel(context)));
  }
}
````

## File: lib/features/customer/profile/customer_profile_screen.dart
````dart
import '../../shared/profile_page.dart';
import '../../shared/demo_orders_screen.dart';
import '../../shared/live_booking_section.dart';
import '../../shared/edit_profile_screen.dart';
import '../../shared/personal_information_screen.dart';
import '../../shared/change_password_screen.dart';
import '../../shared/notification_settings_screen.dart';
import '../../shared/legal_screen.dart';
import '../../shared/delete_account_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/faq_screen.dart';
import '../../shared/about_screen.dart';
import '../../shared/logout_helper.dart';
import '../../shared/manual_location_dialog.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.location,
    required this.onLocationChanged,
    this.onHomeLocation,
    this.onCustomLocation,
  });

  final LocationSelection? location;
  final void Function(LocationSelection selection, bool isManual)
      onLocationChanged;
  final VoidCallback? onHomeLocation;
  final VoidCallback? onCustomLocation;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _authService = AuthService();

  UserModel? _userModel;
  bool _isLoading = true;

  late String _locationText;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _locationText =
        widget.location?.label ?? 'Tap to set your preferred location';
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant CustomerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLabel = widget.location?.label;
    if (!_isLoadingLocation &&
        newLabel != null &&
        newLabel != oldWidget.location?.label) {
      _locationText = newLabel;
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userData;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    if (!mounted || _isLoadingLocation) {
      return;
    }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) {
        return;
      }
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services are turned off.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) {
        return;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission not granted.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));

      final coordinates = LatLng(position.latitude, position.longitude);
      String address;
      try {
        address = await describeLocation(coordinates);
      } catch (_) {
        address = 'Current location';
      }

      if (mounted) {
        widget.onLocationChanged(
          LocationSelection(coordinates: coordinates, label: address),
          false,
        );
        setState(() {
          _locationText = address;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _enterLocationManually() async {
    final selection = await showManualLocationDialog(
      context,
      initialLocation: widget.location?.coordinates,
      title: 'Set Your Location',
    );
    if (selection == null || !mounted) {
      return;
    }
    widget.onLocationChanged(selection, true);
    setState(() => _locationText = selection.label);
  }

  // Tapping "Current location" now offers a choice instead of jumping
  // straight to GPS, so a manual entry is always available -- not only
  // as a fallback once GPS has already failed.
  Future<void> _chooseLocation() async {
    if (_isLoadingLocation) {
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Set your location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.my_location_rounded, color: AppColors.primary),
            title: const Text('Use current location'),
            onTap: () => Navigator.pop(ctx, 'current'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_location_alt_outlined,
                color: AppColors.primary),
            title: const Text('Enter manually'),
            subtitle:
                const Text('Search for an area, city, state, or postcode'),
            onTap: () => Navigator.pop(ctx, 'manual'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    if (choice == 'current') {
      await _loadLocation();
    } else {
      await _enterLocationManually();
    }
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => EditProfileScreen(
                name: _userModel?.fullName ?? user?.displayName ?? '',
                email: _userModel?.email ?? user?.email ?? '')));
    if (saved == true && mounted) {
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    }
  }

  Future<void> _personalInformation() async {
    final user = FirebaseAuth.instance.currentUser;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PersonalInformationScreen(
                name: _userModel?.fullName ?? user?.displayName ?? '',
                email: _userModel?.email ?? user?.email ?? '',
                isVendor: false)));
    if (mounted) {
      await _loadUserData();
    }
  }

  void _changePassword() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
                email: _userModel?.email ??
                    FirebaseAuth.instance.currentUser?.email ??
                    '')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest
        ? 'Guest'
        : _userModel?.fullName.isNotEmpty == true
            ? _userModel!.fullName
            : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name,
      email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      photoUrl: guest ? null : user?.photoURL,
      isVendor: false,
      isGuest: guest,
      canChangePassword: user?.providerData
              .any((provider) => provider.providerId == 'password') ??
          false,
      location: _locationText,
      isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _chooseLocation,
      onHomeLocation: widget.onHomeLocation,
      onCustomLocation: widget.onCustomLocation,
      onEdit: _editProfile,
      onPersonalInformation: _personalInformation,
      onOrders: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DemoOrdersScreen(isVendor: false))),
      bookingSection: guest ? null : const LiveBookingSection(isVendor: false),
      onPassword: _changePassword,
      onFaq: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: false))),
      onAbout: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onNotificationSettings: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen())),
      onPrivacyPolicy: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const LegalScreen(page: LegalPage.privacy))),
      onTerms: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const LegalScreen(page: LegalPage.terms))),
      onDeleteAccount: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen())),
    );
  }
}
````

## File: lib/features/vendor/dashboard/vendor_dashboard_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/vendor_location_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';
import '../../shared/manual_location_dialog.dart';
import '../../shared/demo_orders_screen.dart';
import '../../shared/live_booking_section.dart';
import '../../../core/utils/vendor_phone.dart';
import 'vendor_demo_sales.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  VendorDashboardScreenState createState() => VendorDashboardScreenState();
}

class VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _vendorService = VendorService();
  final _location = VendorLocationService.instance;
  StreamSubscription<VendorModel?>? _subscription;
  VendorModel? _vendor;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _location.addListener(_locationChanged);
    fetchVendorDetails();
  }

  void _locationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _location.removeListener(_locationChanged);
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> fetchVendorDetails() async {
    await _subscription?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _subscription = _vendorService.watchVendorProfile(uid).listen((vendor) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vendor = vendor;
        _loading = false;
        _error = null;
      });
      if (vendor?.isOpen != true && _location.isSharing) {
        unawaited(_location.pause());
      }
    }, onError: (Object error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Could not load your stall. Check your connection and retry.';
        });
      }
    });
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on GPS before sharing your location.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Allow location access in your phone settings.');
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Location permission is required.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 12));
  }

  Future<void> _toggle(bool open) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_saving || uid == null) {
      return;
    }
    if (open && (_vendor?.stallName.trim().isEmpty ?? true)) {
      _message('Set up your stall name before opening.');
      return;
    }
    if (open && normalizeVendorPhone(_vendor?.phoneNumber ?? '') == null) {
      _message('Add a business phone number in My stall before opening.');
      return;
    }
    if (open && (_vendor?.isTemporarilyClosed ?? false)) {
      _message('Remove the active temporary closure before opening.');
      return;
    }
    if (open) {
      final agreed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Open stall and share location?'),
                content: const Text(
                    'Your location continues updating while your stall is open, even when you lock your phone or use another app. Android shows a persistent notification while sharing is active.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Open stall')),
                ],
              ));
      if (agreed != true || !mounted) {
        return;
      }
    }
    setState(() => _saving = true);
    try {
      if (open) {
        double? latitude;
        double? longitude;
        var manualLocation = false;
        try {
          final position = await _position();
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (_) {
          if (!mounted) {
            return;
          }
          final existing = _vendor?.hasValidLocation == true
              ? LatLng(_vendor!.latitude, _vendor!.longitude)
              : null;
          final selection = await showManualLocationDialog(context,
              initialLocation: existing, title: 'Set Stall Location Manually');
          if (selection == null || !mounted) {
            return;
          }
          latitude = selection.coordinates.latitude;
          longitude = selection.coordinates.longitude;
          manualLocation = true;
        }
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
          return;
        }
        await _vendorService.updateVendorLocation(uid, latitude, longitude,
            sharingActive: !manualLocation);
        await _vendorService.toggleStallStatus(uid, true);
        if (!manualLocation && mounted) {
          await _location.start(uid);
        }
        if (manualLocation) {
          _message('Your stall is open using the manually entered location.');
        }
      } else {
        await _location.pause();
        await _vendorService.toggleStallStatus(uid, false);
      }
      if (!open) {
        _message('Your stall is closed.');
      }
      if (open && _location.isSharing) {
        _message('Your stall is open.');
      }
    } catch (_) {
      _message(
          'Could not update your stall. Check GPS, location permission, and connection, then retry.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resume() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _position();
      if (mounted && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _location.start(uid);
      }
    } catch (_) {
      _message('Could not share location. Check GPS and location permission.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleDemoSelfCollect(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) return;
    setState(() => _saving = true);
    try {
      await _vendorService.setSelfCollectEnabled(uid, enabled);
      _message(enabled
          ? 'Customers can now pay for self-collect bookings immediately.'
          : 'New self-collect bookings are off.');
    } catch (_) {
      _message('Could not save booking setting. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        TextButton(onPressed: fetchVendorDetails, child: const Text('Retry')),
      ]));
    }
    final open = _vendor?.isOpen ?? false;
    return RefreshIndicator(
      onRefresh: fetchVendorDetails,
      child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            Text(
                _vendor?.stallName.isNotEmpty == true
                    ? _vendor!.stallName
                    : 'Set up your stall',
                style: Theme.of(context).textTheme.headlineSmall),
            const LiveBookingSection(isVendor: true),
            const VendorDemoSales(),
            const SizedBox(height: 16),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_vendor?.isTemporarilyClosed == true
                                  ? 'Temporary closure active'
                                  : open
                                      ? 'Stall open'
                                      : 'Stall closed'),
                              subtitle: Text(_vendor?.isTemporarilyClosed ==
                                      true
                                  ? 'Customers see your stall as closed. The Open switch will turn off shortly.'
                                  : 'Control whether customers can find you on the live map'),
                              value: open,
                              onChanged: _saving ? null : _toggle),
                          if (_saving) const LinearProgressIndicator(),
                          const Divider(),
                          Text(!open
                              ? 'Location sharing off'
                              : _location.error ??
                                  (_location.isSharing
                                      ? 'Location sharing active in the background'
                                      : 'Location sharing paused')),
                          if (open && !_location.isSharing)
                            TextButton.icon(
                                onPressed: _saving ? null : _resume,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Resume sharing')),
                        ]))),
            const SizedBox(height: 16),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                SwitchListTile(
                  title: const Text('Self-collect bookings'),
                  subtitle:
                      const Text('Allow customers to book for collection.'),
                  value: _vendor?.selfCollectEnabled ?? false,
                  onChanged: _saving ? null : _toggleDemoSelfCollect,
                ),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const DemoOrdersScreen(isVendor: true))),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('View current and past bookings'),
                    )),
              ]),
            )),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VendorMenuScreen())),
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Manage menu & stock')),
            const SizedBox(height: 16),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stall information',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(_vendor?.category ?? 'Choose a food category'),
                          Text(_vendor?.hoursToday ?? 'Add your opening hours'),
                          const SizedBox(height: 8),
                          Text(_vendor?.description ??
                              'Tell customers what you sell.'),
                          TextButton.icon(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const EditStallScreen())),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit stall')),
                        ]))),
          ]),
    );
  }
}
````

## File: lib/core/services/auth_service.dart
````dart
// MANAGE ACCOUNT
// - signup, login, signin with google, signinasguest, getuserdata, save cust location, signout, resetpassword, req email verfiy, confir email verify, change password, update anem, delete account

import 'notification_service.dart';
import 'local_demo_booking_service.dart';
import 'vendor_location_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';
import '../utils/vendor_phone.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // connect to firebase auth
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // connect to firestore db
  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance; // connect to google login
  static bool _googleSignInReady = false;

  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) {
      return;
    }
    await _googleSignIn.initialize(
      serverClientId:
          '793011933510-ljrpbsf089fjdmjk58tfo7o1dmg1bmov.apps.googleusercontent.com',
    );
    _googleSignInReady = true;
  }

  // Stream of auth state changes (logged in / logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // repair current user profile
  Future<void> repairCurrentUserProfile() async {
    final user = _auth.currentUser;

    if (user == null || user.isAnonymous) {
      return;
    }

    final userRef =
        _firestore.collection(FirestoreCollections.users).doc(user.uid);

    final userSnapshot = await userRef.get();
    final existingData = userSnapshot.data();
    final existingRole = existingData?['role'];

    if (existingRole == 'customer' || existingRole == 'vendor') {
      return;
    }

    final vendorSnapshot = await _firestore
        .collection(FirestoreCollections.vendors)
        .doc(user.uid)
        .get();

    await userRef.set({
      'uid': user.uid,
      'email': user.email ?? '',
      'fullName': user.displayName ?? '',
      'role': vendorSnapshot.exists ? 'vendor' : 'customer',
      if (existingData?['createdAt'] == null)
        'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Register user with Email, Password, Name & Role
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? vendorPhone,
  }) async {
    try {
      final normalizedPhone =
          role == 'vendor' ? normalizeVendorPhone(vendorPhone ?? '') : null;
      if (role == 'vendor' && normalizedPhone == null) {
        return 'Enter a valid Malaysian business phone number.';
      }
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          fullName: fullName.trim(),
          role: role,
          createdAt: DateTime.now(),
        );

        final batch = _firestore.batch();
        batch.set(
            _firestore
                .collection(FirestoreCollections.users)
                .doc(credential.user!.uid),
            newUser.toMap());
        if (role == 'vendor') {
          batch.set(
              _firestore
                  .collection(FirestoreCollections.vendors)
                  .doc(credential.user!.uid),
              {
                'vendorId': credential.user!.uid,
                'phoneNumber': normalizedPhone,
                'isOpen': false,
              });
        }
        await batch.commit();

        return null;
      }
      return "User creation failed.";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // Login user with Email & Password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInReady();

      final GoogleSignInAccount googleUser = await _googleSignIn
          .authenticate()
          .timeout(const Duration(seconds: 25));

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(
              seconds:
                  25)); // cancel google sign in kalau lebih 25 sec  xbuat apa2
      final user = userCredential.user;

      if (user != null &&
          (userCredential.additionalUserInfo?.isNewUser ?? false)) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          role: 'customer',
          createdAt: DateTime.now(),
        );
        await _firestore // save profile dalam firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .set(newUser.toMap());
      }

      return null;
    } on TimeoutException {
      return "Google sign-in timed out. Check your connection and try again, "
          "or sign in with email.";
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return "cancelled"; // user closed the picker without choosing
      }
      return e.description ?? "Google sign-in failed.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        return "An account already exists with this email. Log in with your email and password instead.";
      }
      return e.message ?? "Google sign-in failed.";
    } catch (e) {
      return e.toString();
    }
  }

// Guest mode
  Future<String?> signInAsGuest() async {
    try {
      await _auth.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Could not start guest session.";
    } catch (e) {
      return e.toString();
    }
  }

  // Fetch current user's data from Firestore                   //  read user id
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return null;
    }
  }

// stores customer location
  Future<String?> saveCustomerLocation({
    required double latitude,
    required double longitude,
    required String label,
    required bool isManual,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return null;
    }
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set({
        'customerLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'label': label,
          'isManual': isManual,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      return null;
    } catch (_) {
      return 'Your location could not be saved.';
    }
  }

  // Sign Out
  // stop vendor location service
  Future<void> signOut() async {
    await VendorLocationService.instance.pause();
    try {
      await NotificationService.instance.clearCurrentDevice();
    } catch (_) {
      debugPrint('Notification cleanup could not finish.');
    }
    try {
      if (_googleSignInReady) {
        await _googleSignIn.signOut();
      }
    } finally {
      await _auth.signOut();
    }
  }

// reset password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      // Give the same result for unknown accounts to avoid exposing sign-ups.
      if (e.code == 'user-not-found') {
        return null;
      }
      if (e.code == 'invalid-email') {
        return 'Enter a valid email address.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many requests. Please wait and try again.';
      }
      if (e.code == 'network-request-failed') {
        return 'Could not connect. Check your network and retry.';
      }
      return 'Could not send the reset link. Please try again.';
    } catch (_) {
      return 'Could not send the reset link. Please try again.';
    }
  }

// Ask Firebase Authentication to send its standard verification link.
  Future<String?> sendEmailVerificationLink() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) {
        return 'Sign in to verify your email.';
      }
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed?.emailVerified == true) return null;
      await refreshed!.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return 'Too many emails were requested. Please wait and try again.';
      }
      if (e.code == 'network-request-failed') {
        return 'Could not connect. Check your network and try again.';
      }
      return e.message ?? 'Could not send the verification email.';
    } catch (_) {
      return 'Could not send the verification email. Please try again.';
    }
  }

// Refresh the user and signed email_verified token after the link is opened.
  Future<String?> refreshEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Your session ended. Please sign in again.';
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed?.emailVerified != true) {
        return 'The email is not verified yet. Open the link in your email first.';
      }
      await refreshed!.getIdToken(true);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not check your verification status.';
    } catch (_) {
      return 'Could not check your verification status. Please try again.';
    }
  }

  Future<String?> sendEmailChangeLink(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) {
        return 'Sign in before changing your email.';
      }
      final email = newEmail.trim();
      if (email.toLowerCase() == (user.email ?? '').toLowerCase()) {
        return 'Enter a different email address.';
      }
      await user.verifyBeforeUpdateEmail(email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'For security, sign out and sign in again before changing your email.';
      }
      if (e.code == 'email-already-in-use') {
        return 'That email is already in use.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many emails were requested. Please wait and try again.';
      }
      return e.message ?? 'Could not send the email-change link.';
    } catch (_) {
      return 'Could not send the email-change link. Please try again.';
    }
  }

  Future<String?> refreshEmailChange(String expectedEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Your session ended. Please sign in again.';
      await user.reload();
      final refreshed = _auth.currentUser;
      if ((refreshed?.email ?? '').toLowerCase() !=
          expectedEmail.trim().toLowerCase()) {
        return 'The new email is not verified yet. Open the link in that email first.';
      }
      await refreshed!.getIdToken(true);
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(refreshed.uid)
          .set({
        'email': refreshed.email,
        'emailVerified': refreshed.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not check the new email.';
    } catch (_) {
      return 'Could not check the new email. Please try again.';
    }
  }

// change password
  Future<String?> changePassword(String newPassword,
      {String? currentPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user is currently logged in.";
      }
      if (currentPassword != null) {
        if (user.email == null ||
            !user.providerData.any((p) => p.providerId == 'password')) {
          return 'Manage your password with your sign-in provider.';
        }
        final credential = EmailAuthProvider.credential(
            email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);
      }
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Your current password is incorrect. Please try again.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please wait and try again.';
      }
      if (e.code == 'network-request-failed') {
        return 'Could not connect. Check your network and retry.';
      }
      if (e.code == 'requires-recent-login') {
        return "For security, please log out and log back in before changing your password.";
      }
      return e.message ?? "Could not change password.";
    } catch (_) {
      return 'Could not update your password. Please try again.';
    }
  }

// update name
  Future<String?> updateFullName(String uid, String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous || user.uid != uid) {
        return 'Please sign in to edit your profile.';
      }
      final name = newName.trim();
      if (name.isEmpty || name.length > 80) {
        return 'Enter a name between 1 and 80 characters.';
      }
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .update({'fullName': name});
      // Firestore is the app's profile source. Sync Auth's display name as well.
      try {
        await user.updateDisplayName(name);
      } catch (_) {
        debugPrint('Profile saved; Auth display-name sync is unavailable.');
      }
      return null;
    } catch (_) {
      return 'Could not save your profile. Please try again.';
    }
  }

// delete account (bug)
  Future<String?> deleteAccount({String? currentPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return 'Sign in before deleting your account.';
    }
    try {
      final providers =
          user.providerData.map((provider) => provider.providerId).toSet();
      if (providers.contains('password')) {
        if (currentPassword == null ||
            currentPassword.isEmpty ||
            user.email == null) {
          return 'Enter your current password.';
        }
        await user.reauthenticateWithCredential(EmailAuthProvider.credential(
            email: user.email!, password: currentPassword));
      } else if (providers.contains('google.com')) {
        await _ensureGoogleSignInReady();
        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        await user.reauthenticateWithCredential(
            GoogleAuthProvider.credential(idToken: googleAuth.idToken));
      } else {
        return 'Log out, sign in again, then retry account deletion.';
      }

      await NotificationService.instance.clearCurrentDevice();
      await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
      try {
        await LocalDemoBookingService().removeAccountData(user.uid);
      } catch (_) {
        debugPrint('Account deleted; local booking cleanup was unavailable.');
      }
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Your current password is incorrect.';
      }
      if (e.code == 'requires-recent-login') {
        return 'Log out, sign in again, then retry account deletion.';
      }
      return e.message ?? 'Could not verify your account.';
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        return 'Your session expired. Sign in and try again.';
      }
      if (e.code == 'failed-precondition') {
        return 'Confirm your sign-in, then retry account deletion.';
      }
      return 'Could not finish account deletion. Please retry.';
    } catch (_) {
      return 'Could not delete your account. Please try again.';
    }
  }
}
````

## File: lib/features/auth/auth_wrapper.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stallseeker/features/auth/screens/welcome_screen.dart';
import 'package:stallseeker/features/vendor/vendor_main_screen.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/core/services/notification_service.dart';
import 'package:stallseeker/core/services/auth_service.dart';
import 'screens/email_verification_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authStream = FirebaseAuth.instance.userChanges();
  bool _guestAccessGranted = false;

  void _grantGuestAccess() {
    if (!mounted) return;
    setState(() => _guestAccessGranted = true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _AccountRecovery(
                message: 'Could not check your session. Please sign in again.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          if (user == null || (user.isAnonymous && !_guestAccessGranted)) {
            return WelcomeScreen(onGuestAccessGranted: _grantGuestAccess);
          }
          if (user.isAnonymous) {
            return const CustomerHomeScreen();
          }
          if (!user.emailVerified) {
            NotificationService.instance.setNavigationReady(false);
            return EmailVerificationScreen(key: ValueKey('verify-${user.uid}'));
          }
          return _AccountGate(key: ValueKey(user.uid), user: user);
        });
  }
}

class _AccountGate extends StatefulWidget {
  const _AccountGate({super.key, required this.user});
  final User user;
  @override
  State<_AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<_AccountGate> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _profile;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _profile = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();
    unawaited(AuthService().repairCurrentUserProfile().catchError(
          (Object error) => debugPrint('Account profile repair failed: $error'),
        ));
  }

  @override
  void dispose() {
    NotificationService.instance.setNavigationReady(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data?.data()?['role'];
        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists ||
            (role != 'vendor' && role != 'customer')) {
          NotificationService.instance.setNavigationReady(false);
          return _AccountRecovery(
            message: snapshot.hasError
                ? 'Could not load your account. Check your connection and retry.'
                : 'Your account setup is incomplete. Retry, or sign out and contact support.',
            retry: () => setState(_listen),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NotificationService.instance.setNavigationReady(true);
            unawaited(NotificationService.instance.configureForRole(role));
          }
        });
        return role == 'vendor'
            ? const VendorMainScreen()
            : const CustomerHomeScreen();
      },
    );
  }
}

class _AccountRecovery extends StatelessWidget {
  const _AccountRecovery({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Retry')),
          TextButton(
              onPressed: () async {
                try {
                  await AuthService().signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Could not sign out. Please retry.')));
                  }
                }
              },
              child: const Text('Sign out')),
        ]),
      )));
}
````

## File: lib/features/customer/home/customer_home_screen.dart
````dart
import '../../../core/services/notification_history_service.dart';
import '../../../core/services/demo_order_service.dart';
import '../notifications/customer_notifications_screen.dart';
import 'dart:async'; // bawak time, future dan unawaited
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_pill_navigation.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/constants/stall_categories.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/models/dish_search_entry.dart';
import 'open_at_picker.dart';
import 'discovery_search_filters.dart';
import 'price_range_picker.dart';
import 'map_marker_focus.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/dish_search_service.dart';
import '../../../core/services/search_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../following/customer_following_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../../shared/profile_page.dart';
import '../vendor_details/vendor_details_screen.dart';
import '../../shared/manual_location_dialog.dart';
import '../../shared/saved_locations_sheet.dart';
import '../../shared/pin_location_screen.dart';
import '../../../core/widgets/app_dropdown.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _vendorService = VendorService(); // loads vendor
  final _authService = AuthService(); // loads customer info
  final _dishSearchService = DishSearchService();
  final _searchHistoryService = SearchHistoryService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Stream<int>? _unreadCount;
  Stream<int>? _bookingUnreadCount;

  int _selectedIndex = 0;
  String _searchQuery = '';
  GoogleMapController? _mapController; // move the map dan zoom
  LatLng? _customerPosition;
  String? _customerLocationLabel;
  double _searchRadiusKm = 5;

  // NEW: Track the visible map area to filter vendors
  LatLngBounds? _visibleBounds;
  LatLngBounds? _pendingBounds;
  LatLng? _mapCenter;
  CameraPosition? _lastCameraPosition;
  final ValueNotifier<double> _mapBearing = ValueNotifier(0);
  LatLng? _searchCenter;
  bool _showSearchArea = false;
  bool _programmaticCameraMove = false;
  Timer? _cameraMoveGuard;
  bool _cameraMovedByUser = false;
  int _boundsRequest = 0;
  OpeningTimeFilter? _openingTime;
  MenuPriceRange? _priceRange;

  final List<String> _tabTitles = [
    'Home',
    'Following',
    'Notifications',
    'Settings'
  ];
  String _greeting = 'Guest';

  static const _mapStyle = '''[
    {"featureType":"all","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f7f2e3"}]},
    {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#d9efd9"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#cce9d0"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ebe9df"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d9d9ce"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#bfdfe7"}]},
    {"featureType":"transit","elementType":"geometry","stylers":[{"visibility":"off"}]}
  ]''';

  String get _welcomeLine {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$salutation, $_greeting 👋';
  }

  String? _selectedVendorId;
  bool _isLocatingCustomer = true;
  bool _locationPermissionGranted = false;
  String? _locationError;
  String? _category;
  String _statusFilter = 'Open';
  Timer? _freshnessTimer;
  late Stream<List<VendorModel>> _vendors;
  StreamSubscription<List<DishSearchEntry>>? _dishSubscription;
  List<DishSearchEntry> _allDishes = const [];
  List<String> _recentSearches = const [];
  bool _dishesLoading = true;
  String? _dishSearchError;
  final ScrollController _stallScrollController = ScrollController();
  List<VendorModel> _visibleVendors = [];
  List<VendorModel> _markerVendors = [];
  double _cardExtent = 288;
  int _cameraRequest = 0;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

// cari vendor data, tgk notification, loads customer location, name for greeting
  @override
  void initState() {
    super.initState();
    _vendors = _vendorService.getAllVendors();
    _searchFocus.addListener(_onSearchFocusChanged);
    _dishSubscription = _dishSearchService.watchAllDishes().listen(
      (dishes) {
        if (!mounted) return;
        setState(() {
          _allDishes = dishes;
          _dishesLoading = false;
          _dishSearchError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _dishesLoading = false;
          _dishSearchError = 'Could not load dishes.';
        });
      },
    );
    unawaited(_loadRecentSearches());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      _unreadCount = NotificationHistoryService().watchUnreadCount(user.uid);
      _bookingUnreadCount =
          DemoOrderService().watchUnseenCount(user.uid, isVendor: false);
    }
    _initializeCustomerLocation();
    _loadGreeting();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // refresh location setiap 30sec
      if (mounted) {
        setState(() {});
      }
    });
  }

// bila customer leave app dia clean up
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _dishSubscription?.cancel();
    _mapController?.dispose();
    _mapBearing.dispose();
    _stallScrollController.dispose();
    _freshnessTimer?.cancel();
    _cameraMoveGuard?.cancel();
    super.dispose();
  }

  void _expectProgrammaticCameraMove() {
    _programmaticCameraMove = true;
    _cameraMoveGuard?.cancel();
    _cameraMoveGuard = Timer(const Duration(seconds: 3), () {
      _programmaticCameraMove = false;
    });
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentSearches() async {
    try {
      await _searchHistoryService.mergeGuestHistoryIntoCustomerAccount();
      final recent = await _searchHistoryService.loadRecent();
      if (mounted) setState(() => _recentSearches = recent);
    } catch (_) {
      // Search still works when history is unavailable.
    }
  }

  void _submitSearch(String rawQuery) {
    final query = rawQuery.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.isEmpty) return;
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(offset: query.length);
    setState(() {
      _searchQuery = query;
      _selectedVendorId = null;
      _recentSearches = [
        query,
        ..._recentSearches
            .where((item) => item.toLowerCase() != query.toLowerCase()),
      ].take(10).toList();
    });
    _searchFocus.unfocus();
    unawaited(_searchHistoryService.save(query).catchError((Object error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Search worked, but history could not be saved.')));
      }
    }));
  }

  Future<void> _removeRecentSearch(String query) async {
    setState(() => _recentSearches = _recentSearches
        .where((item) => item.toLowerCase() != query.toLowerCase())
        .toList());
    try {
      await _searchHistoryService.remove(query);
    } catch (_) {
      if (mounted) await _loadRecentSearches();
    }
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches = const []);
    try {
      await _searchHistoryService.clear();
    } catch (_) {
      if (mounted) await _loadRecentSearches();
    }
  }

  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    if (user.isAnonymous) {
      if (mounted) {
        setState(() => _greeting = 'Guest');
      }
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final name = userData?.fullName;
    if (mounted) {
      setState(() {
        _greeting = (name != null && name.trim().isNotEmpty)
            ? name.trim().split(RegExp(r'\s+')).first
            : 'Guest';
      });
    }
  }

  bool _locationRequestActive = false;
  int _locationSelectionVersion = 0;

  Future<void> _initializeCustomerLocation() async {
    final selectionVersion = _locationSelectionVersion;
    // check kalau customer ada saved location, kalau takde baru call getcustomerlocation
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final userData = await _authService.getUserData(user.uid);
      if (!mounted || selectionVersion != _locationSelectionVersion) {
        return;
      }
      if (userData?.hasCustomerLocation == true) {
        _applyCustomerLocation(
          LocationSelection(
            coordinates: LatLng(
              userData!.customerLatitude!,
              userData.customerLongitude!,
            ),
            label: userData.customerLocationLabel ?? 'Selected location',
          ),
          userData.customerLocationIsManual,
          persist: false, // false for check cust loc, it move to get cust loc
        );
        setState(() => _isLocatingCustomer = false);
        return;
      }
    }
    if (mounted && selectionVersion == _locationSelectionVersion) {
      await _getCustomerLocation(); // get cust loc
    }
  }

  void _applyCustomerLocation(
    LocationSelection selection,
    bool isManual, {
    bool persist = true,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      // default
      _locationSelectionVersion++;
      _isLocatingCustomer = false;
      _selectedVendorId = null;
      _customerPosition = selection.coordinates;
      _searchCenter = selection.coordinates;
      _visibleBounds = null;
      _showSearchArea = false;
      _customerLocationLabel = selection.label;
      _locationPermissionGranted = !isManual;
      _locationError = null; // buang error
    });
    final controller = _mapController;
    if (controller != null) _expectProgrammaticCameraMove();
    controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
          selection.coordinates,
          isManual
              ? 13.5
              : 15), // moves map. 13.5 size kalau manual, 15 gps (closer)
    );
    if (persist) {
      unawaited(_authService.saveCustomerLocation(
        latitude: selection.coordinates.latitude,
        longitude: selection.coordinates.longitude,
        label: selection.label,
        isManual: isManual,
      ));
    }
  }

  Future<void> _getCustomerLocation() async {
    if (_isLocatingCustomer && _locationRequestActive) {
      return;
    }
    _locationRequestActive = true;
    final selectionVersion = _locationSelectionVersion;
    if (mounted) {
      setState(() {
        _isLocatingCustomer = true;
        _locationError = null;
        _locationPermissionGranted = false;
      });
    }
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled(); // check gps bukak ke tak
      if (!serviceEnabled) {
        throw StateError('Turn on GPS, or browse the map manually.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission(); // check gps permission
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || // customer reject
          permission == LocationPermission.deniedForever) {
        // customer kena allow gps thru setting phone
        throw StateError(permission == LocationPermission.deniedForever
            ? 'Allow location access in phone settings, or browse manually.'
            : 'Location access denied. You can still browse the map.');
      }

      final position = await Geolocator.getCurrentPosition(
        // read coordinate lepas allow gps, 12s limit kalau x, set manual
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) {
        return;
      }
      final coordinates = LatLng(position.latitude, position.longitude);
      String label;
      try {
        label = await describeLocation(coordinates);
      } catch (_) {
        label = 'Current location';
      }
      if (!mounted || selectionVersion != _locationSelectionVersion) return;
      _applyCustomerLocation(
        LocationSelection(coordinates: coordinates, label: label),
        false,
      );
    } catch (error) {
      if (mounted && selectionVersion == _locationSelectionVersion) {
        setState(() {
          _locationError = error is StateError
              ? error.message.toString()
              : 'Could not find your location. Retry or browse the map manually.';
        });
      }
    } finally {
      _locationRequestActive = false;
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  Future<void> _enterCustomerLocationManually() async {
    final selection = await showManualLocationDialog(
      context,
      initialLocation: _customerPosition ?? _defaultPosition.target,
      title: 'Set Search Location',
    );

    if (selection == null || !mounted) {
      return;
    }

    _applyCustomerLocation(selection, true);
  }

  void _setSearchRadius(double radius) {
    setState(() => _searchRadiusKm = radius);
    final center = _searchCenter ?? _customerPosition;
    _visibleBounds = null;
    if (center != null) {
      if (_mapController != null) _expectProgrammaticCameraMove();
      final zoom = switch (radius) {
        <= 5 => 13.5,
        <= 10 => 12.5,
        <= 25 => 11.0,
        _ => 10.0,
      };
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(center, zoom));
    }
  }

  Future<void> _chooseSavedLocation({String? type}) async {
    final selection = await showSavedLocationsSheet(context,
        initialLocation:
            _searchCenter ?? _customerPosition ?? _defaultPosition.target,
        initialType: type);
    if (!mounted || selection == null) return;
    _applyCustomerLocation(selection, true);
  }

  Future<void> _pinSearchLocation() async {
    final selection = await Navigator.push<LocationSelection>(
        context,
        MaterialPageRoute(
            builder: (_) => PinLocationScreen(
                initialLocation: _searchCenter ??
                    _customerPosition ??
                    _defaultPosition.target)));
    if (!mounted || selection == null) return;
    _applyCustomerLocation(selection, true);
  }

  // ui for set location, enter manually button
  Future<void> _chooseLocationSource() async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Set your location',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppGroupedCard(children: [
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.my_location_rounded, color: Color(0xFF43CE72)),
                title: const Text('Use current location'),
                subtitle: const Text('Find stalls near where you are now'),
                onTap: () => Navigator.pop(ctx, 'current'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.search_rounded, color: AppColors.primary),
                title: const Text('Enter manually'),
                subtitle:
                    const Text('Search for an area, city, state, or postcode'),
                onTap: () => Navigator.pop(ctx, 'manual'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.push_pin_rounded, color: Color(0xFFFFAE22)),
                title: const Text('Pin on map'),
                subtitle: const Text('Choose an exact search location'),
                onTap: () => Navigator.pop(ctx, 'pin'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.home_rounded, color: Color(0xFFAD55E8)),
                title: const Text('Home & saved places'),
                subtitle: const Text('Save and choose Home or custom pins'),
                onTap: () => Navigator.pop(ctx, 'saved'),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    if (choice == 'current') {
      await _getCustomerLocation();
    } else if (choice == 'saved') {
      await _chooseSavedLocation();
    } else if (choice == 'pin') {
      await _pinSearchLocation();
    } else {
      await _enterCustomerLocationManually();
    }
  }

  Future<void> _selectVendor(VendorModel vendor) async {
    if (!vendor.hasValidLocation) {
      return;
    }
    FocusScope.of(context).unfocus();
    final request = ++_cameraRequest;
    setState(() {
      _selectedVendorId = vendor.vendorId;
    });
    _revealSelectedCard();
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    _expectProgrammaticCameraMove();
    try {
      final currentZoom = await controller.getZoomLevel();
      if (!mounted || request != _cameraRequest) {
        return;
      }

      final targetZoom =
          currentZoom < 16 ? 16.0 : currentZoom.clamp(16.0, 17.5).toDouble();
      await controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(vendor.latitude, vendor.longitude),
        targetZoom,
      ));
    } catch (_) {
      // A controller may be disposed while the user changes screens.
      if (request == _cameraRequest) {
        _programmaticCameraMove = false;
        _cameraMoveGuard?.cancel();
      }
    }
  }

  void _revealSelectedCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stallScrollController.hasClients) {
        return;
      }
      final index =
          _visibleVendors.indexWhere((v) => v.vendorId == _selectedVendorId);
      if (index < 0) {
        return;
      }
      final offset = (index * _cardExtent)
          .clamp(
            0.0,
            _stallScrollController.position.maxScrollExtent,
          )
          .toDouble();
      _stallScrollController.animateTo(offset,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    });
  }

  // NEW: Update the visible bounds whenever the map stops moving
  void _updateVisibleBounds() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    final request = ++_boundsRequest;
    final movedByUser = _cameraMovedByUser && !_programmaticCameraMove;
    _cameraMovedByUser = false;
    final center = _lastCameraPosition?.target ?? _mapCenter;
    try {
      final bounds = await controller.getVisibleRegion();
      if (mounted && request == _boundsRequest) {
        final focused = movedByUser && center != null
            ? stallNearMapCenter(
                center: center,
                bounds: bounds,
                vendors: _markerVendors,
              )
            : null;
        setState(() {
          _pendingBounds = bounds;
          if (movedByUser && focused != null) {
            _visibleBounds = bounds;
            _searchCenter = center;
            _showSearchArea = false;
            _selectedVendorId = focused.vendorId;
          } else if (_programmaticCameraMove && _selectedVendorId != null) {
            _visibleBounds = bounds;
            _showSearchArea = false;
          } else if (_visibleBounds == null) {
            _visibleBounds = bounds;
            _showSearchArea = false;
          } else if (!_programmaticCameraMove) {
            final previous = _visibleBounds!;
            _showSearchArea =
                (previous.southwest.latitude - bounds.southwest.latitude)
                            .abs() >
                        0.0001 ||
                    (previous.southwest.longitude - bounds.southwest.longitude)
                            .abs() >
                        0.0001 ||
                    (previous.northeast.latitude - bounds.northeast.latitude)
                            .abs() >
                        0.0001 ||
                    (previous.northeast.longitude - bounds.northeast.longitude)
                            .abs() >
                        0.0001;
          }
          _programmaticCameraMove = false;
          _cameraMoveGuard?.cancel();
        });
        _revealSelectedCard();
      }
    } catch (_) {
      // Controller may have been disposed during navigation.
      _programmaticCameraMove = false;
      _cameraMoveGuard?.cancel();
    }
  }

  void _searchThisArea() {
    if (_pendingBounds == null || _mapCenter == null) return;
    setState(() {
      _visibleBounds = _pendingBounds;
      _searchCenter = _mapCenter;
      _showSearchArea = false;
      _selectedVendorId = null;
    });
    if (_stallScrollController.hasClients) _stallScrollController.jumpTo(0);
  }

  Future<void> _resetCompass() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      _expectProgrammaticCameraMove();
      final camera = _lastCameraPosition;
      final zoom = camera?.zoom ?? await controller.getZoomLevel();
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: camera?.target ??
                _mapCenter ??
                _searchCenter ??
                _customerPosition ??
                _defaultPosition.target,
            zoom: zoom,
            bearing: 0,
            tilt: 0,
          ),
        ),
      );
    } catch (_) {
      // The map may be disposed while the user changes screens.
    }
  }

  Future<void> _chooseOpeningTime() async {
    final result = await showOpeningTimePicker(context);
    if (result == null || !mounted) return;
    setState(() {
      _openingTime = result;
      _statusFilter = 'All';
    });
  }

  Future<void> _choosePriceRange() async {
    _searchFocus.unfocus();
    final result =
        await showPriceRangePicker(context, initialRange: _priceRange);
    if (result == null || !mounted) return;
    setState(() {
      _priceRange = result.isActive ? result : null;
      _selectedVendorId = null;
    });
    if (_stallScrollController.hasClients) _stallScrollController.jumpTo(0);
  }

  bool _matchesOpening(VendorModel vendor) {
    final filter = _openingTime;
    if (filter != null) {
      return filter.end == null
          ? vendor.isScheduledOpenAt(filter.start)
          : hasScheduledOpening(filter.start, filter.end!, vendor.weeklyHours,
              vendor.temporaryClosures);
    }
    if (_statusFilter == 'Open') return vendor.isOpenNow;
    if (_statusFilter == 'Closed') return !vendor.isOpenNow;
    return true;
  }

  String _stallStatus(VendorModel vendor) => _openingTime != null
      ? 'Scheduled open'
      : vendor.isOpenNow
          ? 'Open now'
          : 'Closed';

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m away';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor:
          _selectedIndex == 3 ? ProfilePage.background : AppColors.background,
      appBar: _selectedIndex == 0 || _selectedIndex == 3
          ? null
          : AppBar(
              title: Text(
                _tabTitles[_selectedIndex],
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(top: true, bottom: false, child: _buildMapTab()),
          const CustomerFollowingScreen(),
          const CustomerNotificationsScreen(),
          CustomerProfileScreen(
            location: _customerPosition == null
                ? null
                : LocationSelection(
                    coordinates: _customerPosition!,
                    label: _customerLocationLabel ?? 'Selected location',
                  ),
            onLocationChanged: _applyCustomerLocation,
            onHomeLocation: () => _chooseSavedLocation(type: 'home'),
            onCustomLocation: () => _chooseSavedLocation(type: 'custom'),
          ),
        ],
      ),
      bottomNavigationBar: AppPillNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);

          if (index == 0) {
            unawaited(_loadGreeting());
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Following',
          ),
          NavigationDestination(
            icon: _notificationIcon(false),
            selectedIcon: _notificationIcon(true),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: _settingsIcon(false),
            selectedIcon: _settingsIcon(true),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _mapHeader() => Row(children: [
        Expanded(
          child: Material(
            color: AppColors.cardColor.withValues(alpha: .94),
            elevation: 3,
            shadowColor: const Color(0x18000000),
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _chooseLocationSource,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
                child: Row(children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.mint,
                    child:
                        Icon(Icons.person_rounded, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_welcomeLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.place_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                            child: Text(
                                _customerLocationLabel ?? 'Set your location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted))),
                      ]),
                    ],
                  )),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.cardColor.withValues(alpha: .94),
          elevation: 3,
          shadowColor: const Color(0x18000000),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => _selectedIndex = 2),
            icon: _notificationIcon(false),
          ),
        ),
      ]);

  Widget _notificationIcon(bool selected) => StreamBuilder<int>(
        stream: _unreadCount,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Badge(
            isLabelVisible: count > 0,
            label: Text(count >= 100 ? '99+' : '$count'),
            child: Icon(
              selected ? Icons.notifications : Icons.notifications_none_rounded,
            ),
          );
        },
      );

  Widget _settingsIcon(bool selected) => StreamBuilder<int>(
        stream: _bookingUnreadCount,
        builder: (context, snapshot) => Badge(
          isLabelVisible: (snapshot.data ?? 0) > 0,
          label:
              Text((snapshot.data ?? 0) > 99 ? '99+' : '${snapshot.data ?? 0}'),
          child: Icon(selected ? Icons.settings : Icons.settings_outlined),
        ),
      );

  IconData _suggestionIcon(DiscoverySuggestion suggestion) =>
      switch (suggestion.kind) {
        DiscoverySuggestionKind.dish => Icons.restaurant_menu_rounded,
        DiscoverySuggestionKind.stall => Icons.storefront_rounded,
        DiscoverySuggestionKind.category => Icons.category_outlined,
        DiscoverySuggestionKind.recent => Icons.history_rounded,
      };

  Widget _suggestionPanel(List<DiscoverySuggestion> suggestions) => Material(
        elevation: 7,
        shadowColor: const Color(0x33000000),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 304),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              if (_searchController.text.trim().isEmpty &&
                  _recentSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 6, 0),
                  child: Row(children: [
                    const Expanded(
                        child: Text('Recent searches',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                    TextButton(
                        onPressed: _clearRecentSearches,
                        child: const Text('Clear')),
                  ]),
                ),
              for (final suggestion in suggestions)
                ListTile(
                  dense: true,
                  leading: Icon(_suggestionIcon(suggestion),
                      size: 20, color: const Color(0xFF64748B)),
                  title: Text(suggestion.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(suggestion.detail),
                  trailing: suggestion.isRecent
                      ? IconButton(
                          tooltip: 'Remove recent search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              _removeRecentSearch(suggestion.label))
                      : const Icon(Icons.north_west_rounded, size: 17),
                  onTap: () => _submitSearch(suggestion.label),
                ),
            ],
          ),
        ),
      );

  Widget _buildMapTab() {
    return StreamBuilder<List<VendorModel>>(
      stream: _vendors,
      builder: (context, snapshot) {
        final allVendors = (snapshot.data ?? [])
            .where((v) =>
                v.hasValidLocation &&
                (_category == null || v.category == _category))
            .toList();

        final query = normalizeDiscoveryQuery(_searchQuery);
        final dishesByVendor = <String, List<DishSearchEntry>>{};
        for (final dish in _allDishes) {
          (dishesByVendor[dish.vendorId] ??= []).add(dish);
        }
        final matchingDishVendorIds = query.isEmpty
            ? const <String>{}
            : _allDishes
                .where((dish) =>
                    normalizeDiscoveryQuery(dish.item.name).contains(query) &&
                    (_priceRange == null || _priceRange!.contains(dish)))
                .map((dish) => dish.vendorId)
                .toSet();
        final matchingVendors = allVendors.where((vendor) {
          final dishMatches = matchingDishVendorIds.contains(vendor.vendorId);
          // A dish search must show every nearby seller, including closed
          // stalls, so the customer can compare availability and status.
          if (!dishMatches && !_matchesOpening(vendor)) return false;
          return vendorMatchesQueryAndPrice(
            vendor: vendor,
            dishes: dishesByVendor[vendor.vendorId] ?? const [],
            query: query,
            priceRange: _priceRange,
          );
        });
        final filteredVendors = matchingVendors.where((vendor) {
          final position = _searchCenter ?? _customerPosition;
          if (position == null) {
            return true;
          }
          return Geolocator.distanceBetween(position.latitude,
                  position.longitude, vendor.latitude, vendor.longitude) <=
              _searchRadiusKm * 1000;
        }).toList();
        _markerVendors = filteredVendors;

        final filteredVendorById = {
          for (final vendor in filteredVendors) vendor.vendorId: vendor,
        };
        final dishResults = query.isEmpty
            ? <DishSearchEntry>[]
            : _allDishes
                .where((dish) =>
                    normalizeDiscoveryQuery(dish.item.name).contains(query) &&
                    (_priceRange == null || _priceRange!.contains(dish)) &&
                    filteredVendorById.containsKey(dish.vendorId))
                .toList()
          ..sort((a, b) {
            final vendorA = filteredVendorById[a.vendorId]!;
            final vendorB = filteredVendorById[b.vendorId]!;
            final center = _searchCenter ?? _customerPosition;
            if (center != null) {
              final distanceA = Geolocator.distanceBetween(center.latitude,
                  center.longitude, vendorA.latitude, vendorA.longitude);
              final distanceB = Geolocator.distanceBetween(center.latitude,
                  center.longitude, vendorB.latitude, vendorB.longitude);
              final distanceOrder = distanceA.compareTo(distanceB);
              if (distanceOrder != 0) return distanceOrder;
            }
            return a.item.name
                .toLowerCase()
                .compareTo(b.item.name.toLowerCase());
          });
        final suggestionVendors = allVendors.where((vendor) {
          final center = _searchCenter ?? _customerPosition;
          return center == null ||
              Geolocator.distanceBetween(center.latitude, center.longitude,
                      vendor.latitude, vendor.longitude) <=
                  _searchRadiusKm * 1000;
        });
        final suggestions = buildDiscoverySuggestions(
          query: _searchController.text,
          vendors: suggestionVendors,
          dishes: _allDishes,
          categories: stallCategories,
          recentSearches: _recentSearches,
          priceRange: _priceRange,
        );
        final showSuggestions = _searchFocus.hasFocus && suggestions.isNotEmpty;
        final showingDishResults = query.isNotEmpty &&
            dishResults.isNotEmpty &&
            _selectedVendorId == null;

        // NEW: Filter to only vendors that are physically inside the current map view
        var onScreenVendors = List<VendorModel>.from(filteredVendors);

        if (_visibleBounds != null) {
          final southWest = _visibleBounds!.southwest;
          final northEast = _visibleBounds!.northeast;

          onScreenVendors = onScreenVendors.where((v) {
            return v.latitude >= southWest.latitude &&
                v.latitude <= northEast.latitude &&
                v.longitude >= southWest.longitude &&
                v.longitude <= northEast.longitude;
          }).toList();
        }

        // Sort by distance for easier viewing
        onScreenVendors.sort((a, b) {
          final sortCenter = _searchCenter ?? _customerPosition;
          if (sortCenter == null) {
            return 0;
          }
          final distA = Geolocator.distanceBetween(
            sortCenter.latitude,
            sortCenter.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = Geolocator.distanceBetween(
            sortCenter.latitude,
            sortCenter.longitude,
            b.latitude,
            b.longitude,
          );
          return distA.compareTo(distB);
        });

        _visibleVendors = onScreenVendors;

        final markers = filteredVendors
            .map(
              (v) => Marker(
                markerId: MarkerId(v.vendorId),
                position: LatLng(v.latitude, v.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  v.vendorId == _selectedVendorId
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(
                  title: v.stallName,
                  snippet: '${v.category} · ${_stallStatus(v)}',
                  onTap: () => _openVendorDetails(v),
                ),
                consumeTapEvents: true,
                onTap: () => _selectVendor(v),
              ),
            )
            .toSet();
        final searchPosition = _searchCenter ?? _customerPosition;
        if (searchPosition != null) {
          markers.add(Marker(
            markerId: const MarkerId('customer-search-location'),
            position: searchPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
                title: 'Search location',
                snippet: searchPosition == _customerPosition
                    ? _customerLocationLabel ?? 'Selected location'
                    : 'Selected map area'),
          ));
        }

        return LayoutBuilder(builder: (context, constraints) {
          final shortViewport = constraints.maxHeight < 400;

          // With Scaffold.extendBody enabled, this includes the
          // floating navigation bar and the device's bottom inset.
          final navClearance = MediaQuery.paddingOf(context).bottom + 12;

          const headerHeight = 52.0;
          final cardAreaHeight =
              shortViewport ? 0.0 : (showingDishResults ? 144.0 : 112.0);
          final panelHeight = headerHeight + cardAreaHeight + navClearance;

          final resultCount =
              showingDishResults ? dishResults.length : onScreenVendors.length;
          final resultLabel = showingDishResults
              ? (resultCount == 1 ? 'dish nearby' : 'dishes nearby')
              : query.isEmpty
                  ? (resultCount == 1
                      ? 'stall in this area'
                      : 'stalls in this area')
                  : (resultCount == 1
                      ? 'matching stall in this area'
                      : 'matching stalls in this area');

          final useSidePanel =
              constraints.maxWidth >= 900 && constraints.maxHeight >= 600;
          final sidePanelWidth = math.min(420.0, constraints.maxWidth * .38);

          final cardWidth = constraints.maxWidth >= 600
              ? (!showingDishResults && onScreenVendors.length == 1
                  ? math.min(520.0, constraints.maxWidth - 32)
                  : 320.0)
              : (constraints.maxWidth * .84).clamp(220.0, 360.0).toDouble();

          final overlayWidth = math.max(
            0.0,
            constraints.maxWidth - (useSidePanel ? sidePanelWidth + 40 : 24),
          );
          final sidePanelHeight = math.min(
            math.max(
              180.0,
              constraints.maxHeight - 12 - navClearance - 80,
            ),
            74.0 +
                math.max(1, resultCount) * (showingDishResults ? 144.0 : 112.0),
          );

          _cardExtent = useSidePanel
              ? (showingDishResults ? 144.0 : 112.0)
              : cardWidth + 12;
          // Full map with a floating results panel on tablets.
          return Stack(children: [
            Positioned.fill(
                bottom: useSidePanel ? 0 : panelHeight,
                child: Stack(children: [
                  Positioned.fill(
                      child: GoogleMap(
                    style: _mapStyle,
                    initialCameraPosition: _defaultPosition,
                    markers: markers,
                    myLocationEnabled: _locationPermissionGranted,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      206,
                      useSidePanel ? sidePanelWidth + 28 : 12,
                      useSidePanel ? navClearance + 80 : 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_customerPosition != null) {
                        _expectProgrammaticCameraMove();
                        controller.animateCamera(
                            CameraUpdate.newLatLngZoom(_customerPosition!, 15));
                      }
                      _updateVisibleBounds();
                    },
                    onCameraMove: (position) {
                      _mapCenter = position.target;
                      _lastCameraPosition = position;
                      if ((_mapBearing.value - position.bearing).abs() > .1) {
                        _mapBearing.value = position.bearing;
                      }
                    },
                    onCameraMoveStarted: () {
                      _boundsRequest++;
                      if (!_programmaticCameraMove) _cameraMovedByUser = true;
                    },
                    onCameraIdle: _updateVisibleBounds,
                    onTap: (_) {
                      FocusScope.of(context).unfocus();
                    },
                  )),
                  Positioned(
                      top: 12,
                      left: 12,
                      child:
                          SizedBox(width: overlayWidth, child: _mapHeader())),
                  Positioned(
                      top: 76,
                      left: 12,
                      child: SizedBox(
                          width: overlayWidth,
                          child: Material(
                            elevation: 3,
                            shadowColor: const Color(0x22000000),
                            color: AppColors.cardColor.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(25),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              textInputAction: TextInputAction.search,
                              onTap: () => setState(() {}),
                              onChanged: (value) => setState(() {
                                _searchQuery = value;
                                _selectedVendorId = null;
                              }),
                              onSubmitted: _submitSearch,
                              decoration: InputDecoration(
                                filled: false,
                                hintText: 'Search dishes or stalls…',
                                hintStyle: const TextStyle(
                                    fontSize: 13, color: AppColors.textMuted),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                prefixIcon: const Icon(Icons.search_rounded,
                                    color: AppColors.textMuted),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear search',
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        })
                                    : AppDropdown<String>(
                                        value: _category ?? 'All',
                                        iconOnly: true,
                                        icon: Icons.tune_rounded,
                                        hint: 'Filter category',
                                        options: {
                                          'All': 'All',
                                          for (final category
                                              in stallCategories)
                                            category: category,
                                        },
                                        onChanged: (value) => setState(() {
                                          _category =
                                              value == 'All' ? null : value;
                                          _selectedVendorId = null;
                                        }),
                                      ),
                              ),
                            ),
                          ))),
                  Positioned(
                      top: 134,
                      left: 12,
                      right: useSidePanel ? sidePanelWidth + 28 : 12,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          ActionChip(
                              avatar: const Icon(
                                  Icons.edit_location_alt_outlined,
                                  size: 18),
                              label: const Text('Set location'),
                              onPressed: _chooseLocationSource),
                          const SizedBox(width: 8),
                          AppDropdown<String>(
                            value: _statusFilter,
                            displayText:
                                _openingTime != null ? 'Scheduled' : null,
                            width: 155,
                            compact: true,
                            hint: 'Choose stall status',
                            icon: Icons.storefront_outlined,
                            options: const {
                              'Open': 'Open now',
                              'Closed': 'Closed',
                              'All': 'All stalls',
                            },
                            onChanged: (status) => setState(() {
                              _statusFilter = status;
                              _openingTime = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          AppDropdown<String>(
                            value: _category ?? 'All',
                            displayText: _category ?? 'All categories',
                            width: 190,
                            compact: true,
                            hint: 'Choose category',
                            icon: Icons.category_outlined,
                            options: {
                              'All': 'All',
                              for (final category in stallCategories)
                                category: category,
                            },
                            onChanged: (value) => setState(() {
                              _category = value == 'All' ? null : value;
                              _selectedVendorId = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          InputChip(
                            avatar:
                                const Icon(Icons.payments_outlined, size: 18),
                            label: Text(_priceRange?.label ?? 'Any price'),
                            onPressed: _choosePriceRange,
                            onDeleted: _priceRange == null
                                ? null
                                : () => setState(() {
                                      _priceRange = null;
                                      _selectedVendorId = null;
                                    }),
                          ),
                          const SizedBox(width: 8),
                          InputChip(
                            avatar: const Icon(Icons.schedule, size: 18),
                            label: Text(_openingTime?.label ?? 'Open at…'),
                            onPressed: _chooseOpeningTime,
                            onDeleted: _openingTime == null
                                ? null
                                : () => setState(() {
                                      _openingTime = null;
                                      _statusFilter = 'Open';
                                    }),
                          ),
                          if (_searchCenter != null ||
                              _customerPosition != null) ...[
                            const SizedBox(width: 8),
                            AppDropdown<double>(
                              value: _searchRadiusKm,
                              width: 165,
                              compact: true,
                              hint: 'Choose distance',
                              icon: Icons.radar,
                              options: {
                                for (final radius in [5.0, 10.0, 25.0, 50.0])
                                  radius:
                                      'Within ${radius.toStringAsFixed(0)} km',
                              },
                              onChanged: _setSearchRadius,
                            ),
                          ],
                        ]),
                      )),
                  if (_showSearchArea)
                    Positioned(
                        top: 196,
                        left: 0,
                        right: useSidePanel ? sidePanelWidth + 28 : 0,
                        child: Center(
                            child: ElevatedButton.icon(
                          onPressed: _searchThisArea,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Search this area'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cardColor,
                              foregroundColor: AppColors.primary,
                              elevation: 3),
                        ))),
                  if (_locationError != null)
                    Positioned(
                        top: _showSearchArea ? 250 : 202,
                        left: 12,
                        right: useSidePanel ? sidePanelWidth + 28 : 68,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(children: [
                              Expanded(
                                  child: Text(_locationError!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12))),
                              TextButton(
                                  onPressed: _enterCustomerLocationManually,
                                  child: const Text('Enter manually')),
                            ]),
                          ),
                        ))
                  else if (!shortViewport && _isLocatingCustomer)
                    Positioned(
                      top: _showSearchArea ? 250 : 202,
                      left: 12,
                      right: useSidePanel ? null : 68,
                      child: Material(
                        color: Colors.white,
                        elevation: 3,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Finding your location…',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                      right: useSidePanel ? sidePanelWidth + 28 : 12,
                      bottom: useSidePanel ? navClearance + 40 : 12,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        FloatingActionButton.small(
                          heroTag: 'compass_button',
                          tooltip: 'Reset compass',
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textDark,
                          onPressed: _resetCompass,
                          child: ValueListenableBuilder<double>(
                            valueListenable: _mapBearing,
                            child: const Icon(Icons.navigation_rounded),
                            builder: (context, bearing, child) =>
                                Transform.rotate(
                              angle: -bearing * math.pi / 180,
                              child: child,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'recenter_button',
                          tooltip: 'My location',
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textDark,
                          onPressed: _getCustomerLocation,
                          child: _isLocatingCustomer
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ])),
                  if (showSuggestions)
                    Positioned(
                      top: 135,
                      left: 12,
                      child: SizedBox(
                          width: useSidePanel
                              ? math.max(
                                  0.0,
                                  constraints.maxWidth - sidePanelWidth - 40,
                                )
                              : overlayWidth,
                          child: _suggestionPanel(suggestions)),
                    ),
                ])),
            Positioned(
                top: useSidePanel ? 12 : null,
                left: useSidePanel ? null : 0,
                right: useSidePanel ? 16 : 0,
                bottom: useSidePanel ? null : 0,
                width: useSidePanel ? sidePanelWidth : null,
                height: useSidePanel ? sidePanelHeight : panelHeight,
                child: Material(
                  color: AppColors.background,
                  elevation: 10,
                  shadowColor: const Color(0x26000000),
                  borderRadius: useSidePanel
                      ? BorderRadius.circular(26)
                      : const BorderRadius.vertical(top: Radius.circular(26)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    if (useSidePanel)
                      const SizedBox(height: 12)
                    else
                      const SizedBox(
                        height: 10,
                        child: Center(
                          child: SizedBox(
                            width: 36,
                            height: 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 42,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Row(
                          children: [
                            if (!snapshot.hasError &&
                                snapshot.connectionState !=
                                    ConnectionState.waiting) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$resultCount',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                snapshot.hasError
                                    ? 'Could not load stalls'
                                    : snapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? 'Finding stalls…'
                                        : resultLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (snapshot.hasError ||
                                (snapshot.connectionState !=
                                        ConnectionState.waiting &&
                                    resultCount > 1))
                              TextButton(
                                onPressed: snapshot.hasError
                                    ? () => setState(() => _vendors =
                                        _vendorService.getAllVendors())
                                    : showingDishResults
                                        ? () => _showAllDishes(
                                              dishResults,
                                              filteredVendorById,
                                            )
                                        : () => _showAllStalls(onScreenVendors),
                                child: Text(
                                  snapshot.hasError ? 'Retry' : 'View all',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!shortViewport)
                      Expanded(
                          child: snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : showingDishResults
                                  ? ListView.builder(
                                      controller: _stallScrollController,
                                      scrollDirection: useSidePanel
                                          ? Axis.vertical
                                          : Axis.horizontal,
                                      padding: useSidePanel
                                          ? const EdgeInsets.fromLTRB(
                                              12, 8, 12, 12)
                                          : const EdgeInsets.fromLTRB(
                                              16, 0, 4, 10),
                                      itemCount: dishResults.length,
                                      itemExtent: _cardExtent,
                                      itemBuilder: (context, index) {
                                        final dish = dishResults[index];
                                        return Padding(
                                          padding: useSidePanel
                                              ? const EdgeInsets.only(bottom: 8)
                                              : const EdgeInsets.only(
                                                  right: 12),
                                          child: _dishCard(
                                            dish,
                                            filteredVendorById[dish.vendorId]!,
                                          ),
                                        );
                                      },
                                    )
                                  : onScreenVendors.isEmpty
                                      ? Center(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24),
                                              child: Text(
                                                  snapshot.hasError
                                                      ? 'Check your connection and retry.'
                                                      : (query.isNotEmpty ||
                                                                  _priceRange !=
                                                                      null) &&
                                                              _dishSearchError !=
                                                                  null
                                                          ? 'Could not load menu prices and dishes. Check your connection and retry.'
                                                          : (query.isNotEmpty ||
                                                                      _priceRange !=
                                                                          null) &&
                                                                  _dishesLoading
                                                              ? 'Loading dishes and prices…'
                                                              : _priceRange !=
                                                                      null
                                                                  ? 'No dishes or stalls match ${_priceRange!.label}${query.isEmpty ? '' : ' and “${_searchController.text.trim()}”'}. Try another price range or reset it.'
                                                                  : _customerPosition !=
                                                                              null &&
                                                                          _searchRadiusKm <
                                                                              50
                                                                      ? 'No stalls found within ${_searchRadiusKm.toStringAsFixed(0)} km. Try Expand area.'
                                                                      : query
                                                                              .isNotEmpty
                                                                          ? 'No nearby dishes or stalls match “${_searchController.text.trim()}”.'
                                                                          : 'Move the map, zoom out, or clear your filters.',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      color: Color(0xFF64748B),
                                                      fontSize: 13))))
                                      : ListView.builder(
                                          controller: _stallScrollController,
                                          scrollDirection: useSidePanel
                                              ? Axis.vertical
                                              : Axis.horizontal,
                                          padding: useSidePanel
                                              ? const EdgeInsets.fromLTRB(
                                                  12, 8, 12, 12)
                                              : EdgeInsets.fromLTRB(
                                                  onScreenVendors.length == 1
                                                      ? math.max(
                                                          16.0,
                                                          (constraints.maxWidth -
                                                                  _cardExtent) /
                                                              2,
                                                        )
                                                      : 16,
                                                  0,
                                                  4,
                                                  8,
                                                ),
                                          itemCount: onScreenVendors.length,
                                          itemExtent: _cardExtent,
                                          itemBuilder: (context, index) =>
                                              Padding(
                                            padding: useSidePanel
                                                ? const EdgeInsets.only(
                                                    bottom: 8)
                                                : const EdgeInsets.only(
                                                    right: 12),
                                            child: _stallCard(
                                              onScreenVendors[index],
                                            ),
                                          ),
                                        )),
                    SizedBox(height: useSidePanel ? 0 : navClearance),
                  ]),
                )),
          ]);
        });
      },
    );
  }

  String? _distanceTo(VendorModel vendor) {
    final position = _searchCenter ?? _customerPosition;
    if (position == null) {
      return null;
    }
    return _formatDistance(Geolocator.distanceBetween(position.latitude,
        position.longitude, vendor.latitude, vendor.longitude));
  }

  String _stockLabel(String status) => switch (status) {
        'low_stock' => 'Low stock',
        'out_of_stock' => 'Out of stock',
        _ => 'In stock',
      };

  Color _stockColor(String status) => switch (status) {
        'low_stock' => const Color(0xFFB45309),
        'out_of_stock' => const Color(0xFFB91C1C),
        _ => const Color(0xFF15803D),
      };

  Widget _dishPhoto(DishSearchEntry dish, {double size = 70}) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          color: AppColors.mint,
          child: dish.item.imageUrl.isEmpty
              ? const Icon(Icons.restaurant_rounded, color: AppColors.primary)
              : Image.network(
                  dish.item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.primary),
                ),
        ),
      );

  Widget _dishCard(DishSearchEntry dish, VendorModel vendor) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openVendorDetails(vendor),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _dishPhoto(dish),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dish.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                        dish.priceIsKnown
                            ? 'RM ${dish.item.price.toStringAsFixed(2)}'
                            : 'Price unavailable',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text(vendor.stallName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11)),
                    const Spacer(),
                    Wrap(spacing: 7, runSpacing: 2, children: [
                      Text(_stockLabel(dish.item.status),
                          style: TextStyle(
                              color: _stockColor(dish.item.status),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      Text(_stallStatus(vendor),
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 10)),
                      if (_distanceTo(vendor) != null)
                        Text(_distanceTo(vendor)!,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 10)),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _stallPhoto(VendorModel vendor, {double size = 48}) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
            width: size,
            height: size,
            color: AppColors.mint,
            child: vendor.imageUrl.isEmpty
                ? const Icon(Icons.storefront_rounded, color: AppColors.primary)
                : Image.network(vendor.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary))),
      );

  Widget _stallCard(VendorModel vendor) {
    final selected = vendor.vendorId == _selectedVendorId;
    final distance = _distanceTo(vendor);

    return Material(
      color: selected ? AppColors.mint : AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _selectVendor(vendor),
        onDoubleTap: () => _openVendorDetails(vendor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _stallPhoto(vendor, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.stallName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        vendor.category,
                        _stallStatus(vendor),
                        if (distance != null) distance,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          vendor.hasFreshLocation
                              ? Icons.circle
                              : Icons.history_rounded,
                          size: 11,
                          color: vendor.hasFreshLocation
                              ? AppColors.openGreen
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            vendor.hasFreshLocation
                                ? 'Location updated'
                                : 'Last known location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'View stall',
                onPressed: () => _openVendorDetails(vendor),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAllStalls(List<VendorModel> vendors) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<VendorModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * .6,
        child: Column(children: [
          ListTile(
              title: const Text('Stalls in this area',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Choose a stall to find it on the map'),
              trailing: IconButton(
                  tooltip: 'Close list',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context))),
          const Divider(height: 1),
          Expanded(
              child: ListView.separated(
            itemCount: vendors.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _stallPhoto(vendor),
                  title: Text(vendor.stallName),
                  subtitle: Text([
                    vendor.category,
                    _stallStatus(vendor),
                    if (_distanceTo(vendor) != null) _distanceTo(vendor)!
                  ].join(' · ')),
                  trailing: const Icon(Icons.near_me_outlined,
                      color: AppColors.primary),
                  onTap: () => Navigator.pop(context, vendor));
            },
          )),
        ]),
      ),
    );
    if (mounted && selected != null) {
      await _selectVendor(selected);
    }
  }

  Future<void> _showAllDishes(
      List<DishSearchEntry> dishes, Map<String, VendorModel> vendors) async {
    _searchFocus.unfocus();
    final selected = await showModalBottomSheet<VendorModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * .72,
        child: Column(children: [
          ListTile(
            title: Text('${dishes.length} nearby dish results',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Results for “${_searchController.text.trim()}”'),
            trailing: IconButton(
              tooltip: 'Close results',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: dishes.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 100),
              itemBuilder: (context, index) {
                final dish = dishes[index];
                final vendor = vendors[dish.vendorId]!;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _dishPhoto(dish),
                  title: Text(dish.item.name),
                  subtitle: Text([
                    dish.priceIsKnown
                        ? 'RM ${dish.item.price.toStringAsFixed(2)}'
                        : 'Price unavailable',
                    _stockLabel(dish.item.status),
                    vendor.stallName,
                    if (_distanceTo(vendor) != null) _distanceTo(vendor)!,
                    _stallStatus(vendor),
                  ].join(' · ')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, vendor),
                );
              },
            ),
          ),
        ]),
      ),
    );
    if (mounted && selected != null) _openVendorDetails(selected);
  }

  void _openVendorDetails(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
  }
}
````
