// MANAGE ACCOUNT
// - signup, login, signin with google, signinasguest, getuserdata, save cust location, signout, resetpassword, req email verfiy, confir email verify, change password, update anem, delete account

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
