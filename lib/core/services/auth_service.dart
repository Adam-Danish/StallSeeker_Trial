import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

        // Save user details into Firestore 'users' collection
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        return null; // Success (no error message)
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
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
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
      print("Error fetching user data: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    // Clear this device's FCM token BEFORE signing out. If we sign out
    // first, request.auth becomes null and the security rules block the
    // write -- so this must happen while still authenticated. Without
    // this, a logged-out device keeps receiving push notifications for
    // an account no longer using it.
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .update({'fcmToken': FieldValue.delete()});
      } catch (e) {
        // Non-fatal -- proceed with sign out even if this fails
        // (e.g. offline at the moment of logout).
        print("Error clearing FCM token on sign out: $e");
      }
    }

    await _auth.signOut();
  }

  // Sends Firebase's built-in password reset email. Firebase handles
  // generating the reset link and the email itself -- this app never
  // sees or handles the new password directly.
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Could not send reset email.";
    } catch (e) {
      return e.toString();
    }
  }

  // Changes the password of the currently logged-in user.
  // Firebase requires a "recent" login for this -- if the user logged
  // in a while ago, this will fail with 'requires-recent-login' and
  // they need to log out and back in first before it will work.
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

  // Updates just the fullName field on the user's Firestore profile
  // document. Uses .update() (not .set()) so it only touches this one
  // field and leaves email/role/createdAt untouched.
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
