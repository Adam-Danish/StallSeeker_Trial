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
    models/
      menu_item_model.dart
      user_model.dart
      vendor_model.dart
    services/
      auth_service.dart
      follow_service.dart
      menu_service.dart
      notification_service.dart
      storage_service.dart
      vendor_location_service.dart
      vendor_service.dart
    theme/
      app_theme.dart
  features/
    auth/
      screens/
        login_screen.dart
        register_screen.dart
        welcome_screen.dart
      auth_wrapper.dart
    customer/
      following/
        customer_following_screen.dart
      home/
        customer_home_screen.dart
      profile/
        customer_profile_screen.dart
      vendor_details/
        vendor_details_screen.dart
    shared/
      about_screen.dart
      faq_screen.dart
      logout_helper.dart
      profile_page.dart
    splash/
      splash_screen.dart
    vendor/
      dashboard/
        vendor_dashboard_screen.dart
      menu/
        vendor_menu_screen.dart
      profile/
        edit_stall_screen.dart
        vendor_profile_screen.dart
      vendor_main_screen.dart
  firebase_options.dart
  main.dart
````

# Files

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

## File: lib/core/services/vendor_location_service.dart
````dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Foreground-only sampling. Native background permissions/services are not
/// present in the supplied source export. Never claims background tracking.
class VendorLocationService extends ChangeNotifier {
  VendorLocationService._();
  static final instance = VendorLocationService._();
  Timer? _timer;
  Future<void>? _pending;
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
      if (request != _request || FirebaseAuth.instance.currentUser?.uid != vendorId) { return; }
      _vendorId = vendorId;
      error = null;
      final generation = ++_generation;
      notifyListeners();
      await _sample(vendorId, generation);
    });
    return _operations;
  }

  Future<void> pause() {
    ++_request;
    ++_generation;
    _timer?.cancel();
    _operations = _operations.catchError((Object _) {}).then((_) => _pause());
    return _operations;
  }

  Future<void> _sample(String vendorId, int generation) async {
    if (generation != _generation) { return; }
    final work = _writePosition(vendorId, generation);
    _pending = work;
    await work;
    if (generation != _generation) { return; }
    _pending = null;
    _timer = Timer(const Duration(seconds: 15), () {
      unawaited(_sample(vendorId, generation));
    });
  }

  Future<void> _writePosition(String vendorId, int generation) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (generation != _generation || FirebaseAuth.instance.currentUser?.uid != vendorId) { return; }
      final ref = FirebaseFirestore.instance.collection('vendors').doc(vendorId);
      // Do not reopen a stall closed by another screen/device.
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (generation != _generation || doc.data()?['isOpen'] != true) { return; }
        tx.update(ref, {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
          'locationSharingActive': true,
        });
      }).timeout(const Duration(seconds: 8));
      if (generation == _generation) { error = null; }
    } catch (_) {
      if (generation == _generation) {
        error = 'Location could not update. Check GPS and your connection.';
      }
    }
    if (generation == _generation) { notifyListeners(); }
  }

  Future<void> _pause() async {
    ++_generation;
    _timer?.cancel();
    _timer = null;
    final id = _vendorId;
    _vendorId = null;
    final pending = _pending;
    _pending = null;
    // Finish an in-flight transaction before writing the paused state.
    if (pending != null) { await pending; }
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

## File: lib/features/shared/about_screen.dart
````dart
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About StallSeeker')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.storefront, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'StallSeeker',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'StallSeeker connects food stall vendors with nearby customers. '
            'Vendors can share their live location, opening hours, and menu '
            'availability, while customers can discover open stalls nearby, '
            'view menus in real time, and follow their favorite stalls.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'This app was developed as a Final Year Project.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/shared/profile_page.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared account presentation. Callers keep their existing authentication,
/// editing, and location actions; this widget does not own account data.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.name, required this.email,
    required this.isVendor, required this.isGuest, required this.canChangePassword,
    required this.location, required this.isLoadingLocation, required this.onRefresh,
    required this.onLocation, required this.onEdit, required this.onPassword,
    required this.onFaq, required this.onAbout, required this.onLogout,
    required this.onSignIn, this.onEditStall});

  final String name;
  final String email;
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
  final VoidCallback? onEditStall;

  static const _ink = Color(0xFF17202D);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFEDF0F3);

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2);
    final initials = words.map((part) => String.fromCharCode(part.runes.first)).join().toUpperCase();
    return initials.isEmpty ? 'S' : initials;
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted))),
      Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line)),
        child: Column(children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68, endIndent: 16, color: _line),
            children[i],
          ],
        ])),
    ],
  );

  Widget _action({required IconData icon, required String title, required String subtitle,
      required VoidCallback onTap, Color accent = AppColors.primary, Widget? trailing}) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    leading: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: accent.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: accent, size: 21)),
    title: Text(title, style: const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w600)),
    subtitle: Padding(padding: const EdgeInsets.only(top: 3),
      child: Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted))),
    trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: _muted),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF7F8FA),
    child: RefreshIndicator(onRefresh: onRefresh,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFFFF2E9), borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Container(width: 80, height: 80, alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD8C4), width: 3)),
                child: Text(_initials, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFC64B22)))),
              const SizedBox(height: 14),
              Text(name, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, height: 1.25)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(email, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _muted)),
              ],
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isVendor ? Icons.storefront_outlined : Icons.person_outline_rounded,
                    size: 14, color: const Color(0xFFC64B22)),
                  const SizedBox(width: 5),
                  Text(isGuest ? 'Guest' : isVendor ? 'Vendor account' : 'Customer account',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFC64B22), fontWeight: FontWeight.w600)),
                ])),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: isGuest ? onSignIn : onEdit,
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white,
                  foregroundColor: _ink, side: const BorderSide(color: Color(0xFFFFD8C4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: Icon(isGuest ? Icons.login_rounded : Icons.edit_outlined, size: 16),
                label: Text(isGuest ? 'Sign in to your account' : 'Edit profile')),
            ])),
          _section('Your area', [
            _action(icon: Icons.near_me_outlined, title: 'Current location', subtitle: location,
              accent: const Color(0xFF147D68), onTap: onLocation,
              trailing: isLoadingLocation
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: _muted, size: 20)),
          ]),
          if (!isGuest) _section(isVendor ? 'Account & business' : 'Account', [
            _action(icon: Icons.person_outline_rounded, title: 'Personal information',
              subtitle: 'Update your display name', onTap: onEdit),
            if (isVendor && onEditStall != null)
              _action(icon: Icons.storefront_outlined, title: 'My stall',
                subtitle: 'Photos, opening hours and stall information', onTap: onEditStall!),
            if (canChangePassword)
              _action(icon: Icons.lock_outline_rounded, title: 'Password & security',
                subtitle: 'Change your account password', onTap: onPassword, accent: const Color(0xFF6260BF)),
          ]),
          _section('Help & information', [
            _action(icon: Icons.help_outline_rounded, title: 'Help centre',
              subtitle: 'Answers to common questions', onTap: onFaq, accent: const Color(0xFF4774B8)),
            _action(icon: Icons.info_outline_rounded, title: 'About StallSeeker',
              subtitle: 'Get to know the app', onTap: onAbout, accent: const Color(0xFF4774B8)),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: onLogout,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50),
              foregroundColor: const Color(0xFFB42318), side: const BorderSide(color: Color(0xFFF1D4D0)),
              backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            icon: const Icon(Icons.logout_rounded, size: 18), label: Text(isGuest ? 'Leave guest mode' : 'Log out')),
          const SizedBox(height: 18),
          const Text('StallSeeker', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
        ]),
    ),
  );
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

## File: lib/core/models/menu_item_model.dart
````dart
class MenuItemModel {
  final String itemId;
  final String name;
  final double price;
  final String
      status; // 'available' (Green), 'low_stock' (Yellow), 'out_of_stock' (Red)
  final String imageUrl;

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    this.status = 'available',
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      itemId: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'available',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
````

## File: lib/core/models/user_model.dart
````dart
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'customer' or 'vendor'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  // Convert Firestore Document to UserModel Object
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'customer',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convert UserModel Object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt,
    };
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
}
````

## File: lib/features/shared/faq_screen.dart
````dart
import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  final bool isVendor;

  const FaqScreen({super.key, required this.isVendor});

  static const List<Map<String, String>> _vendorFaqs = [
    {
      'question': 'How do I mark my stall as open?',
      'answer': 'On your Dashboard, flip the "Stall Status" switch to Open. '
          'The app will ask for your location permission the first time '
          '-- this is needed so customers can find you on the map.',
    },
    {
      'question': 'Why is my stall not showing up on the customer map?',
      'answer': 'Make sure your stall is toggled Open, and that you allowed '
          'location permission when prompted. If location services are '
          'off on your phone, the app cannot save your position.',
    },
    {
      'question': 'How do I update my menu prices or stock status?',
      'answer':
          'Go to Dashboard > Manage Menu & Stock. Tap the colored circles '
              'next to a dish to mark it Available, Low Stock, or Out of '
              'Stock -- customers see this update instantly.',
    },
    {
      'question': 'How do I add a photo to my stall or a menu item?',
      'answer': 'Go to Edit Stall Profile to set your stall\'s cover photo, '
          'or Manage Menu & Stock and tap the photo box when adding a dish '
          'to attach a picture to that item.',
    },
    {
      'question': 'Will customers be notified when I open my stall?',
      'answer': 'Yes. Anyone who follows your stall gets a push '
          'notification the moment you switch your status to Open.',
    },
    {
      'question': 'I forgot my password. What do I do?',
      'answer': 'On the login screen, tap "Forgot Password?" and enter your '
          'email. You will receive a link to reset your password.',
    },
  ];

  static const List<Map<String, String>> _customerFaqs = [
    {
      'question': 'How do I find stalls near me?',
      'answer': 'The Home tab shows a map centered on your current '
          'location, with a live list of open stalls sorted by distance. '
          'Use the search bar to filter by name or food category.',
    },
    {
      'question': 'How do I follow a stall?',
      'answer':
          'Open a stall\'s details page (tap its marker on the map or its '
              'card in the nearby list) and tap the heart icon in the top '
              'right corner.',
    },
    {
      'question': 'How will I know when a stall I follow opens?',
      'answer': 'You will get a push notification as soon as a followed '
          'stall switches to Open, and can tap it to jump straight to '
          'that stall\'s page.',
    },
    {
      'question': 'How do I see what a stall is selling?',
      'answer': 'Open the stall\'s details page to see its live menu, '
          'including which items are Available, Low Stock, or Out of '
          'Stock.',
    },
    {
      'question': 'I forgot my password. What do I do?',
      'answer': 'On the login screen, tap "Forgot Password?" and enter your '
          'email. You will receive a link to reset your password.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final faqs = isVendor ? _vendorFaqs : _customerFaqs;

    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['answer']!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
````

## File: lib/features/shared/logout_helper.dart
````dart
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

// Shows a confirmation dialog before logging out. Used by every logout
// button in the app (customer AppBar icon, customer profile, vendor
// dashboard AppBar icon, vendor profile) so the confirmation behavior
// stays identical everywhere instead of being copy-pasted per screen.
Future<void> confirmAndLogout(
  BuildContext context,
  AuthService authService,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await authService.signOut();
      if (context.mounted) { Navigator.of(context).popUntil((route) => route.isFirst); }
    } catch (_) {
      if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not finish logging out. Please retry.')),
      ); }
    }
  }
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
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'StallSeeker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Poppins', // Added Poppins font
              ),
            ),
          ],
        ),
      ),
    );
  }
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

## File: lib/core/services/notification_service.dart
````dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/vendor_model.dart';
import 'vendor_service.dart';
import '../../features/customer/vendor_details/vendor_details_screen.dart';

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
    description: 'Notifies you when a followed vendor starts selling.',
    importance: Importance.high,
  );

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;
  String? _syncedUid;
  String? _pendingVendorId;
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
    if (ready && _pendingVendorId != null) {
      final id = _pendingVendorId!;
      _pendingVendorId = null;
      unawaited(_openVendorDetails(id));
    }
  }


  // One-time setup: creates the notification channel, requests
  // permission, and wires up listeners for taps in every app state
  // (foreground, background, terminated). Safe to call more than once.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) { return; }

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
        final vendorId = response.payload;
        if (vendorId != null) { _openVendorDetails(vendorId); }
      },
    );

    await _messaging.requestPermission();
    _initialized = true;

    // FCM does not show a system notification by itself while the app is
    // in the foreground, so display one manually using the same channel.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final vendorId = message.data['vendorId'];
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
          payload: vendorId,
        );
      }
    });

    // App was backgrounded and the user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final vendorId = message.data['vendorId'];
      if (vendorId != null) { _openVendorDetails(vendorId); }
    });

    // App was fully closed and got launched by tapping the notification.
    final initialMessage = await _messaging.getInitialMessage();
    final vendorId = initialMessage?.data['vendorId'];
    if (vendorId != null) { _openVendorDetails(vendorId); }
  }

  // Fetches this device's FCM token and saves it on the logged-in user's
  // Firestore record, and keeps it updated if it ever rotates. Call this
  // once the user is known to be logged in.
  Future<void> syncTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || _syncedUid == user.uid) { return; }
    _syncedUid = user.uid;
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      final uid = _syncedUid;
      if (uid != null) { unawaited(_queueTokenSave(uid, token).catchError((Object e) {
        debugPrint('Could not refresh notification registration.');
      })); }
    });
    try {
      final token = await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) { await _queueTokenSave(user.uid, token); }
    } catch (_) {
      _syncedUid = null;
      debugPrint('Notification registration unavailable.');
    }
  }

  Future<void> clearCurrentDevice() async {
    _navigationReady = false;
    _pendingVendorId = null;
    final user = FirebaseAuth.instance.currentUser;
    _syncedUid = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    await _tokenWork.timeout(const Duration(seconds: 5)).catchError((Object _) {});
    if (user == null || user.isAnonymous) { return; }
    try {
      final token = await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(ref);
          // Preserve another device's registration in the existing single-token schema.
          if (doc.data()?['fcmToken'] == token) { tx.update(ref, {'fcmToken': FieldValue.delete()}); }
        }).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      debugPrint('Could not remove notification registration.');
    } finally {
      try {
        await _messaging.deleteToken().timeout(const Duration(seconds: 5));
      } catch (_) {
        debugPrint('Could not revoke this device notification token.');
      }
      await _localNotifications.cancelAll();
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
  }

  Future<void> _openVendorDetails(String vendorId) async {
    final navState = _navigatorKey?.currentState;
    if (!_navigationReady || navState == null) {
      _pendingVendorId = vendorId;
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final VendorModel? vendor = await _vendorService.getVendorProfile(vendorId);
    if (vendor == null || !_navigationReady ||
        FirebaseAuth.instance.currentUser?.uid != uid) { return; }

    navState.push(
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
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

  Future<void> updateVendorLocation(
    String vendorId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _vendorsRef.doc(vendorId).update({
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'locationSharingActive': true,
      });
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

  Stream<List<VendorModel>> getOpenVendors() {
    return _vendorsRef.where('isOpen', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
````

## File: lib/core/constants/app_colors.dart
````dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary =
      Color(0xFFFF6E41); // Deep Orange / Food Stall theme
  static const Color primaryLight = Color(0xFFFF8142);

  // New design system
  static const Color background = Color(0xFFF2EFF5); // Soft Lavender-Gray
  static const Color cardColor = Color(0xFFFFFFFF); // Pure White
  static const Color textDark = Color(0xFF222222); // Dark Charcoal
  static const Color textMuted = Color(0xFF9A9A9E); // Muted Gray

  // Status Colors
  static const Color openGreen = Color(0xFF2E7D32);
  static const Color closedRed = Color(0xFFC62828);
  static const Color limitedYellow = Color(0xFFF57F17);
}
````

## File: lib/core/models/vendor_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorModel {
  final String vendorId;
  final String stallName;
  final String description;
  final String category;
  final String openingHours;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final DateTime? locationUpdatedAt;
  final bool locationSharingActive;

  bool get hasValidLocation => latitude.isFinite && longitude.isFinite &&
      latitude.abs() <= 90 && longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  bool get hasFreshLocation {
    final updated = locationUpdatedAt;
    if (!locationSharingActive || updated == null) { return false; }
    final age = DateTime.now().difference(updated);
    return !age.isNegative && age < const Duration(minutes: 2);
  }


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
    this.locationUpdatedAt,
    this.locationSharingActive = false,
  });

  /// Editable information only. Operational state belongs to the selling session.
  Map<String, dynamic> toProfileMap() => {
    'vendorId': vendorId,
    'stallName': stallName,
    'description': description,
    'category': category,
    'openingHours': openingHours,
    'imageUrl': imageUrl,
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
      locationUpdatedAt: (map['locationUpdatedAt'] as Timestamp?)?.toDate(),
      locationSharingActive: map['locationSharingActive'] == true,
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
      locationUpdatedAt: locationUpdatedAt,
      locationSharingActive: locationSharingActive,
    );
  }
}
````

## File: lib/core/theme/app_theme.dart
````dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72.0,
      ),
      // Root-cause fix for cards looking peach/tinted instead of pure
      // white: Material 3 automatically tints elevated surfaces with a
      // primary-colored overlay (surfaceTintColor) the higher their
      // elevation is -- since every Card in the app uses elevation,
      // they were all picking up a warm/orange cast from the primary
      // color even though color: null was meant to just mean "white".
      // Setting surfaceTintColor: Colors.transparent here disables
      // that overlay app-wide, so every Card renders true
      // AppColors.cardColor regardless of elevation.
      cardTheme: const CardThemeData(
        color: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
````

## File: lib/features/customer/following/customer_following_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/follow_service.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerFollowingScreen extends StatefulWidget {
  const CustomerFollowingScreen({super.key});

  @override
  State<CustomerFollowingScreen> createState() =>
      _CustomerFollowingScreenState();
}

class _CustomerFollowingScreenState extends State<CustomerFollowingScreen> {
  final followService = FollowService();
  final vendorService = VendorService();

  @override
  Widget build(BuildContext context) {
    final customerId = FirebaseAuth.instance.currentUser?.uid;

    if (customerId == null || FirebaseAuth.instance.currentUser!.isAnonymous) {
      return const Center(child: Text('Please log in to see followed stalls.'));
    }

    return StreamBuilder<List<String>>(
      stream: followService.getFollowedVendorIds(customerId),
      builder: (context, idSnapshot) {
        if (idSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (idSnapshot.hasError) {
          return const Center(child: Text('Could not load followed stalls. Please reopen this screen.'));
        }
        final vendorIds = idSnapshot.data ?? [];

        if (vendorIds.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'You are not following any stalls yet.\n'
                'Tap the heart icon on a stall to follow it.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Trigger a rebuild to re‑fetch vendor profiles.
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vendorIds.length,
            itemBuilder: (context, index) {
              final vendorId = vendorIds[index];

              return StreamBuilder<VendorModel?>(
                stream: vendorService.watchVendorProfile(vendorId),
                builder: (context, vendorSnapshot) {
                  if (vendorSnapshot.hasError) {
                    return const ListTile(title: Text('Could not update this stall.'));
                  }
                  if (!vendorSnapshot.hasData || vendorSnapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  final vendor = vendorSnapshot.data!;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: vendor.isOpen
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          Icons.storefront,
                          color: vendor.isOpen ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(vendor.stallName.isNotEmpty
                          ? vendor.stallName
                          : 'Unnamed Stall'),
                      subtitle: Text(
                          '${vendor.category} • ${vendor.isOpen ? "Open" : "Closed"}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VendorDetailsScreen(vendor: vendor),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
````

## File: lib/features/customer/vendor_details/vendor_details_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';

class VendorDetailsScreen extends StatefulWidget {
  final VendorModel vendor;

  const VendorDetailsScreen({super.key, required this.vendor});

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  final _menuService = MenuService();
  final _followService = FollowService();
  final _vendorService = VendorService();

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
    _menuStream = _menuService.getMenuItems(_vendor.vendorId);
    _vendorSub = _vendorService.watchVendorProfile(_vendor.vendorId).listen(
      (vendor) {
        if (!mounted) { return; }
        setState(() {
          _vendorDeleted = vendor == null;
          if (vendor != null) { _vendor = vendor; }
          _vendorError = null;
        });
      },
      onError: (Object error) {
        if (mounted) { setState(() => _vendorError = 'Could not update this stall. Showing last known details.'); }
      },
    );
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) { setState(() {}); }
    });

    final customerId = FirebaseAuth.instance.currentUser?.uid;
    if (customerId != null) {
      _followSub = _followService
          .isFollowing(customerId, _vendor.vendorId)
          .listen((value) {
        if (mounted) { setState(() => _isFollowing = value); }
      });
    }
  }

  @override
  void dispose() {
    _followSub?.cancel();
    _vendorSub?.cancel();
    _freshnessTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshVendor() async {
    setState(() => _isRefreshing = true);
    final updated = await _vendorService.getVendorProfile(_vendor.vendorId);
    if (mounted) {
      setState(() {
        if (updated != null) { _vendor = updated; }
        _isRefreshing = false;
      });
    }
  }

  Future<void> _toggleFollow(String customerId) async {
    if (_isFollowSaving) { return; }
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
          const SnackBar(content: Text('Could not update following. Please retry.')),
        );
      }
    } finally {
      if (mounted) { setState(() => _isFollowSaving = false); }
    }
  }

  Future<void> _openNavigation() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_vendor.latitude},${_vendor.longitude}',
    );
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) { throw StateError('No maps application'); }
    } catch (_) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions. Please retry.')),
      ); }
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create an Account'),
        content: const Text(
          'Following vendors requires an account. Log in or register to continue.',
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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final customerId = currentUser?.uid;
    final isGuest = currentUser?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
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
                    onPressed: _isFollowSaving || _vendorDeleted ? null : () => _toggleFollow(customerId),
                  ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: !_vendorDeleted && _vendor.hasValidLocation ? _openNavigation : null,
          icon: const Icon(Icons.directions),
          label: const Text('Get directions'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          if (_vendorDeleted || _vendorError != null)
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(_vendorDeleted ? 'This stall is no longer available.' : _vendorError!)),
          ClipRRect(borderRadius: BorderRadius.circular(24),
            child: AspectRatio(aspectRatio: 1.8,
              child: _vendor.imageUrl.isNotEmpty
                  ? Image.network(_vendor.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder())
                  : _photoPlaceholder())),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _badge(_vendor.isOpen ? 'Open now' : 'Closed',
                _vendor.isOpen ? const Color(0xFF15803D) : const Color(0xFFB42318), Icons.circle),
            if (_vendor.category.isNotEmpty)
              _badge(_vendor.category, const Color(0xFF64748B), Icons.restaurant_outlined),
          ]),
          const SizedBox(height: 12),
          Text(_vendor.stallName.isEmpty ? 'Unnamed stall' : _vendor.stallName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
              height: 1.2, color: Color(0xFF17202D))),
          if (_vendor.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_vendor.description,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9ECF0))),
            child: Column(children: [
              _info(Icons.schedule_rounded, 'Opening hours',
                _vendor.openingHours.isEmpty ? 'Not provided by this vendor' : _vendor.openingHours),
              const Divider(height: 24, indent: 36),
              _info(Icons.location_on_outlined, _vendor.hasFreshLocation ? 'Location updated recently' : 'Last known location',
                _vendor.hasFreshLocation ? 'The vendor is sharing their location.'
                    : 'This location may be outdated. Check before travelling.'),
            ])),
          const SizedBox(height: 26),
          const Text('On the menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF17202D))),
          const SizedBox(height: 4),
          const Text('Availability is updated by the vendor', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          StreamBuilder<List<MenuItemModel>>(
            stream: _menuStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                  const Text('Could not load the menu.'),
                  TextButton(onPressed: () => setState(() => _menuStream = _menuService.getMenuItems(_vendor.vendorId)),
                    child: const Text('Retry')),
                ]));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Padding(padding: EdgeInsets.all(24), child: Text('The vendor has not added a menu yet.'));
              }
              return Column(children: items.map(_menuCard).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(color: const Color(0xFFFFF0E7),
    alignment: Alignment.center,
    child: const Icon(Icons.storefront_rounded, size: 60, color: Color(0xFFC64B22)));

  Widget _badge(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color), const SizedBox(width: 5),
      Flexible(child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
    ]),
  );

  Widget _info(IconData icon, String title, String detail) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: const Color(0xFF64748B), size: 21), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF17202D))),
      const SizedBox(height: 4),
      Text(detail, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
    ])),
  ]);

  Widget _menuCard(MenuItemModel item) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE9ECF0))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 68, height: 68,
          child: item.imageUrl.isEmpty ? _photoPlaceholder()
              : Image.network(item.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder()))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF17202D))),
        const SizedBox(height: 4),
        Text('RM ${item.price.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC64B22))),
        const SizedBox(height: 8),
        _badge(_statusLabel(item.status), _statusColor(item.status), Icons.circle),
      ])),
    ]),
  );
}
````

## File: lib/features/vendor/profile/edit_stall_screen.dart
````dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/storage_service.dart';

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

  String _selectedCategory = 'Beverages';
  final List<String> _categories = [
    'Beverages',
    'Snacks & Desserts',
    'Malay Food',
    'Chinese Food',
    'Indian Food',
    'Western',
    'Noodles',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOpen = false;

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
    if (!_formKey.currentState!.validate()) { return; }

    final user = _auth.currentUser;
    if (user == null) { return; }

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
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageContent,
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black54,
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
        title: const Text('Edit Stall Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
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
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter stall name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Food Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your food/drinks offered...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Operating Hours
                    TextFormField(
                      controller: _openingHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Hours',
                        hintText: 'e.g. 8:00 AM - 5:00 PM',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter opening hours'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveStallProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
````

## File: lib/features/vendor/vendor_main_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard/vendor_dashboard_screen.dart';
import 'profile/vendor_profile_screen.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _selectedIndex = 0;

  static const _titles = ['Vendor Dashboard', 'My Profile'];

  // Key to call dashboard refresh method
  final _dashboardKey = GlobalKey<VendorDashboardScreenState>();

  void _refreshDashboard() {
    _dashboardKey.currentState?.fetchVendorDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // Refresh button only on Dashboard
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFFF6E41)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF6E41)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
````

## File: lib/core/services/menu_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream menu items for a specific vendor
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

  // Generates a new, unused document ID for a menu item before it exists.
  // Needed when a photo has to be uploaded (and named after the item's ID)
  // before the item document itself is written.
  String newMenuItemId(String vendorId) {
    return _db.collection('vendors').doc(vendorId).collection('menu').doc().id;
  }

  // Add new menu item. Pass itemId (from newMenuItemId) when a photo was
  // uploaded ahead of time so the item is saved under that same ID.
  Future<void> addMenuItem(
    String vendorId,
    String name,
    double price, {
    String? itemId,
    String? imageUrl,
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
    );

    await docRef.set(newItem.toMap()).timeout(const Duration(seconds: 15));
  }

  // Edit an existing item's name, price, and (optionally) photo, without
  // touching its current status. Pass imageUrl only if a new photo was
  // uploaded -- omit it to keep whatever photo the item already has.
  Future<void> updateMenuItem(
    String vendorId,
    String itemId,
    String name,
    double price, {
    String? imageUrl,
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) { throw ArgumentError('Invalid dish'); }
    final data = <String, dynamic>{
      'name': name,
      'price': price,
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

  // Quick Traffic Light Status Update
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

## File: lib/features/auth/screens/register_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'customer';
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) { return; }

    setState(() => _isLoading = true);

    String? error = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else if (mounted) {
      Navigator.pop(context); // Go back after successful registration
    }
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Reusable pill-shaped text field to match your image perfectly
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: Color(0xFF212121),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: Color(0xFFF1F3F4), // Bbackground text box tempat taip
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
          255, 250, 250, 250), // Light grey screen background
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Full Name
                  _buildTextField(
                    controller: _fullNameController,
                    hintText: 'Full Name',
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Email Address
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email Address',
                    validator: (val) => val == null || !val.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Password
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    validator: (val) => val == null || val.length < 6
                        ? 'Password must be 6+ chars'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 5. Choose Role
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'I am a...', // Removed the weird extra spaces
                      textAlign: TextAlign.start, // Fixes left alignment
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                  // 6. Role Selection Box (Pill-shaped Container + Dropdown)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _selectedRole,
                        dropdownColor: Colors
                            .white, // Added this back for a clean popup background
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.grey),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Color(0xFF212121),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'customer', child: Text('Customer')),
                          DropdownMenuItem(
                              value: 'vendor',
                              child: Text('Vendor / Stall Owner')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRole = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // "Sign Up" Coral Button (Pill-shaped)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFF6E41), // Matches your coral color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sign Up'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer: Already have an account? Sign In
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : _goToLogin,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: const Color(0xFFFF6E41),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
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
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);
    final error = await _authService.signInWithGoogle();
    if (mounted) { setState(() => _isLoading = false); }

    if (error != null && error != 'cancelled' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error), backgroundColor: const Color(0xFFFF6B56)),
      );
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    final error = await _authService.signInAsGuest();
    if (mounted) { setState(() => _isLoading = false); }

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.storefront,
                size: 64,
                color: Color(0xFFFF6E41), // removed const (was unnecessary)
              ),
              const SizedBox(height: 16),
              const Text(
                'StallSeeker',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find nearby food stalls, live.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 40),
              _buildActionButton(
                icon: Image.asset('assets/google_logo.png', height: 20),
                label: 'Continue with Google',
                backgroundColor: const Color(0xFFF1F3F4),
                foregroundColor: Colors.black,
                onPressed: _isLoading ? null : _continueWithGoogle,
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                icon: const Icon(Icons.email_outlined, size: 24),
                label: 'Continue with Email',
                backgroundColor: const Color(0xFFFF6E41),
                foregroundColor: Colors.white,
                onPressed: _isLoading ? null : _goToRegister,
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                icon: const Icon(Icons.person_outline, size: 24),
                label: 'Continue as Guest',
                backgroundColor: const Color(0xFF1C1C1E),
                foregroundColor: Colors.white,
                onPressed: _isLoading ? null : _continueAsGuest,
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _goToLogin,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
````

## File: lib/features/vendor/profile/vendor_profile_screen.dart
````dart
import 'edit_stall_screen.dart';
import '../../shared/profile_page.dart';
import '../../auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
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
    if (!mounted || _isLoadingLocation) { return; }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) { return; }
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
      if (!mounted) { return; }
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

      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
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
    if (p == null) { return 'Location unavailable'; }
    final parts = [p.subLocality, p.locality, p.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  void _showEditProfileDialog() {
    final nameController =
        TextEditingController(text: _userModel?.fullName ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final user = FirebaseAuth.instance.currentUser;
                          final newName = nameController.text.trim();
                          if (user == null || newName.isEmpty) { return; }

                          setDialogState(() => isSaving = true);
                          final error = await _authService.updateFullName(
                              user.uid, newName);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (error == null) {
                            await _loadUserData(); // refresh header card
                          }

                          if (!mounted) { return; }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error ?? 'Profile updated.'),
                              backgroundColor:
                                  error != null ? Colors.red : Colors.green,
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPassword = passwordController.text.trim();
                          if (newPassword.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password must be 6+ characters.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final error =
                              await _authService.changePassword(newPassword);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!mounted) { return; }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  error ?? 'Password changed successfully.'),
                              backgroundColor:
                                  error != null ? Colors.red : Colors.green,
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { return const Center(child: CircularProgressIndicator()); }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest ? 'Welcome, explorer' : _userModel?.fullName.isNotEmpty == true
        ? _userModel!.fullName : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name, email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      isVendor: true, isGuest: guest,
      canChangePassword: user?.providerData.any((provider) => provider.providerId == 'password') ?? false,
      location: _locationText, isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _loadLocation,
      onEdit: _showEditProfileDialog,
      onPassword: _showChangePasswordDialog,
      onFaq: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: true))),
      onAbout: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      onEditStall: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStallScreen())),
    );
  }
}
````

## File: lib/features/vendor/menu/vendor_menu_screen.dart
````dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/storage_service.dart';

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
    _items = _uid == null ? Stream.value(<MenuItemModel>[]) : _menu.getMenuItems(_uid);
  }

  void _error(String message) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  }

  Future<void> _status(MenuItemModel item, String status) async {
    if (_uid == null || _busyItems.contains(item.itemId) || item.status == status) { return; }
    setState(() => _busyItems.add(item.itemId));
    try {
      await _menu.updateItemStatus(_uid, item.itemId, status);
    } catch (_) {
      _error('Could not update stock. Please retry.');
    } finally {
      if (mounted) { setState(() => _busyItems.remove(item.itemId)); }
    }
  }

  Future<void> _delete(MenuItemModel item) async {
    if (_uid == null || _busyItems.contains(item.itemId)) { return; }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete dish?'),
      content: Text('Delete ${item.name} from your menu? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ));
    if (confirmed != true || !mounted) { return; }
    setState(() => _busyItems.add(item.itemId));
    try { await _menu.deleteMenuItem(_uid, item.itemId); }
    catch (_) { _error('Could not delete this dish. Please retry.'); }
    finally { if (mounted) { setState(() => _busyItems.remove(item.itemId)); } }
  }

  Future<void> _edit([MenuItemModel? item]) async {
    if (_uid == null) { return; }
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true,
      isDismissible: false, enableDrag: false,
      builder: (_) => _MenuEditor(uid: _uid, item: item, menu: _menu, storage: _storage),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Menu & stock')),
    floatingActionButton: _uid == null ? null : FloatingActionButton.extended(
      onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Add dish')),
    body: StreamBuilder<List<MenuItemModel>>(stream: _items, builder: (context, snapshot) {
      if (snapshot.hasError) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Could not load your menu.'),
        TextButton(onPressed: () => setState(_reload), child: const Text('Retry')),
      ])); }
      if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
      final items = snapshot.data ?? [];
      if (items.isEmpty) { return const Center(child: Text('Your menu is empty.\nTap Add dish to get started.', textAlign: TextAlign.center)); }
      return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final busy = _busyItems.contains(item.itemId);
          return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
            padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 56, height: 56,
                  child: item.imageUrl.isEmpty ? const Icon(Icons.restaurant, size: 32)
                      : Image.network(item.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 32)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('RM ${item.price.toStringAsFixed(2)}'),
                ])),
                PopupMenuButton<String>(enabled: !busy, tooltip: 'Dish options', onSelected: (value) {
                  if (value == 'edit') { _edit(item); } else { _delete(item); }
                }, itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit dish')),
                  PopupMenuItem(value: 'delete', child: Text('Delete dish')),
                ]),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 4, children: _statuses.entries.map((entry) => ChoiceChip(
                label: Text(entry.value.$1),
                avatar: Icon(Icons.circle, size: 12, color: entry.value.$2),
                selected: item.status == entry.key,
                onSelected: busy ? null : (_) => _status(item, entry.key),
              )).toList()),
              if (busy) const LinearProgressIndicator(),
            ]),
          ));
        });
    }),
  );
}

class _MenuEditor extends StatefulWidget {
  const _MenuEditor({required this.uid, required this.item, required this.menu, required this.storage});
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
  late final String _itemId;
  File? _image;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _price = TextEditingController(text: widget.item?.price.toStringAsFixed(2) ?? '');
    // Reuse the same ID on retries so an uncertain network result cannot duplicate a dish.
    _itemId = widget.item?.itemId ?? widget.menu.newMenuItemId(widget.uid);
  }
  @override
  void dispose() { _name.dispose(); _price.dispose(); super.dispose(); }

  Future<void> _pick() async {
    try {
      final image = await widget.storage.pickImage();
      if (mounted && image != null) { setState(() => _image = image); }
    } catch (_) {
      if (mounted) { setState(() => _error = 'Could not open your photos. Please retry.'); }
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) { return; }
    setState(() { _saving = true; _error = null; });
    try {
      String? imageUrl;
      if (_image != null) { imageUrl = await widget.storage.uploadMenuItemImage(widget.uid, _itemId, _image!); }
      if (widget.item == null) {
        await widget.menu.addMenuItem(widget.uid, _name.text.trim(), double.parse(_price.text.trim()),
            itemId: _itemId, imageUrl: imageUrl);
      } else {
        await widget.menu.updateMenuItem(widget.uid, _itemId, _name.text.trim(), double.parse(_price.text.trim()), imageUrl: imageUrl);
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) { setState(() { _saving = false; _error = 'Could not save this dish. Your changes are still here. Please retry.'; }); }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.item == null ? 'Add dish' : 'Edit dish', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (_image != null) ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.file(_image!, height: 140, fit: BoxFit.cover))
        else if (widget.item?.imageUrl.isNotEmpty == true)
          Image.network(widget.item!.imageUrl, height: 140, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.restaurant)),
        TextButton.icon(onPressed: _saving ? null : _pick, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Choose photo')),
        TextFormField(controller: _name, enabled: !_saving, maxLength: 80,
          decoration: const InputDecoration(labelText: 'Dish name'),
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter a dish name.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _price, enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Price', prefixText: 'RM '),
          validator: (value) {
            final text = value?.trim() ?? '';
            final price = double.tryParse(text);
            if (price == null || !price.isFinite || price <= 0 || !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
              return 'Enter a positive price with up to 2 decimal places.';
            }
            return null;
          }),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save dish')),
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      ])),
    ),
  );
}
````

## File: lib/core/services/auth_service.dart
````dart
import 'notification_service.dart';
import 'vendor_location_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  // google_sign_in v7 requires an explicit initialize() call, exactly
  // once, before authenticate()/signOut() are used. Cheap to call
  // repeatedly since it's guarded by the flag below.
  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) { return; }
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

  // Register user with Email, Password, Name & Role
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
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

        await _firestore
            .collection(FirestoreCollections.users)
            .doc(credential.user!.uid)
            .set(newUser.toMap());

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

  // Google sign-in. Offered as a quick customer entry point -- a
  // brand-new Google user is created as role 'customer' automatically,
  // using their Google account's display name as fullName. Vendors
  // still register with email/password since a stall account needs the
  // role picker anyway.
  //
  // A 25-second timeout is applied to the account picker step. Without
  // this, a misconfigured SHA-1 fingerprint (the most common cause of
  // this failing) makes the picker hang indefinitely with no error and
  // no way forward for the user -- the timeout turns that into a clear
  // message instead of a frozen screen.
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
          .timeout(const Duration(seconds: 25));
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
        await _firestore
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

  // Guest mode: signs in anonymously so a customer can browse without
  // creating an account. Anonymous users skip the Firestore users/
  // document entirely (see AuthWrapper) and can't follow vendors --
  // following requires converting to a real account.
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

  // Fetch current user's data from Firestore
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

  // Sign Out
  Future<void> signOut() async {
    await VendorLocationService.instance.pause();
    try {
      await NotificationService.instance.clearCurrentDevice();
    } catch (_) {
      debugPrint('Notification cleanup could not finish.');
    }
    try {
      if (_googleSignInReady) { await _googleSignIn.signOut(); }
    } finally {
      await _auth.signOut();
    }
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Could not send reset email.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) { return "No user is currently logged in."; }
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return "For security, please log out and log back in before changing your password.";
      }
      return e.message ?? "Could not change password.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateFullName(String uid, String newName) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .update({'fullName': newName});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
````

## File: lib/features/customer/profile/customer_profile_screen.dart
````dart
import '../../shared/profile_page.dart';
import '../../auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/faq_screen.dart';
import '../../shared/about_screen.dart';
import '../../shared/logout_helper.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _authService = AuthService();
  final _geocoding = Geocoding();

  UserModel? _userModel;
  bool _isLoading = true;

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
    if (!mounted || _isLoadingLocation) { return; }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) { return; }
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
      if (!mounted) { return; }
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

      // FIXED: use _geocoding.placemarkFromCoordinates
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
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
    if (p == null) { return 'Location unavailable'; }
    final parts = [p.subLocality, p.locality, p.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  void _showEditProfileDialog() {
    final nameController =
        TextEditingController(text: _userModel?.fullName ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final user = FirebaseAuth.instance.currentUser;
                          final newName = nameController.text.trim();
                          if (user == null || newName.isEmpty) { return; }

                          setDialogState(() => isSaving = true);
                          final error = await _authService.updateFullName(
                              user.uid, newName);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (error == null) {
                            await _loadUserData(); // refresh header card
                          }

                          if (!mounted) { return; }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error ?? 'Profile updated.'),
                              backgroundColor:
                                  error != null ? Colors.red : Colors.green,
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPassword = passwordController.text.trim();
                          if (newPassword.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password must be 6+ characters.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final error =
                              await _authService.changePassword(newPassword);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!mounted) { return; }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  error ?? 'Password changed successfully.'),
                              backgroundColor:
                                  error != null ? Colors.red : Colors.green,
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { return const Center(child: CircularProgressIndicator()); }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest ? 'Welcome, explorer' : _userModel?.fullName.isNotEmpty == true
        ? _userModel!.fullName : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name, email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      isVendor: false, isGuest: guest,
      canChangePassword: user?.providerData.any((provider) => provider.providerId == 'password') ?? false,
      location: _locationText, isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _loadLocation,
      onEdit: _showEditProfileDialog,
      onPassword: _showChangePasswordDialog,
      onFaq: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: false))),
      onAbout: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      
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
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/vendor_location_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  VendorDashboardScreenState createState() => VendorDashboardScreenState();
}

class VendorDashboardScreenState extends State<VendorDashboardScreen>
    with WidgetsBindingObserver {
  final _vendorService = VendorService();
  final _location = VendorLocationService.instance;
  StreamSubscription<VendorModel?>? _subscription;
  VendorModel? _vendor;
  bool _loading = true;
  bool _saving = false;
  bool _foreground = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.addListener(_locationChanged);
    fetchVendorDetails();
  }

  void _locationChanged() {
    if (mounted) { setState(() {}); }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      unawaited(_location.pause());
    }
    // Resuming is explicit: avoids restarting sharing after logout or a
    // permission dialog, and makes foreground-only behaviour visible.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _location.removeListener(_locationChanged);
    _subscription?.cancel();
    unawaited(_location.pause());
    super.dispose();
  }

  Future<void> fetchVendorDetails() async {
    await _subscription?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) { return; }
    setState(() { _loading = true; _error = null; });
    _subscription = _vendorService.watchVendorProfile(uid).listen((vendor) {
      if (!mounted) { return; }
      setState(() { _vendor = vendor; _loading = false; _error = null; });
      if (vendor?.isOpen != true && _location.isSharing) { unawaited(_location.pause()); }
    }, onError: (Object error) {
      if (mounted) { setState(() {
        _loading = false;
        _error = 'Could not load your stall. Check your connection and retry.';
      }); }
    });
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on GPS before sharing your location.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) { permission = await Geolocator.requestPermission(); }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Allow location access in your phone settings.');
    }
    if (permission == LocationPermission.denied) { throw StateError('Location permission is required.'); }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 12));
  }

  Future<void> _toggle(bool open) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_saving || uid == null) { return; }
    if (open && (_vendor?.stallName.trim().isEmpty ?? true)) {
      _message('Set up your stall name before opening.');
      return;
    }
    if (open) {
      final agreed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Open stall and share location?'),
        content: const Text('Your location updates while StallSeeker is open. Sharing pauses when you leave the app or lock your phone. Customers will see the last known location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open stall')),
        ],
      ));
      if (agreed != true || !mounted) { return; }
    }
    setState(() => _saving = true);
    try {
      if (open) {
        final position = await _position();
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) { return; }
        await _vendorService.updateVendorLocation(uid, position.latitude, position.longitude);
        await _vendorService.toggleStallStatus(uid, true);
        if (mounted && _foreground) { await _location.start(uid); }
      } else {
        await _location.pause();
        await _vendorService.toggleStallStatus(uid, false);
      }
      _message(open ? 'Your stall is open.' : 'Your stall is closed.');
    } catch (_) {
      _message('Could not update your stall. Check GPS, location permission, and connection, then retry.');
    } finally {
      if (mounted) { setState(() => _saving = false); }
    }
  }

  Future<void> _resume() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) { return; }
    setState(() => _saving = true);
    try {
      await _position();
      if (mounted && _foreground && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _location.start(uid);
      }
    } catch (_) {
      _message('Could not share location. Check GPS and location permission.');
    } finally {
      if (mounted) { setState(() => _saving = false); }
    }
  }

  void _message(String text) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) { return const Center(child: CircularProgressIndicator()); }
    if (_error != null) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, textAlign: TextAlign.center),
      TextButton(onPressed: fetchVendorDetails, child: const Text('Retry')),
    ])); }
    final open = _vendor?.isOpen ?? false;
    return RefreshIndicator(
      onRefresh: fetchVendorDetails,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
        Text(_vendor?.stallName.isNotEmpty == true ? _vendor!.stallName : 'Set up your stall',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(contentPadding: EdgeInsets.zero,
            title: Text(open ? 'Stall open' : 'Stall closed'),
            subtitle: const Text('Control whether customers can find you on the live map'),
            value: open, onChanged: _saving ? null : _toggle),
          if (_saving) const LinearProgressIndicator(),
          const Divider(),
          Text(!open ? 'Location sharing off'
              : _location.error ?? (_location.isSharing ? 'Location sharing active while the app is open' : 'Location sharing paused')),
          if (open && !_location.isSharing)
            TextButton.icon(onPressed: _saving ? null : _resume,
                icon: const Icon(Icons.my_location), label: const Text('Resume sharing')),
        ]))),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VendorMenuScreen())),
            icon: const Icon(Icons.restaurant_menu), label: const Text('Manage menu & stock')),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Stall information', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_vendor?.category ?? 'Choose a food category'),
          Text(_vendor?.openingHours ?? 'Add your opening hours'),
          const SizedBox(height: 8),
          Text(_vendor?.description ?? 'Tell customers what you sell.'),
          TextButton.icon(onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditStallScreen())),
              icon: const Icon(Icons.edit_outlined), label: const Text('Edit stall')),
        ]))),
      ]),
    );
  }
}
````

## File: lib/features/auth/screens/login_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    // If this screen was pushed on top of something else -- e.g. a
    // guest was prompted to log in before following a vendor -- close
    // it automatically once a real account signs in, so the user
    // lands back where they were instead of getting stuck here.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null &&
          !user.isAnonymous &&
          mounted &&
          Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) { return; }

    setState(() => _isLoading = true);

    final error = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) { return; }

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email address and we will send you a link to reset your password.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid email first.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);

                          final error =
                              await _authService.resetPassword(email: email);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!mounted) { return; }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error ??
                                    'Password reset email sent. Check your inbox.',
                              ),
                              backgroundColor:
                                  error != null ? Colors.red : Colors.green,
                            ),
                          );
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Reusable pill-shaped text field to match the image
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: Color(0xFF212121),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: Colors.grey.shade500,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFE5E5E5), // BOX  BUTTON EMAIL A
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey screen background

      // iOS-style AppBar with centered title and back button
      appBar: AppBar(
        title: const Text(
          'Sign In',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.grey),
          onPressed: () => Navigator.pop(context), // Adds the Back button
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Email Address Field
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your password' : null,
                ),

                const SizedBox(height: 32),

                // "Sign In" Coral Button (Pill-shaped)
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6E41), // Coral color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot Password? Button
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFFFF6E41), // Coral color
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Footer: Don't have an account? Sign Up
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : _goToRegister,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: const Color(0xFFFF6E41),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authStream = FirebaseAuth.instance.authStateChanges();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: _authStream, builder: (context, snapshot) {
      if (snapshot.hasError) { return const _AccountRecovery(message: 'Could not check your session. Please sign in again.'); }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user == null) { return const WelcomeScreen(); }
      if (user.isAnonymous) { return const CustomerHomeScreen(); }
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
    unawaited(NotificationService.instance.syncTokenForCurrentUser());
  }

  void _listen() {
    _profile = FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots();
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data?.data()?['role'];
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists ||
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
          if (mounted) { NotificationService.instance.setNavigationReady(role == 'customer'); }
        });
        return role == 'vendor' ? const VendorMainScreen() : const CustomerHomeScreen();
      },
    );
  }
}

class _AccountRecovery extends StatelessWidget {
  const _AccountRecovery({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_outlined, size: 40),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center),
      if (retry != null) TextButton(onPressed: retry, child: const Text('Retry')),
      TextButton(onPressed: () async {
        try { await AuthService().signOut(); }
        catch (_) {
          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not sign out. Please retry.'))); }
        }
      }, child: const Text('Sign out')),
    ]),
  )));
}
````

## File: lib/features/customer/home/customer_home_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/vendor_service.dart';
import '../following/customer_following_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _vendorService = VendorService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  int _selectedIndex = 0;
  String _searchQuery = '';
  GoogleMapController? _mapController;
  LatLng? _customerPosition;

  // NEW: Track the visible map area to filter vendors
  LatLngBounds? _visibleBounds;

  final List<String> _tabTitles = ['Home', 'Following', 'Profile'];
  String _greeting = 'Welcome!';

  String? _selectedVendorId;
  bool _isLocatingCustomer = true;
  bool _locationPermissionGranted = false;
  String? _locationError;
  String? _category;
  Timer? _freshnessTimer;
  late Stream<List<VendorModel>> _vendors;
  final ScrollController _stallScrollController = ScrollController();
  List<VendorModel> _visibleVendors = [];
  double _cardExtent = 288;
  int _cameraRequest = 0;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _vendors = _vendorService.getOpenVendors();
    _getCustomerLocation();
    _loadGreeting();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) { setState(() {}); }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _stallScrollController.dispose();
    _freshnessTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { return; }

    if (user.isAnonymous) {
      if (mounted) { setState(() => _greeting = 'Welcome, Guest'); }
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final name = userData?.fullName;
    if (mounted) {
      setState(() {
        _greeting =
            (name != null && name.isNotEmpty) ? 'Welcome, $name' : 'Welcome!';
      });
    }
  }

  bool _locationRequestActive = false;

  Future<void> _getCustomerLocation() async {
    if (_isLocatingCustomer && _locationRequestActive) { return; }
    _locationRequestActive = true;
    if (mounted) { setState(() { _isLocatingCustomer = true; _locationError = null; _locationPermissionGranted = false; }); }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { throw StateError('Turn on GPS, or browse the map manually.'); }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(permission == LocationPermission.deniedForever
            ? 'Allow location access in phone settings, or browse manually.'
            : 'Location access denied. You can still browse the map.');
      }

      if (mounted) { setState(() => _locationPermissionGranted = true); }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) { return; }

      setState(() {
        _customerPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_customerPosition!, 15),
      );
    } catch (error) {
      if (mounted) { setState(() {
        _locationError = error is StateError ? error.message.toString()
            : 'Could not find your location. Retry or browse the map manually.';
      }); }
    } finally {
      _locationRequestActive = false;
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  Future<void> _selectVendor(VendorModel vendor) async {
    if (!vendor.hasValidLocation) { return; }
    FocusScope.of(context).unfocus();
    final request = ++_cameraRequest;
    setState(() => _selectedVendorId = vendor.vendorId);
    _revealSelectedCard();
    final controller = _mapController;
    if (controller == null) { return; }
    try {
      final currentZoom = await controller.getZoomLevel();
      if (!mounted || request != _cameraRequest) { return; }
      // A modest zoom-in with a useful street-level ceiling. Repeated taps
      // keep the same useful view, instead of zooming further on every tap.
      final targetZoom = currentZoom < 16 ? 16.0 : currentZoom.clamp(16.0, 17.5).toDouble();
      await controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(vendor.latitude, vendor.longitude), targetZoom,
      ));
    } catch (_) {
      // A controller may be disposed while the user changes screens.
    }
  }

  void _revealSelectedCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stallScrollController.hasClients) { return; }
      final index = _visibleVendors.indexWhere((v) => v.vendorId == _selectedVendorId);
      if (index < 0) { return; }
      final offset = (index * _cardExtent).clamp(
        0.0, _stallScrollController.position.maxScrollExtent,
      ).toDouble();
      _stallScrollController.animateTo(offset,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    });
  }

  // NEW: Update the visible bounds whenever the map stops moving
  void _updateVisibleBounds() async {
    if (_mapController == null) { return; }
    try {
      final bounds = await _mapController!.getVisibleRegion();
      if (mounted) {
        setState(() => _visibleBounds = bounds);
        _revealSelectedCard();
      }
    } catch (_) {
      // Controller may have been disposed during navigation.
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) { return '${meters.toStringAsFixed(0)} m away'; }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? _greeting : _tabTitles[_selectedIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              tooltip: 'Refresh',
              onPressed: _getCustomerLocation,
            ),

        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMapTab(),
          const CustomerFollowingScreen(),
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFFFF6E41)),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Color(0xFFFF6E41)),
            label: 'Following',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF6E41)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return StreamBuilder<List<VendorModel>>(
      stream: _vendors,
      builder: (context, snapshot) {
        final allVendors = (snapshot.data ?? []).where((v) => v.hasValidLocation &&
            (_category == null || v.category == _category)).toList();

        final query = _searchQuery.trim().toLowerCase();
        final filteredVendors = query.isEmpty
            ? allVendors
            : allVendors
                .where((v) =>
                    v.stallName.toLowerCase().contains(query) ||
                    v.category.toLowerCase().contains(query))
                .toList();

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
          if (_customerPosition == null) { return 0; }
          final distA = Geolocator.distanceBetween(
            _customerPosition!.latitude,
            _customerPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = Geolocator.distanceBetween(
            _customerPosition!.latitude,
            _customerPosition!.longitude,
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
                  snippet: v.category,
                  onTap: () => _openVendorDetails(v),
                ),
                consumeTapEvents: true,
                onTap: () => _selectVendor(v),
              ),
            )
            .toSet();

        return LayoutBuilder(builder: (context, constraints) {
          // The panel is a sibling below the map, never an overlay. It cannot
          // grow to obscure the map, even after tapping or scrolling a stall.
          final shortViewport = constraints.maxHeight < 400;
          final panelHeight = shortViewport ? 52.0
              : (constraints.maxHeight * .34).clamp(168.0, 180.0).toDouble();
          final cardWidth = (constraints.maxWidth - 48).clamp(220.0, 340.0).toDouble();
          _cardExtent = cardWidth + 12;
          return Column(children: [
            Expanded(child: Stack(children: [
              Positioned.fill(child: GoogleMap(
                initialCameraPosition: _defaultPosition,
                markers: markers,
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                padding: const EdgeInsets.fromLTRB(12, 76, 12, 12),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_customerPosition != null) {
                    controller.animateCamera(CameraUpdate.newLatLngZoom(_customerPosition!, 15));
                  }
                  _updateVisibleBounds();
                },
                onCameraIdle: _updateVisibleBounds,
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                },
              )),
              Positioned(top: 12, left: 12, right: 12,
                child: Material(elevation: 3, shadowColor: const Color(0x22000000),
                  color: Colors.white, borderRadius: BorderRadius.circular(18),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() { _searchQuery = value; _selectedVendorId = null; }),
                    decoration: InputDecoration(
                      hintText: 'Find a stall or food category',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: InputBorder.none, enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      prefixIcon: PopupMenuButton<String>(
                        tooltip: 'Filter category', icon: Icon(Icons.tune_rounded,
                          color: _category == null ? AppColors.textDark : AppColors.primary),
                        onSelected: (value) => setState(() {
                          _category = value == 'All' ? null : value;
                          _selectedVendorId = null;
                        }),
                        itemBuilder: (_) => ['All', 'Beverages', 'Snacks & Desserts', 'Malay Food', 'Chinese Food', 'Indian Food', 'Western', 'Noodles']
                            .map((value) => PopupMenuItem(value: value, child: Text(value))).toList(),
                      ),
                      suffixIcon: _searchQuery.isEmpty ? const Icon(Icons.search_rounded)
                          : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded),
                              onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }),
                    ),
                  ),
                )),
              if (!shortViewport && (_locationError != null || _isLocatingCustomer || _category != null))
                Positioned(top: 76, left: 12, right: 68,
                  child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    child: Padding(padding: const EdgeInsets.all(10),
                      child: Text(_locationError ?? (_isLocatingCustomer ? 'Finding your location…' : 'Category: $_category'),
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    ),
                  )),
              Positioned(right: 12, bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'recenter_button', tooltip: 'My location',
                  backgroundColor: Colors.white, foregroundColor: AppColors.textDark,
                  onPressed: _getCustomerLocation,
                  child: _isLocatingCustomer
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded),
                )),
            ])),
            SizedBox(height: panelHeight, child: Material(color: Colors.white,
              child: Column(children: [
                SizedBox(height: 44, child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Row(children: [
                    Expanded(child: Text(snapshot.hasError ? 'Could not load stalls'
                        : snapshot.connectionState == ConnectionState.waiting ? 'Finding stalls…'
                        : '${onScreenVendors.length} open stalls in this area',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                    TextButton(onPressed: snapshot.hasError
                        ? () => setState(() => _vendors = _vendorService.getOpenVendors())
                        : onScreenVendors.isEmpty ? null : () => _showAllStalls(onScreenVendors),
                      child: Text(snapshot.hasError ? 'Retry' : 'View all')),
                  ]),
                )),
                if (!shortViewport) Expanded(child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : onScreenVendors.isEmpty
                        ? Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(snapshot.hasError ? 'Check your connection and retry.'
                                : 'Move the map, zoom out, or clear your filters.', textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))))
                        : ListView.builder(
                            controller: _stallScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 4, 10),
                            itemCount: onScreenVendors.length,
                            itemExtent: _cardExtent,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _stallCard(onScreenVendors[index]),
                            ),
                          )),
              ]),
            )),
          ]);
        });
      },
    );
  }

  String? _distanceTo(VendorModel vendor) {
    final position = _customerPosition;
    if (position == null) { return null; }
    return _formatDistance(Geolocator.distanceBetween(
      position.latitude, position.longitude, vendor.latitude, vendor.longitude));
  }

  Widget _stallPhoto(VendorModel vendor, {double size = 48}) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(width: size, height: size, color: const Color(0xFFFFF0E9),
      child: vendor.imageUrl.isEmpty ? const Icon(Icons.storefront_rounded, color: AppColors.primary)
          : Image.network(vendor.imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppColors.primary))),
  );

  Widget _stallCard(VendorModel vendor) {
    final selected = vendor.vendorId == _selectedVendorId;
    return Material(
      color: selected ? const Color(0xFFFFF8F3) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.primary : const Color(0xFFE5E7EB), width: selected ? 1.5 : 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () => _selectVendor(vendor),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _stallPhoto(vendor), const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vendor.stallName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text([vendor.category, if (_distanceTo(vendor) != null) _distanceTo(vendor)!].join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ])),
              if (selected) const Padding(padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18)),
            ]),
            Row(children: [
              Icon(vendor.hasFreshLocation ? Icons.circle : Icons.history_rounded,
                size: 10, color: vendor.hasFreshLocation ? const Color(0xFF15803D) : const Color(0xFF92400E)),
              const SizedBox(width: 5),
              Expanded(child: Text(vendor.hasFreshLocation ? 'Location updated' : 'Last known location',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
              TextButton(onPressed: () => _openVendorDetails(vendor),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact),
                child: const Text('View stall', style: TextStyle(fontSize: 11))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _showAllStalls(List<VendorModel> vendors) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<VendorModel>(
      context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * .6,
        child: Column(children: [
          ListTile(title: const Text('Open stalls in this area', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Choose a stall to find it on the map'),
            trailing: IconButton(tooltip: 'Close list', icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
          const Divider(height: 1),
          Expanded(child: ListView.separated(itemCount: vendors.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _stallPhoto(vendor), title: Text(vendor.stallName),
                subtitle: Text([vendor.category, if (_distanceTo(vendor) != null) _distanceTo(vendor)!].join(' · ')),
                trailing: const Icon(Icons.near_me_outlined, color: AppColors.primary),
                onTap: () => Navigator.pop(context, vendor));
            },
          )),
        ]),
      ),
    );
    if (mounted && selected != null) { await _selectVendor(selected); }
  }

  void _openVendorDetails(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
  }
}
````
