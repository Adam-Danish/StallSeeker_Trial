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
    if (picked == null) return null;
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

## File: lib/core/theme/app_theme.dart
````dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
    );
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
    await authService.signOut();
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
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/core/constants/app_colors.dart
````dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary =
      Color(0xFFE65100); // Deep Orange / Food Stall theme
  static const Color primaryLight = Color(0xFFFF8142);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF212121);
  static const Color textMuted = Color(0xFF757575);

  // Status Colors
  static const Color openGreen = Color(0xFF2E7D32);
  static const Color closedRed = Color(0xFFC62828);
  static const Color limitedYellow = Color(0xFFF57F17);
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

## File: lib/core/services/notification_service.dart
````dart
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

  // One-time setup: creates the notification channel, requests
  // permission, and wires up listeners for taps in every app state
  // (foreground, background, terminated). Safe to call more than once.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;
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
        if (vendorId != null) _openVendorDetails(vendorId);
      },
    );

    await _messaging.requestPermission();

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
      if (vendorId != null) _openVendorDetails(vendorId);
    });

    // App was fully closed and got launched by tapping the notification.
    final initialMessage = await _messaging.getInitialMessage();
    final vendorId = initialMessage?.data['vendorId'];
    if (vendorId != null) _openVendorDetails(vendorId);
  }

  // Fetches this device's FCM token and saves it on the logged-in user's
  // Firestore record, and keeps it updated if it ever rotates. Call this
  // once the user is known to be logged in.
  Future<void> syncTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(user.uid, token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) _saveToken(current.uid, newToken);
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  Future<void> _openVendorDetails(String vendorId) async {
    final navState = _navigatorKey?.currentState;
    if (navState == null) return;

    final VendorModel? vendor = await _vendorService.getVendorProfile(vendorId);
    if (vendor == null) return;

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
            vendor.toMap(),
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
      });
    } catch (e) {
      debugPrint('Error updating vendor location: $e');
      rethrow;
    }
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

## File: lib/features/customer/following/customer_following_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/follow_service.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerFollowingScreen extends StatelessWidget {
  const CustomerFollowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerId = FirebaseAuth.instance.currentUser?.uid;
    final followService = FollowService();
    final vendorService = VendorService();

    if (customerId == null) {
      return const Center(child: Text('Please log in to see followed stalls.'));
    }

    // Live stream of vendor IDs this customer follows. If they follow/
    // unfollow anywhere (including from the details screen), this list
    // updates automatically without needing to refresh.
    return StreamBuilder<List<String>>(
      stream: followService.getFollowedVendorIds(customerId),
      builder: (context, idSnapshot) {
        if (idSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vendorIds.length,
          itemBuilder: (context, index) {
            final vendorId = vendorIds[index];

            // Each followed ID needs its own one-time fetch to get the
            // vendor's current name/category/status for display.
            return FutureBuilder<VendorModel?>(
              future: vendorService.getVendorProfile(vendorId),
              builder: (context, vendorSnapshot) {
                if (!vendorSnapshot.hasData || vendorSnapshot.data == null) {
                  // Still loading, or the vendor profile no longer exists.
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
        );
      },
    );
  }
}
````

## File: lib/features/customer/vendor_details/vendor_details_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/follow_service.dart';
import '../../auth/screens/login_screen.dart';

class VendorDetailsScreen extends StatelessWidget {
  final VendorModel vendor;

  const VendorDetailsScreen({super.key, required this.vendor});

  Future<void> _openNavigation() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${vendor.latitude},${vendor.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.red;
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
        return 'Out of Stock';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuService = MenuService();
    final followService = FollowService();
    final currentUser = FirebaseAuth.instance.currentUser;
    final customerId = currentUser?.uid;
    final isGuest = currentUser?.isAnonymous ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(vendor.stallName.isNotEmpty ? vendor.stallName : 'Stall'),
        actions: [
          if (customerId != null)
            isGuest
                ? IconButton(
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Follow',
                    onPressed: () => _showLoginRequiredDialog(context),
                  )
                : StreamBuilder<bool>(
                    stream:
                        followService.isFollowing(customerId, vendor.vendorId),
                    builder: (context, snapshot) {
                      final isFollowing = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isFollowing ? Icons.favorite : Icons.favorite_border,
                          color: isFollowing ? Colors.red : null,
                        ),
                        tooltip: isFollowing ? 'Unfollow' : 'Follow',
                        onPressed: () async {
                          if (isFollowing) {
                            await followService.unfollowVendor(
                                customerId, vendor.vendorId);
                          } else {
                            await followService.followVendor(
                                customerId, vendor.vendorId);
                          }
                        },
                      );
                    },
                  ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (vendor.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                vendor.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.storefront,
                      size: 48, color: Colors.grey),
                ),
              ),
            ),
          if (vendor.imageUrl.isNotEmpty) const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: vendor.isOpen ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vendor.isOpen ? 'Open now' : 'Closed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: vendor.isOpen ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Category: ${vendor.category}'),
                  const SizedBox(height: 4),
                  Text('Hours: ${vendor.openingHours}'),
                  const SizedBox(height: 8),
                  Text(
                    vendor.description.isNotEmpty
                        ? vendor.description
                        : 'No description provided.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Navigate'),
                      onPressed: _openNavigation,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Menu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<MenuItemModel>>(
            stream: menuService.getMenuItems(vendor.vendorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No menu items yet.')),
                );
              }

              return Column(
                children: items.map((item) {
                  return Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.fastfood,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.fastfood,
                                      color: Colors.grey),
                                ),
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: Text('RM ${item.price.toStringAsFixed(2)}'),
                      trailing: Chip(
                        label: Text(
                          _statusLabel(item.status),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _statusColor(item.status),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
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

## File: lib/features/vendor/vendor_main_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../shared/logout_helper.dart';
import 'dashboard/vendor_dashboard_screen.dart';
import 'profile/vendor_profile_screen.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  final _authService = AuthService();
  int _selectedIndex = 0;

  static const _titles = ['Vendor Dashboard', 'My Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => confirmAndLogout(context, _authService),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          VendorDashboardScreen(),
          VendorProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
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

## File: lib/core/models/vendor_model.dart
````dart
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
  });

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
    );
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
    if (!_formKey.currentState!.validate()) return;

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
    if (mounted) setState(() => _isLoading = false);

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
    if (mounted) setState(() => _isLoading = false);

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
              // App icon and title
              const Icon(
                Icons.storefront,
                size: 64,
                color: const Color(0xFFFF6E41),
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

              // ---- Updated: Google button (Light Gray) ----
              _buildActionButton(
                icon: Image.asset('assets/google_logo.png', height: 20),
                label: 'Continue with Google',
                backgroundColor: const Color(0xFFF1F3F4), // Light gray
                foregroundColor: Colors.black, // Dark text
                onPressed: _isLoading ? null : _continueWithGoogle,
              ),
              const SizedBox(height: 10), // SPACING ANTARA BUTTON

              // ---- Updated: Email button (Coral/Orange) ----
              _buildActionButton(
                icon: const Icon(Icons.email_outlined, size: 24),
                label: 'Continue with Email',
                backgroundColor: const Color(0xFFFF6E41), // Vibrant coral
                foregroundColor: Colors.white, // White text
                onPressed: _isLoading ? null : _goToRegister,
              ),
              const SizedBox(height: 10),

              // ---- Updated: Guest button (Dark Black) ----
              _buildActionButton(
                icon: const Icon(Icons.person_outline, size: 24),
                label: 'Continue as Guest',
                backgroundColor: const Color(0xFF1C1C1E), // Dark gray/black
                foregroundColor: Colors.white, // White text
                onPressed: _isLoading ? null : _continueAsGuest,
              ),

              const SizedBox(height: 24),

              // "Already have an account? Sign In"
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

  // Reusable button – UPDATED to accept background and foreground colors
  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required Color backgroundColor, // New argument
    required Color foregroundColor, // New argument
    VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor, // The solid background color
        foregroundColor: foregroundColor, // Text & icon color
        side: BorderSide.none, // Removed the gray border entirely
        padding: const EdgeInsets.symmetric(vertical: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Kept your max roundness
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
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

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

## File: lib/features/vendor/profile/vendor_profile_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  UserModel? _userModel;
  bool _isLoading = true;

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
                          if (user == null || newName.isEmpty) return;

                          setDialogState(() => isSaving = true);
                          final error = await _authService.updateFullName(
                              user.uid, newName);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (error == null) {
                            await _loadUserData(); // refresh header card
                          }

                          if (!mounted) return;

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

                          if (!mounted) return;

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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.person, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userModel?.fullName.isNotEmpty == true
                            ? _userModel!.fullName
                            : 'Name Not Set',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userModel?.email ?? '',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _sectionHeader('ACCOUNT SETTINGS'),
        Card(
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: _showEditProfileDialog,
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
        ),
        _sectionHeader('SUPPORT & INFORMATION'),
        Card(
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.help_outline,
                title: 'FAQ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FaqScreen(isVendor: true)),
                  );
                },
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.info_outline,
                title: 'About StallSeeker',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: _settingsTile(
            icon: Icons.logout,
            title: 'Logout',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => confirmAndLogout(context, _authService),
          ),
        ),
      ],
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

    await docRef.set(newItem.toMap());
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
        .update(data);
  }

  // Quick Traffic Light Status Update
  Future<void> updateItemStatus(
      String vendorId, String itemId, String newStatus) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update({'status': newStatus});
  }

  // Delete item
  Future<void> deleteMenuItem(String vendorId, String itemId) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .delete();
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
  final _menuService = MenuService();
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  // Shared by both Add and Edit -- existingItem is null when adding.
  void _showItemDialog({MenuItemModel? existingItem}) {
    final isEditing = existingItem != null;
    final nameController =
        TextEditingController(text: existingItem?.name ?? '');
    final priceController = TextEditingController(
        text:
            existingItem != null ? existingItem.price.toStringAsFixed(2) : '');
    File? pickedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final file = await _storageService.pickImage();
                  if (file != null) {
                    setDialogState(() {
                      pickedImage = file;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: pickedImage != null
                      ? Image.file(pickedImage!, fit: BoxFit.cover)
                      : (isEditing && existingItem.imageUrl.isNotEmpty)
                          ? Image.network(
                              existingItem.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child:
                                    Icon(Icons.add_a_photo, color: Colors.grey),
                              ),
                            )
                          : const Center(
                              child:
                                  Icon(Icons.add_a_photo, color: Colors.grey),
                            ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Item Name (e.g. Nasi Lemak)'),
              ),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price (RM)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final price =
                          double.tryParse(priceController.text.trim()) ?? 0.0;
                      final user = _auth.currentUser;

                      if (name.isEmpty || price <= 0 || user == null) return;

                      setDialogState(() {
                        isUploading = true;
                      });

                      if (isEditing) {
                        // Only re-upload if the vendor picked a new photo
                        // this time -- otherwise leave the existing one.
                        String? newImageUrl;
                        if (pickedImage != null) {
                          newImageUrl =
                              await _storageService.uploadMenuItemImage(
                                  user.uid, existingItem.itemId, pickedImage!);
                        }

                        await _menuService.updateMenuItem(
                          user.uid,
                          existingItem.itemId,
                          name,
                          price,
                          imageUrl: newImageUrl,
                        );
                      } else {
                        // Photo needs the item's ID in its filename, so
                        // generate the ID first if a photo was picked.
                        String? itemId;
                        String? imageUrl;
                        if (pickedImage != null) {
                          itemId = _menuService.newMenuItemId(user.uid);
                          imageUrl = await _storageService.uploadMenuItemImage(
                              user.uid, itemId, pickedImage!);
                        }

                        await _menuService.addMenuItem(
                          user.uid,
                          name,
                          price,
                          itemId: itemId,
                          imageUrl: imageUrl,
                        );
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Save' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  // Shows a confirmation dialog before permanently deleting a menu
  // item. Deleting is irreversible (the document is gone from
  // Firestore immediately), so this prevents an accidental tap from
  // silently wiping out a dish.
  Future<void> _confirmDelete(String uid, MenuItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _menuService.deleteMenuItem(uid, item.itemId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : StreamBuilder<List<MenuItemModel>>(
              stream: _menuService.getMenuItems(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child:
                        Text('No menu items added yet.\nTap + Add Dish below!'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.fastfood,
                                              color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.fastfood,
                                            color: Colors.grey),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('RM ${item.price.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),

                            // Traffic Light Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Green Button (Available)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'available'
                                        ? Colors.green
                                        : Colors.green.shade100,
                                    size: item.status == 'available' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(
                                          user.uid, item.itemId, 'available'),
                                ),
                                // Yellow Button (Low Stock)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'low_stock'
                                        ? Colors.orange
                                        : Colors.orange.shade100,
                                    size: item.status == 'low_stock' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(
                                          user.uid, item.itemId, 'low_stock'),
                                ),
                                // Red Button (Out of Stock)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'out_of_stock'
                                        ? Colors.red
                                        : Colors.red.shade100,
                                    size:
                                        item.status == 'out_of_stock' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(user.uid,
                                          item.itemId, 'out_of_stock'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueGrey),
                                  onPressed: () =>
                                      _showItemDialog(existingItem: item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.grey),
                                  onPressed: () =>
                                      _confirmDelete(user.uid, item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
````

## File: lib/features/customer/profile/customer_profile_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  UserModel? _userModel;
  bool _isLoading = true;

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
                          if (user == null || newName.isEmpty) return;

                          setDialogState(() => isSaving = true);
                          final error = await _authService.updateFullName(
                              user.uid, newName);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (error == null) {
                            await _loadUserData(); // refresh header card
                          }

                          if (!mounted) return;

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

                          if (!mounted) return;

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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.person, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userModel?.fullName.isNotEmpty == true
                            ? _userModel!.fullName
                            : 'Name Not Set',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userModel?.email ?? '',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _sectionHeader('ACCOUNT SETTINGS'),
        Card(
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: _showEditProfileDialog,
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
        ),
        _sectionHeader('SUPPORT & INFORMATION'),
        Card(
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.help_outline,
                title: 'FAQ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FaqScreen(isVendor: false)),
                  );
                },
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.info_outline,
                title: 'About StallSeeker',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: _settingsTile(
            icon: Icons.logout,
            title: 'Logout',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => confirmAndLogout(context, _authService),
          ),
        ),
      ],
    );
  }
}
````

## File: lib/features/vendor/dashboard/vendor_dashboard_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';
import 'package:geolocator/geolocator.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _vendorService = VendorService();
  final _auth = FirebaseAuth.instance;

  VendorModel? _vendorModel;
  bool _isLoading = true;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchVendorDetails();
  }

  // Fetch Vendor Profile from Firestore
  Future<void> _fetchVendorDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      VendorModel? vendor = await _vendorService.getVendorProfile(user.uid);
      if (mounted) {
        setState(() {
          _vendorModel = vendor;
          _isOpen = vendor?.isOpen ?? false;
          _isLoading = false;
        });
      }
    }
  }

  // Asks the vendor to confirm before their location is captured and
  // shared. Shown every time they open the stall (not just once) since
  // location sharing is a meaningful thing to confirm each time, not a
  // one-off permission grant.
  Future<bool> _confirmShareLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share Your Location?'),
        content: const Text(
          'Turning your stall Open will capture your current location and '
          'show it to customers on the map so they can find you. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Share Location'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // Gets the vendor's current GPS position, handling permission requests
  // and the various ways a phone can refuse to give location.
  // Returns null if location could not be obtained for any reason.
  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on location services on your phone.'),
          ),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // First time asking, or the vendor said "no" before but can still
      // be asked again (as opposed to "denied forever" below).
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // The vendor permanently blocked location for this app. The app
      // cannot ask again -- they must go into phone Settings manually.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is permanently denied. '
              'Please enable it in your phone Settings > Apps > StallSeeker.',
            ),
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // Fast toggle for Open/Closed status
  Future<void> _handleStatusToggle(bool val) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (val) {
      // A stall with no name would show as "Unnamed Stall" to customers
      // on the map -- block opening until the vendor sets one, rather
      // than letting them go live with an unidentifiable stall.
      final hasName = _vendorModel?.stallName.trim().isNotEmpty == true;
      if (!hasName) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please set your stall name before opening your stall.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Ask for explicit confirmation every time the vendor opens --
      // not just a one-off system permission prompt, but a clear
      // in-app "yes, share my location" decision each time.
      final agreed = await _confirmShareLocation();
      if (!agreed) {
        // Vendor declined -- leave the switch off, don't touch Firestore
        // or request location at all.
        return;
      }
    }

    setState(() {
      _isOpen = val;
    });

    try {
      if (val) {
        // Opening the stall: capture the vendor's current GPS location
        // first, so customers can actually find this stall on the map.
        final position = await _determinePosition();

        if (position == null) {
          // Couldn't get a location (permission denied, GPS off, etc).
          // Revert the switch instead of marking the stall "open" with
          // no location -- that would show nothing on the customer map
          // anyway, so it's misleading to leave it toggled on.
          setState(() {
            _isOpen = false;
          });
          return;
        }

        await _vendorService.updateVendorLocation(
          user.uid,
          position.latitude,
          position.longitude,
        );
      }

      await _vendorService.toggleStallStatus(user.uid, val);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(val ? 'Stall is now OPEN!' : 'Stall is now CLOSED.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert switch state on failure
      setState(() {
        _isOpen = !val;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold/AppBar here -- VendorMainScreen (the bottom-nav shell)
    // now provides those, so this widget is just the tab's content.
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchVendorDetails,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Live Status Switch Card
                Card(
                  color: _isOpen ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stall Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _isOpen ? 'Currently Open' : 'Currently Closed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isOpen ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isOpen,
                          onChanged: _handleStatusToggle,
                          activeTrackColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stall Information Overview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _vendorModel?.stallName.isNotEmpty == true
                                    ? _vendorModel!.stallName
                                    : 'Stall Name Not Set',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditStallScreen(),
                                  ),
                                );
                                // Refresh details upon returning
                                _fetchVendorDetails();
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Category: ${_vendorModel?.category ?? "N/A"}'),
                        const SizedBox(height: 4),
                        Text('Hours: ${_vendorModel?.openingHours ?? "N/A"}'),
                        const SizedBox(height: 8),
                        Text(
                          _vendorModel?.description ??
                              'No description provided.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),

                        // Manage Menu Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.restaurant_menu),
                            label: const Text('Manage Menu & Stock'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VendorMenuScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
````

## File: lib/main.dart
````dart
import 'package:flutter/foundation.dart';
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
    debugPrint('Firebase initialization error ignored: $e');
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize(navigatorKey);

  runApp(const StallSeekerApp());
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

## File: lib/core/services/auth_service.dart
````dart
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
    if (_googleSignInReady) return;
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
      return "Google Sign-In timed out. This usually means the app's "
          "SHA-1 fingerprint isn't registered in Firebase Console yet "
          "(Project Settings > Your apps > Android app > Add fingerprint), "
          "or google-services.json needs to be re-downloaded after adding it.";
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
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .update({'fcmToken': FieldValue.delete()});
      } catch (e) {
        // Non-fatal -- proceed with sign out even if this fails (e.g.
        // offline at the moment of logout, or a guest with no
        // Firestore document to update in the first place).
        debugPrint("Error clearing FCM token on sign out: $e");
      }
    }

    if (_googleSignInReady) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
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
      if (user == null) return "No user is currently logged in.";
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

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

                          if (!mounted) return;

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

## File: lib/features/customer/home/customer_home_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../shared/logout_helper.dart';
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

  // Shown in the AppBar in place of a static "Search" title. Starts as
  // a neutral greeting while the user's name is being fetched.
  String _greeting = 'Welcome!';

  // Which vendor is currently highlighted -- set by tapping either a
  // marker on the map or a card in the horizontal list. Both use the
  // same selection so tapping either one highlights consistently.
  String? _selectedVendorId;

  // True while we're still trying to get the customer's GPS position.
  // Drives a small loading indicator on the map so it's clear the app
  // is actively locating them, not just stuck on the default view.
  bool _isLocatingCustomer = true;

  // Fallback camera position (Kuala Lumpur) used only until the
  // customer's real GPS position is obtained, or if location fails.
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _getCustomerLocation();
    _loadGreeting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Builds the "Welcome, [Name]" greeting. Guests (anonymous sign-in)
  // have no Firestore profile document to read a name from, so they
  // get a suitable generic greeting instead.
  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.isAnonymous) {
      if (mounted) setState(() => _greeting = 'Welcome!');
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

  // Gets the customer's current GPS position and, once found, animates
  // the map camera to center on them. Fails silently (falls back to the
  // default position) if permission is denied or GPS is off, since this
  // is a "nice to have" and shouldn't block the whole screen. The
  // `finally` block guarantees the loading indicator always turns off,
  // whether location succeeded, failed, or was denied.
  Future<void> _getCustomerLocation() async {
    if (mounted) setState(() => _isLocatingCustomer = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;

      setState(() {
        _customerPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_customerPosition!, 15),
      );
    } catch (_) {
      // Silently keep the default map position if anything goes wrong.
    } finally {
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  // Highlights a vendor (on both the map marker and its card) and pans
  // the camera to it, without navigating away -- tapping the same
  // vendor again (already selected) is what actually opens details.
  void _selectVendor(VendorModel vendor) {
    setState(() => _selectedVendorId = vendor.vendorId);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(vendor.latitude, vendor.longitude)),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _greeting,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false, // Aligns the title to the left (iOS style)
        backgroundColor: Colors.transparent, // Makes the bar invisible
        elevation: 0, // Removes the shadow
        // This screen overrides backgroundColor directly (bypassing the
        // app-wide AppBarTheme), so the status bar style needs setting
        // explicitly here too -- dark icons so time/battery/signal stay
        // visible against the light background behind this bar.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => confirmAndLogout(context, _authService),
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Following'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    // Live Firebase stream: any vendor that opens/closes updates this map
    // instantly, without the customer needing to refresh.
    return StreamBuilder<List<VendorModel>>(
      stream: _vendorService.getOpenVendors(),
      builder: (context, snapshot) {
        final allVendors = snapshot.data ?? [];

        // Filter by search text (matches stall name or category).
        final query = _searchQuery.trim().toLowerCase();
        final filteredVendors = query.isEmpty
            ? allVendors
            : allVendors
                .where((v) =>
                    v.stallName.toLowerCase().contains(query) ||
                    v.category.toLowerCase().contains(query))
                .toList();

        // For the floating card list: sort by distance from the customer
        // when we know their position, closest first.
        final nearbyVendors = List<VendorModel>.from(filteredVendors)
            .where((v) => v.latitude != 0.0 && v.longitude != 0.0)
            .toList();

        if (_customerPosition != null) {
          nearbyVendors.sort((a, b) {
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
        }

        final markers = nearbyVendors
            .map(
              (v) => Marker(
                markerId: MarkerId(v.vendorId),
                position: LatLng(v.latitude, v.longitude),
                // Selected marker shows in a different color so it's
                // clearly distinguishable from the rest.
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  v.vendorId == _selectedVendorId
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(
                  title: v.stallName,
                  snippet: v.category,
                  // Tapping the info bubble (the label that pops up
                  // above a selected marker) is what opens details --
                  // tapping the marker pin itself just selects it.
                  onTap: () => _openVendorDetails(v),
                ),
                onTap: () => _selectVendor(v),
              ),
            )
            .toSet();

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _defaultPosition,
              markers: markers,
              myLocationEnabled: true,
              // Replaced by our own recenter button below, so the
              // built-in one (which can end up hidden behind our
              // overlays) isn't shown as well.
              myLocationButtonEnabled: false,
              compassEnabled: true,
              padding: const EdgeInsets.only(top: 60),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_customerPosition != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_customerPosition!, 15),
                  );
                }
              },
              onTap: (_) {
                // Tapping empty map space clears the current selection.
                if (_selectedVendorId != null) {
                  setState(() => _selectedVendorId = null);
                }
              },
            ),

            // Search bar
            // Search bar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                elevation: 2, // <--- 1. Removed the shadow
                color: const Color(
                    0xFFF4F6F8), // <--- 2. Added the light grey background (matches your login inputs)
                borderRadius: BorderRadius.circular(
                    50), // <--- 3. Made it fully pill-shaped
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search your fav vendors here...', // <--- 5. Changed the text to match the vibe
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey
                            .shade400, // <--- 6. Made the hint text softer grey
                      ),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search,
                          color: Colors.grey), // Adjust icon color here
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            // Small "locating you" indicator, shown just below the
            // search bar only while GPS lookup is still in progress.
            if (_isLocatingCustomer)
              Positioned(
                top: 70,
                left: 12,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          ' Finding your location...',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator()),

            if (filteredVendors.isEmpty &&
                snapshot.connectionState != ConnectionState.waiting)
              Positioned(
                bottom: 130,
                left: 24,
                right: 24,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      query.isEmpty
                          ? 'No vendors are open nearby right now.'
                          : 'No vendors match "$_searchQuery".',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // Recenter-to-current-location button. Sits above the
            // nearby-stalls list when it's showing, otherwise sits
            // closer to the bottom.
            Positioned(
              right: 12,
              bottom: nearbyVendors.isNotEmpty ? 132 : 24,
              child: FloatingActionButton.small(
                heroTag: 'recenter_button',
                tooltip: 'Go to current location',
                onPressed: () {
                  if (_customerPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_customerPosition!, 15),
                    );
                  } else {
                    // Location wasn't available earlier (denied/off at
                    // the time) -- try fetching it again now.
                    _getCustomerLocation();
                  }
                },
                child: _isLocatingCustomer
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),

            // Floating horizontal list of nearby stalls, sitting above
            // the bottom navigation bar.
            if (nearbyVendors.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 112,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: nearbyVendors.length,
                    itemBuilder: (context, index) {
                      final vendor = nearbyVendors[index];
                      final isSelected = vendor.vendorId == _selectedVendorId;
                      final distanceLabel = _customerPosition != null
                          ? _formatDistance(
                              Geolocator.distanceBetween(
                                _customerPosition!.latitude,
                                _customerPosition!.longitude,
                                vendor.latitude,
                                vendor.longitude,
                              ),
                            )
                          : null;

                      return GestureDetector(
                        onTap: () {
                          // Tap once to highlight + pan to it on the
                          // map; tap again while already selected to
                          // open the full details screen.
                          if (isSelected) {
                            _openVendorDetails(vendor);
                          } else {
                            _selectVendor(vendor);
                          }
                        },
                        child: Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 10),
                          child: Card(
                            elevation: isSelected ? 8 : 4,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: isSelected
                                  ? BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: vendor.isOpen
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          vendor.stallName.isNotEmpty
                                              ? vendor.stallName
                                              : 'Unnamed Stall',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vendor.category,
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (distanceLabel != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      distanceLabel,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12),
                                    ),
                                  ],
                                  if (isSelected) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap again to view',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openVendorDetails(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
  }
}
````

## File: lib/features/auth/auth_wrapper.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/welcome_screen.dart';
import '../vendor/vendor_main_screen.dart';
import '../customer/home/customer_home_screen.dart';
import '../../core/services/notification_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          // Guests (anonymous sign-in) skip the Firestore role lookup
          // entirely and go straight to the customer experience --
          // there's no users/ document for them since they haven't
          // created a real account.
          if (user.isAnonymous) {
            return const CustomerHomeScreen();
          }

          NotificationService.instance.syncTokenForCurrentUser();

          // Live listener (.snapshots()), not a one-time .get(). This
          // matters for brand-new Google sign-ins: Firebase Auth's
          // state updates immediately, but the user's Firestore profile
          // document gets created a moment later by signInWithGoogle().
          // A one-time .get() can run in that gap, find nothing, and
          // (since it never checks again) get stuck showing
          // WelcomeScreen forever even after the document exists. A
          // live stream instead automatically re-fires and routes
          // correctly the instant the document appears.
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                final String role = userData?['role'] ?? 'customer';

                if (role == 'vendor') {
                  return const VendorMainScreen();
                } else {
                  return const CustomerHomeScreen();
                }
              }

              // Document doesn't exist yet -- show a brief loading
              // state instead of WelcomeScreen while we wait for it to
              // be created. If the document genuinely never gets
              // created (e.g. signup failed), the user is still signed
              // in at this point, so falling through to WelcomeScreen
              // (which offers sign-in options again) would be
              // confusing; a spinner is a more honest "still working
              // on it" state for the brief moment this normally takes.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}
````
