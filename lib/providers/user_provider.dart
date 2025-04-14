import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  int _dailyBonus = 0;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get dailyBonus => _dailyBonus;
  bool get isAuthenticated => _user != null;

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Listen to auth state changes
      FirebaseAuth.instance.authStateChanges().listen((
        User? firebaseUser,
      ) async {
        if (firebaseUser != null) {
          await _loadUserData(firebaseUser);
        } else {
          _user = null;
          notifyListeners();
        }
      });
    } catch (e) {
      _setError('Failed to initialize: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load user data
  Future<void> _loadUserData(User firebaseUser) async {
    _setLoading(true);

    try {
      // Create user if not exists and get user data
      UserModel userModel = await _authService.createUserIfNotExists(
        firebaseUser,
      );

      // Check for daily login bonus
      _dailyBonus = await _firestoreService.processDailyLogin(
        userModel.uid,
        userModel.lastLoginDate,
      );

      // Set up listener for user data changes
      _firestoreService.getUserData(firebaseUser.uid).listen((updatedUser) {
        _user = updatedUser;
        notifyListeners();
      });
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _setError('Failed to sign in with Google: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Process spin and get earned points
  Future<int> processSpin() async {
    if (_user == null) return 0;

    try {
      return await _firestoreService.processSpin(_user!.uid, _user!.spinsToday);
    } catch (e) {
      _setError('Failed to process spin: ${e.toString()}');
      return 0;
    }
  }

  // Create withdrawal request
  Future<bool> createWithdrawalRequest(String upiId, int amount) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.createWithdrawalRequest(
        _user!.uid,
        upiId,
        amount,
      );
      return true;
    } catch (e) {
      _setError('Failed to create withdrawal request: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Apply referral code
  Future<bool> applyReferralCode(String referralCode) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      bool success = await _firestoreService.applyReferralCode(
        _user!.uid,
        referralCode,
      );
      if (!success) {
        _setError('Invalid referral code or already applied');
      }
      return success;
    } catch (e) {
      _setError('Failed to apply referral code: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update UPI ID
  Future<void> updateUpiId(String upiId) async {
    if (_user == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.updateUpiId(_user!.uid, upiId);
    } catch (e) {
      _setError('Failed to update UPI ID: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
