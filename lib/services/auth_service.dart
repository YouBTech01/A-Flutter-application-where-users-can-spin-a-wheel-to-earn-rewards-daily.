import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign In was cancelled by the user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Generate a random 6-character referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return 'BKC' +
        String.fromCharCodes(
          Iterable.generate(
            3,
            (_) => chars.codeUnitAt(random.nextInt(chars.length)),
          ),
        );
  }

  // Check if user exists in Firestore
  Future<bool> checkUserExists(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc.exists;
    } catch (e) {
      throw Exception('Failed to check if user exists: ${e.toString()}');
    }
  }

  // Create user in Firestore if not exists
  Future<UserModel> createUserIfNotExists(User user) async {
    try {
      bool exists = await checkUserExists(user.uid);

      if (!exists) {
        // Generate a unique referral code
        String referralCode = _generateReferralCode();
        bool isUnique = false;

        // Ensure the referral code is unique
        while (!isUnique) {
          QuerySnapshot querySnapshot =
              await _firestore
                  .collection('referralCodes')
                  .where(FieldPath.documentId, isEqualTo: referralCode)
                  .get();

          isUnique = querySnapshot.docs.isEmpty;
          if (!isUnique) {
            referralCode = _generateReferralCode();
          }
        }

        // Create new user
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          myReferralCode: referralCode,
          lastLoginDate: DateTime.now(),
        );

        // Save user to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // Save referral code to referralCodes collection
        await _firestore.collection('referralCodes').doc(referralCode).set({
          'uid': user.uid,
        });

        return newUser;
      } else {
        // Update last login date
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginDate': DateTime.now(),
        });

        // Return existing user
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      throw Exception('Failed to create or get user: ${e.toString()}');
    }
  }
}
