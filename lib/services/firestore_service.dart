import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../models/user_model.dart';
import '../models/withdrawal_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Withdrawal requests collection reference
  CollectionReference get _withdrawalRequestsCollection =>
      _firestore.collection('withdrawalRequests');

  // Referral codes collection reference
  CollectionReference get _referralCodesCollection =>
      _firestore.collection('referralCodes');

  // Get user data
  Stream<UserModel> getUserData(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  // Get user data once
  Future<UserModel> getUserDataOnce(String uid) async {
    DocumentSnapshot doc = await _usersCollection.doc(uid).get();
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Update user data
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  // Check if today is a new day compared to last login
  bool isNewDay(DateTime lastLoginDate) {
    DateTime now = DateTime.now();
    return lastLoginDate.day != now.day ||
        lastLoginDate.month != now.month ||
        lastLoginDate.year != now.year;
  }

  // Update user daily login and reset spins
  Future<int> processDailyLogin(String uid, DateTime lastLoginDate) async {
    if (isNewDay(lastLoginDate)) {
      // Generate random daily bonus (₹1-₹3 = 1000-3000 points)
      Random random = Random();
      int bonusPoints = (1 + random.nextInt(3)) * 1000;

      await _usersCollection.doc(uid).update({
        'lastLoginDate': DateTime.now(),
        'spinsToday': 0,
        'points': FieldValue.increment(bonusPoints),
      });

      return bonusPoints;
    }
    return 0;
  }

  // Process spin and update points
  Future<int> processSpin(String uid, int currentSpins) async {
    if (currentSpins >= 5) {
      return 0; // Maximum spins reached
    }

    // Random points from spin (10, 25, 50, 100)
    List<int> pointOptions = [10, 25, 50, 100];
    Random random = Random();
    int wonPoints = pointOptions[random.nextInt(pointOptions.length)];

    await _usersCollection.doc(uid).update({
      'spinsToday': FieldValue.increment(1),
      'points': FieldValue.increment(wonPoints),
    });

    return wonPoints;
  }

  // Create withdrawal request
  Future<void> createWithdrawalRequest(
    String uid,
    String upiId,
    int amount,
  ) async {
    // Check if user has enough points
    UserModel user = await getUserDataOnce(uid);
    if (user.points < amount) {
      throw Exception('Insufficient points');
    }

    // Create withdrawal request
    await _withdrawalRequestsCollection.add({
      'uid': uid,
      'upiId': upiId,
      'amount': amount,
      'status': 'pending',
      'timestamp': DateTime.now(),
    });

    // Deduct points from user
    await _usersCollection.doc(uid).update({
      'points': FieldValue.increment(-amount),
    });
  }

  // Get user withdrawal requests
  Stream<List<WithdrawalRequestModel>> getUserWithdrawalRequests(String uid) {
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      // Fetch without orderBy (no index needed)
      QuerySnapshot snapshot =
          await _withdrawalRequestsCollection
              .where('uid', isEqualTo: uid)
              .get();

      // Convert to model objects
      List<WithdrawalRequestModel> withdrawals =
          snapshot.docs.map((doc) {
            return WithdrawalRequestModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

      // Sort in memory
      withdrawals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return withdrawals;
    });
  }

  // Apply referral code
  Future<bool> applyReferralCode(String uid, String referralCode) async {
    try {
      // Get current user
      UserModel user = await getUserDataOnce(uid);

      // Check if referral code exists
      DocumentSnapshot referralDoc =
          await _referralCodesCollection.doc(referralCode).get();
      if (!referralDoc.exists) {
        return false; // Referral code doesn't exist
      }

      // Get referrer UID from referral code document
      String referrerUid = (referralDoc.data() as Map<String, dynamic>)['uid'];

      // Check if user is trying to use their own referral code
      if (referrerUid == uid) {
        return false; // User cannot use their own referral code
      }

      // Create or get the appliedReferralCodes array
      DocumentSnapshot userDoc = await _usersCollection.doc(uid).get();
      List<String> appliedCodes = [];

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('appliedReferralCodes')) {
          appliedCodes = List<String>.from(data['appliedReferralCodes']);
        }
      }

      // Check if this code has already been used
      if (appliedCodes.contains(referralCode)) {
        return false; // Already used this specific code
      }

      // Add this code to applied codes
      appliedCodes.add(referralCode);

      // Update the user's document to add this code to applied codes list
      await _usersCollection.doc(uid).update({
        'referredBy': referralCode, // Last used code
        'referralCodeApplied': true, // Keep this for backward compatibility
        'appliedReferralCodes': appliedCodes,
        'points': FieldValue.increment(
          2000,
        ), // Give ₹2 = 2000 points to the user
      });

      // Give ₹2 = 2000 points to the referrer as well
      await _usersCollection.doc(referrerUid).update({
        'points': FieldValue.increment(2000),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to apply referral code: ${e.toString()}');
    }
  }

  // Update user UPI ID
  Future<void> updateUpiId(String uid, String upiId) async {
    await _usersCollection.doc(uid).update({'upiId': upiId});
  }
}
