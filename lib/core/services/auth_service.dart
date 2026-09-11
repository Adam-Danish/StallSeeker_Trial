import 'notification_service.dart';
import 'vendor_location_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleSignInReady = false;

  // google_sign_in v7 requires an explicit initialize() call, exactly
  // once, before authenticate()/signOut() are used. Cheap to call
  // repeatedly since it's guarded by the flag below.
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user != null) {
        await _ensureUserProfile(user);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } on FirebaseException {
      await _discardFailedSignIn();
      return 'Your account profile could not be restored. Check your connection and try again.';
    } catch (e) {
      await _discardFailedSignIn();
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

      if (user != null) {
        await _ensureUserProfile(user);
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
    } on FirebaseException {
      await _discardFailedSignIn(includeGoogle: true);
      return 'Your account profile could not be restored. Check your connection and try again.';
    } catch (e) {
      await _discardFailedSignIn(includeGoogle: true);
      return e.toString();
    }
  }

  Future<void> _discardFailedSignIn({bool includeGoogle = false}) async {
    if (includeGoogle) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Continue clearing Firebase Auth even if Google cannot sign out.
      }
    }
    try {
      await _auth.signOut();
    } catch (_) {
      // The original sign-in/profile error is the useful error to return.
    }
  }

  /// Repairs the split account model after a profile document was removed
  /// while the Firebase Authentication account was left intact.
  ///
  /// A surviving vendor document is the only reliable evidence that the
  /// account was a vendor. Otherwise a recovered account is treated as a
  /// customer, matching the existing Google sign-in default.
  Future<void> _ensureUserProfile(User user) async {
    final userRef =
        _firestore.collection(FirestoreCollections.users).doc(user.uid);
    final profile = await userRef.get();
    final existing = profile.data();
    final existingRole = existing?['role'];
    if (existingRole == 'customer' || existingRole == 'vendor') {
      return;
    }

    final vendor = await _firestore
        .collection(FirestoreCollections.vendors)
        .doc(user.uid)
        .get();
    final recoveredRole = vendor.exists ? 'vendor' : 'customer';
    final savedEmail = existing?['email'];
    final savedName = existing?['fullName'];

    await userRef.set({
      'uid': user.uid,
      'email': savedEmail is String && savedEmail.trim().isNotEmpty
          ? savedEmail
          : user.email ?? '',
      'fullName': savedName is String && savedName.trim().isNotEmpty
          ? savedName
          : user.displayName ?? '',
      'role': recoveredRole,
      if (existing?['createdAt'] == null)
        'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> repairCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    await _ensureUserProfile(user);
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

  Future<String?> requestEmailVerificationCode({String? newEmail}) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('requestEmailVerificationCode');
      await callable.call(<String, dynamic>{
        'purpose': newEmail == null ? 'registration' : 'email_change',
        if (newEmail != null) 'newEmail': newEmail.trim(),
      });
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Could not send the verification code.';
    } catch (_) {
      return 'Could not send the verification code. Please try again.';
    }
  }

  Future<String?> confirmEmailVerificationCode({
    required String code,
    String? newEmail,
  }) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('confirmEmailVerificationCode');
      await callable.call(<String, dynamic>{
        'purpose': newEmail == null ? 'registration' : 'email_change',
        'code': code.trim(),
        if (newEmail != null) 'newEmail': newEmail.trim(),
      });
      await _auth.currentUser?.reload();
      await _auth.currentUser?.getIdToken(true);
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'The verification code could not be confirmed.';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'The account could not be refreshed.';
    } catch (_) {
      return 'The verification code could not be confirmed. Please try again.';
    }
  }

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
