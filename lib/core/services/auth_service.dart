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
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
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

  // Firebase keeps deleted/disabled users cached until explicitly refreshed.
  Future<void> validateCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      await user.reload();
      await _auth.currentUser?.getIdToken(true);
    } on FirebaseAuthException catch (error) {
      if (const {
        'user-not-found',
        'user-disabled',
        'user-token-expired',
        'invalid-user-token',
      }.contains(error.code)) {
        await signOut();
        return;
      }
      rethrow;
    }
  }

  // Register user with Email, Password, Name & Role
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? vendorPhone,
    String? customerPhone,
  }) async {
    try {
      final normalizedPhone =
          role == 'vendor' ? normalizeVendorPhone(vendorPhone ?? '') : null;
      if (role == 'vendor' && normalizedPhone == null) {
        return 'Enter a valid Malaysian business phone number.';
      }
      final customerPhoneInput = (customerPhone ?? '').trim();
      final normalizedCustomerPhone =
          role == 'customer' && customerPhoneInput.isNotEmpty
              ? normalizeVendorPhone(customerPhoneInput)
              : null;
      if (role == 'customer' &&
          customerPhoneInput.isNotEmpty &&
          normalizedCustomerPhone == null) {
        return 'Enter a valid Malaysian phone number.';
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
          phoneNumber: normalizedCustomerPhone,
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
        try {
          await batch.commit();
        } catch (_) {
          // A failed registration must not reserve the email indefinitely.
          await credential.user!.delete();
          rethrow;
        }

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
      final UserCredential userCredential;
      if (kIsWeb) {
        // Browser Back can leave the popup Future pending after the user
        // abandons Google sign-in. Always return control to the login UI.
        userCredential = await _auth
            .signInWithPopup(GoogleAuthProvider())
            .timeout(const Duration(seconds: 25));
      } else {
        await _ensureGoogleSignInReady();
        final googleUser = await _googleSignIn
            .authenticate()
            .timeout(const Duration(seconds: 25));
        final credential = GoogleAuthProvider.credential(
          idToken: googleUser.authentication.idToken,
        );
        userCredential = await _auth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 25));
      }
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
        try {
          await _firestore
              .collection(FirestoreCollections.users)
              .doc(user.uid)
              .set(newUser.toMap());
        } catch (_) {
          await user.delete();
          rethrow;
        }
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
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'redirect-cancelled-by-user') {
        return 'cancelled';
      }
      if (e.code == 'popup-blocked') {
        return 'Allow pop-ups for StallSeeker, then try Google sign-in again.';
      }
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
    try {
      await VendorLocationService.instance.pause();
    } catch (_) {
      debugPrint('Location cleanup could not finish.');
    }
    try {
      await NotificationService.instance.clearCurrentDevice();
    } catch (_) {
      debugPrint('Notification cleanup could not finish.');
    }
    try {
      if (!kIsWeb && _googleSignInReady) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      debugPrint('Google session cleanup could not finish.');
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
  Future<String?> updateFullName(
    String uid,
    String newName, {
    String? customerPhone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous || user.uid != uid) {
        return 'Please sign in to edit your profile.';
      }
      final name = newName.trim();
      if (name.isEmpty || name.length > 80) {
        return 'Enter a name between 1 and 80 characters.';
      }
      final updates = <String, dynamic>{'fullName': name};
      if (customerPhone != null) {
        final input = customerPhone.trim();
        final normalized = input.isEmpty ? null : normalizeVendorPhone(input);
        if (input.isNotEmpty && normalized == null) {
          return 'Enter a valid Malaysian phone number.';
        }
        updates['phoneNumber'] = normalized ?? FieldValue.delete();
      }
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .update(updates);
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

// Delete the sign-in identity before background cleanup of account data.
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
        if (kIsWeb) {
          await user.reauthenticateWithPopup(GoogleAuthProvider());
        } else {
          await _ensureGoogleSignInReady();
          final googleUser = await _googleSignIn.authenticate();
          final googleAuth = googleUser.authentication;
          await user.reauthenticateWithCredential(
              GoogleAuthProvider.credential(idToken: googleAuth.idToken));
        }
      } else {
        return 'Log out, sign in again, then retry account deletion.';
      }

      // Reauthentication updates auth_time; force the callable to use that token.
      await user.getIdToken(true);
      final result = await FirebaseFunctions.instance
          .httpsCallable('deleteAccount')
          .call<Map<String, dynamic>>();
      if (result.data['deleted'] != true) {
        return 'Could not finish account deletion. Please retry.';
      }
      try {
        await LocalDemoBookingService().removeAccountData(user.uid);
      } catch (_) {
        debugPrint('Account deleted; local booking cleanup was unavailable.');
      }
      await signOut();
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
