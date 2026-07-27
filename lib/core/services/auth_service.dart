import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with Role (Customer / Vendor)
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    UserCredential creds = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (creds.user != null) {
      UserModel newUser = UserModel(
        uid: creds.user!.uid,
        email: email,
        name: name,
        role: role,
      );

      await _db
          .collection(FirestoreCollections.users)
          .doc(creds.user!.uid)
          .set(newUser.toMap());
    }
    return creds;
  }

  // Sign In
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign Out
  Future<void> signOut() => _auth.signOut();
}
