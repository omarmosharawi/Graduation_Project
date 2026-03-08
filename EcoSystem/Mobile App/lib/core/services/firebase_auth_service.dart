// =============================================================================
// FIREBASE AUTH SERVICE - Firebase Authentication & Firestore Integration
// =============================================================================
// Replaces mock authentication with real Firebase Auth and Firestore.
// =============================================================================

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

/// User model for the app
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final int currentPoints;
  final int totalPoints;
  final String rank;
  final DateTime createdAt;
  final bool isAdmin;
  final int recycledCount; // Total items recycled
  final int totalPlastic;
  final int totalMetal;
  final int pickupCount;
  final List<String> badges; // Badge IDs
  final String? kioskCode; // Unique 8-digit code for kiosk identification

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatarUrl,
    this.currentPoints = 0,
    this.totalPoints = 0,
    this.rank = 'Bronze',
    DateTime? createdAt,
    this.isAdmin = false,
    this.recycledCount = 0,
    this.totalPlastic = 0,
    this.totalMetal = 0,
    this.pickupCount = 0,
    this.badges = const [],
    this.kioskCode,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      address: data['address'],
      avatarUrl: data['avatarUrl'],
      currentPoints: data['currentPoints'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      rank: data['rank'] ?? 'Bronze',
      createdAt: _parseDateTime(data['createdAt']),
      isAdmin: data['isAdmin'] ?? false,
      recycledCount: data['recycledCount'] ?? 0,
      totalPlastic: data['totalPlastic'] ?? 0,
      totalMetal: data['totalMetal'] ?? 0,
      pickupCount: data['pickupCount'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      kioskCode: data['kioskCode'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'avatarUrl': avatarUrl,
      'currentPoints': currentPoints,
      'totalPoints': totalPoints,
      'rank': rank,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
      'recycledCount': recycledCount,
      'totalPlastic': totalPlastic,
      'totalMetal': totalMetal,
      'pickupCount': pickupCount,
      'badges': badges,
      'kioskCode': kioskCode,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    int? currentPoints,
    int? totalPoints,
    String? rank,
    bool? isAdmin,
    int? recycledCount,
    int? totalPlastic,
    int? totalMetal,
    int? pickupCount,
    String? address,
    List<String>? badges,
    String? kioskCode,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentPoints: currentPoints ?? this.currentPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
      createdAt: createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      recycledCount: recycledCount ?? this.recycledCount,
      totalPlastic: totalPlastic ?? this.totalPlastic,
      totalMetal: totalMetal ?? this.totalMetal,
      pickupCount: pickupCount ?? this.pickupCount,
      badges: badges ?? this.badges,
      kioskCode: kioskCode ?? this.kioskCode,
    );
  }
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Firebase Authentication Service
class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // Convenience getters for user data
  String get userName => _currentUser?.name ?? 'Guest';
  String get userEmail => _currentUser?.email ?? '';
  int get currentPoints => _currentUser?.currentPoints ?? 0;
  int get totalPoints => _currentUser?.totalPoints ?? 0;
  String get userRank => _currentUser?.rank ?? 'Bronze';

  /// Initialize and check for existing session
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        AppLogger.info('Initializing auth: Found existing user ${firebaseUser.email}');
        await _loadUserData(firebaseUser.uid);
        _startUserListener(firebaseUser.uid);
        // Ensure FCM token is up to date
        await _saveFcmToken(firebaseUser.uid);
        AppLogger.info('User session restored: ${firebaseUser.email}');
      } else {
        AppLogger.info('Initializing auth: No existing user session found.');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start real-time listener for user data
  void _startUserListener(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _firestore.collection('users').doc(uid).snapshots().listen(
      (doc) {
        if (doc.exists) {
          _currentUser = AppUser.fromFirestore(doc);
          notifyListeners();
          AppLogger.info('User data updated in real-time');
          // Check for new badges whenever user data changes
          checkAndAwardBadges();
        }
      },
      onError: (e) => AppLogger.error('User listener error: $e'),
    );
  }

  /// Refresh user data manually
  Future<void> refreshUserData() async {
    if (_auth.currentUser != null) {
      await _loadUserData(_auth.currentUser!.uid);
    }
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
        // Backfill kioskCode for existing users who don't have one
        await _ensureKioskCode();
      }
    } catch (e) {
      AppLogger.error('Failed to load user data: $e');
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        _startUserListener(credential.user!.uid);
        // Save FCM token for push notifications
        await _saveFcmToken(credential.user!.uid);
        AppLogger.info('Login successful: $email');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      AppLogger.error('Login failed: ${e.code}');
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      AppLogger.error('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Generate unique 8-digit kiosk code
        final kioskCode = await _generateKioskCode();

        // Create user document in Firestore
        final newUser = AppUser(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          currentPoints: 0,
          totalPoints: 0,
          rank: 'Bronze',
          kioskCode: kioskCode,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toFirestore());

        _currentUser = newUser;
        AppLogger.info('Registration successful: $email');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      AppLogger.error('Registration failed: ${e.code}');
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      AppLogger.error('Registration error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent to: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      return false;
    } catch (e) {
      _error = 'Failed to send reset email';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cache for storing OTPs (Email -> OTP)
  final Map<String, String> _otpCache = {};

  /// Send OTP via email using the PHP API
  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Generate 6-digit OTP
      final random = Random();
      final otp = (100000 + random.nextInt(900000)).toString();
      
      // Store in-memory for verification
      _otpCache[email] = otp;

      // Call PHP API to send the email
      final url = Uri.parse('https://reward.ibrahim-azab.com/api/send-otp-email');
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-API-Key', '53cdf4760cdd5bd629a0b214d80e15ec');
      request.write('{"email":"$email","otp":"$otp"}');
      
      final response = await request.close();
      final statusCode = response.statusCode;
      client.close();

      if (statusCode == 200) {
        AppLogger.info('OTP email sent to $email successfully');
        // Always log to console as backup (for development/testing)
        AppLogger.info('==========================================');
        AppLogger.info('OTP for $email: $otp');
        AppLogger.info('==========================================');
        return true;
      } else {
        AppLogger.error('OTP API returned status $statusCode');
        _error = 'Verification email failed (Status: $statusCode)';
        // Still log it for development fallback
        AppLogger.info('OTP (API Status $statusCode): $otp');
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to send OTP: $e');
      // Even if API fails, OTP is in cache — log it for testing
      final fallbackOtp = _otpCache[email];
      if (fallbackOtp != null) {
        AppLogger.info('OTP (API failed, use console): $fallbackOtp');
      }
      _error = 'Failed to send OTP email';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify OTP (Mock)
  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Check against stored dynamic OTP
      final storedOtp = _otpCache[email];
      
      if (storedOtp != null && storedOtp == otp) {
        // Clear OTP after successful verification
        _otpCache.remove(email);
        return true;
      }
      
      _error = 'Invalid OTP. Please try again.';
      return false;
    } catch (e) {
      _error = 'Verification failed';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }





  /// Reset password via PHP API (Admin proxy)
  Future<bool> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final url = Uri.parse('https://reward.ibrahim-azab.com/api/reset-password');
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-API-Key', '53cdf4760cdd5bd629a0b214d80e15ec');
      request.write(json.encode({
        'email': email,
        'password': newPassword,
      }));
      
      final response = await request.close();
      final statusCode = response.statusCode;
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (statusCode == 200) {
        AppLogger.info('Password reset successfully for $email');
        return true;
      } else {
        AppLogger.error('Password reset API response: $responseBody');
        final data = json.decode(responseBody);
        _error = data['error'] ?? 'Failed to reset password';
        AppLogger.error('Password reset failed: $_error');
        return false;
      }
    } catch (e) {
      AppLogger.error('Connection error during password reset: $e');
      _error = 'Failed to connect to server';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      _userSubscription?.cancel();
      await _auth.signOut();
      _currentUser = null;
      AppLogger.info('User logged out');
    } catch (e) {
      AppLogger.error('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Check if user document exists in Firestore
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (!userDoc.exists) {
          // Generate unique 8-digit kiosk code
          final kioskCode = await _generateKioskCode();

          // Create new user document for first-time Google sign-in
          final newUser = AppUser(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? googleUser.displayName ?? 'User',
            email: firebaseUser.email ?? googleUser.email,
            avatarUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
            currentPoints: 0,
            totalPoints: 0,
            rank: 'Bronze',
            kioskCode: kioskCode,
          );
          
          await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toFirestore());
          _currentUser = newUser;
        } else {
          // Load existing user data
          _currentUser = AppUser.fromFirestore(userDoc);
          // Backfill kioskCode for existing users
          await _ensureKioskCode();
        }
        
        _startUserListener(firebaseUser.uid);
        AppLogger.info('Google Sign-In successful: ${firebaseUser.email}');
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Google Sign-In failed. Please try again.';
      AppLogger.error('Google Sign-In error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add points to user balance
  Future<void> addPoints(int points) async {
    if (_currentUser == null) return;

    try {
      final newCurrentPoints = _currentUser!.currentPoints + points;
      final newTotalPoints = _currentUser!.totalPoints + points;

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'currentPoints': newCurrentPoints,
        'totalPoints': newTotalPoints,
      });

      _currentUser = _currentUser!.copyWith(
        currentPoints: newCurrentPoints,
        totalPoints: newTotalPoints,
      );

      _updateRank();
      notifyListeners();
      AppLogger.info('Added $points points. New balance: $newCurrentPoints');
    } catch (e) {
      AppLogger.error('Failed to add points: $e');
    }
  }

  /// Redeem points
  Future<bool> redeemPoints(int points) async {
    if (_currentUser == null || _currentUser!.currentPoints < points) {
      return false;
    }

    try {
      final newPoints = _currentUser!.currentPoints - points;

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'currentPoints': newPoints,
      });

      _currentUser = _currentUser!.copyWith(currentPoints: newPoints);
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Failed to redeem points: $e');
      return false;
    }
  }

  /// Update user rank based on total points
  void _updateRank() {
    if (_currentUser == null) return;

    String newRank;
    final total = _currentUser!.totalPoints;

    if (total >= 10000) {
      newRank = 'Diamond';
    } else if (total >= 5000) {
      newRank = 'Platinum';
    } else if (total >= 2000) {
      newRank = 'Gold';
    } else if (total >= 500) {
      newRank = 'Silver';
    } else {
      newRank = 'Bronze';
    }

    if (newRank != _currentUser!.rank) {
      _currentUser = _currentUser!.copyWith(rank: newRank);
      _firestore.collection('users').doc(_currentUser!.id).update({
        'rank': newRank,
      });
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user's email is verified (uses cached value - call refreshEmailVerificationStatus first)
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Refresh email verification status from Firebase (needed after user verifies email)
  Future<bool> refreshEmailVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload(); // Refresh the user data from Firebase
        notifyListeners();
        return _auth.currentUser?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to refresh email verification: $e');
      return false;
    }
  }

  /// Check if user signed in with Google
  bool get isGoogleUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  /// Check if profile is incomplete (missing name, phone, or address)
  bool get isProfileIncomplete {
    if (_currentUser == null) return false;
    return _currentUser!.name.isEmpty || 
           (_currentUser!.phone?.isEmpty ?? true) || 
           (_currentUser!.address?.isEmpty ?? true);
  }

  /// Save FCM token for push notifications
  Future<void> _saveFcmToken(String userId) async {
    try {
      await NotificationService().saveTokenToFirestore(userId);
    } catch (e) {
      AppLogger.error('Failed to save FCM token: $e');
    }
  }

  /// Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(dynamic imageFile) async {
    if (_currentUser == null) return null;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${_currentUser!.id}.jpg');
      
      UploadTask uploadTask;
      if (imageFile is String) {
        // Correct implementation for path-based upload
        uploadTask = ref.putFile(File(imageFile));
      } else {
        uploadTask = ref.putFile(imageFile);
      }
      
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      
      await updateUserProfile(avatarUrl: url);
      return url;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'unknown') {
        AppLogger.error('Storage bucket may not be initialized. Please visit the Firebase Console and enable Storage for this project. Error: ${e.message}');
      } else {
        AppLogger.error('Firebase Storage error (${e.code}): ${e.message}');
      }
      return null;
    } catch (e) {
      AppLogger.error('Unexpected error during profile picture upload: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        AppLogger.info('Verification email sent');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to send verification email: $e');
      return false;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;

    try {
      final updates = <String, dynamic>{};
      
      if (name != null && name.isNotEmpty) {
        updates['name'] = name;
      }
      if (phone != null) {
        updates['phone'] = phone;
      }
      if (address != null) {
        updates['address'] = address;
      }
      if (avatarUrl != null) {
        updates['avatarUrl'] = avatarUrl;
      }

      if (updates.isEmpty) return;

      await _firestore.collection('users').doc(_currentUser!.id).update(updates);

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone, // Directly use phone (could be empty string)
        address: address, // Directly use address (could be empty string)
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );
      
      // Also update Firebase Auth display name
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name);
      }
      
      if (avatarUrl != null) {
        await _auth.currentUser?.updatePhotoURL(avatarUrl);
      }

      notifyListeners();
      AppLogger.info('User profile updated');
    } catch (e) {
      AppLogger.error('Failed to update profile: $e');
      rethrow;
    }
  }

  /// Get user-friendly error message
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  // ===========================================================================
  // KIOSK CODE GENERATION
  // ===========================================================================

  /// Generate a unique 8-digit numeric kiosk code
  Future<String> _generateKioskCode() async {
    final random = Random();
    String code;
    bool exists;

    do {
      // Generate random 8-digit number (10000000 - 99999999)
      code = (10000000 + random.nextInt(90000000)).toString();

      // Check for collision in Firestore
      final snapshot = await _firestore
          .collection('users')
          .where('kioskCode', isEqualTo: code)
          .limit(1)
          .get();
      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    return code;
  }

  /// Ensure existing user has a kioskCode, backfill if missing
  Future<void> _ensureKioskCode() async {
    if (_currentUser == null || _currentUser!.kioskCode != null) return;

    try {
      final code = await _generateKioskCode();
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'kioskCode': code,
      });
      _currentUser = _currentUser!.copyWith(kioskCode: code);
      AppLogger.info('Backfilled kioskCode for user: ${_currentUser!.id}');
    } catch (e) {
      AppLogger.error('Failed to backfill kioskCode: $e');
    }
  }

  // ===========================================================================
  // LEADERBOARD METHODS
  // ===========================================================================

  /// Get all-time leaderboard (all users by total points)
  Future<List<AppUser>> getLeaderboard({int limit = 200}) async {
    if (_currentUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Failed to get leaderboard: $e');
      return [];
    }
  }

  /// Get weekly leaderboard (users who earned points this week)
  /// Calculates points from transactions within the last 7 days.
  Future<List<AppUser>> getWeeklyLeaderboard({int limit = 50}) async {
    if (_currentUser == null) {
      AppLogger.warning('Cannot get weekly leaderboard: No current user logged in.');
      return [];
    }
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      AppLogger.info('--- Weekly Leaderboard Diagnostic ---');
      AppLogger.info('Current Time: $now');
      AppLogger.info('Week Ago Threshold: $weekAgo');
      AppLogger.info('Current User ID: ${_currentUser!.id}');
      
      // Query all transactions and filter locally
      final snapshot = await _firestore.collection('transactions').get();
      AppLogger.info('Found ${snapshot.docs.length} total transaction documents in root collection.');

      // Aggregate points per user
      final Map<String, int> userPoints = {};
      int validTransactions = 0;
      int filteredByDate = 0;
      int invalidData = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Safe timestamp parsing
        final dynamic rawTimestamp = data['timestamp'];
        DateTime? date;
        
        if (rawTimestamp is Timestamp) {
          date = rawTimestamp.toDate();
        } else if (rawTimestamp is String) {
          date = DateTime.tryParse(rawTimestamp.trim());
        }

        if (date != null) {
          if (date.isAfter(weekAgo)) {
            final dynamic userId = data['userId'];
            final dynamic points = data['points'];
            
            if (userId is String && points is num) {
              userPoints[userId] = (userPoints[userId] ?? 0) + points.toInt();
              validTransactions++;
              // Log specific info for current user transactions if found
              if (userId == _currentUser!.id) {
                AppLogger.info('Match for current user: ${points.toInt()} pts on $date');
              }
            } else {
              invalidData++;
              AppLogger.warning('Invalid data in doc ${doc.id}: userId=$userId, points=$points');
            }
          } else {
            filteredByDate++;
          }
        } else {
          invalidData++;
          AppLogger.warning('Could not parse timestamp in doc ${doc.id}: $rawTimestamp');
        }
      }

      AppLogger.info('Aggregation Stats: $validTransactions valid this week, $filteredByDate too old, $invalidData missing fields.');
      AppLogger.info('Unique users found with points this week: ${userPoints.length}');

      if (userPoints.isEmpty) {
        AppLogger.info('Returning empty list - no transactions matched criteria.');
        return [];
      }

      // Sort users by aggregated points descending
      final sortedEntries = userPoints.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
        
      // Take top N
      final topEntries = sortedEntries.take(limit).toList();
      
      // Fetch AppUser documents for these top users
      final List<AppUser> weeklyUsers = [];
      for (var entry in topEntries) {
        final userDoc = await _firestore.collection('users').doc(entry.key).get();
        if (userDoc.exists) {
          var user = AppUser.fromFirestore(userDoc);
          user = user.copyWith(totalPoints: entry.value); 
          weeklyUsers.add(user);
        } else {
          AppLogger.warning('User doc not found for points holder: ${entry.key}');
        }
      }

      AppLogger.info('Successfully fetched ${weeklyUsers.length} user profiles for leaderboard.');
      return weeklyUsers;
    } catch (e, stack) {
      AppLogger.error('Critical failure in getWeeklyLeaderboard: $e');
      AppLogger.error('Stack trace: $stack');
      return [];
    }
  }

  /// Get current user's actual rank position (all-time or weekly)
  Future<int> getUserRankPosition({bool isWeekly = false}) async {
    if (_currentUser == null) return 0;
    
    try {
      if (isWeekly) {
         // Calculate weekly rank using robust aggregation
         final weekAgo = DateTime.now().subtract(const Duration(days: 7));
         final snapshot = await _firestore.collection('transactions').get();
             
         final Map<String, int> userPoints = {};
         for (var doc in snapshot.docs) {
           final data = doc.data();
           
           final dynamic rawTimestamp = data['timestamp'];
           DateTime? date;
           if (rawTimestamp is Timestamp) {
             date = rawTimestamp.toDate();
           } else if (rawTimestamp is String) {
             date = DateTime.tryParse(rawTimestamp);
           }

           if (date != null && date.isAfter(weekAgo)) {
             final dynamic userId = data['userId'];
             final dynamic points = data['points'];
             if (userId is String && points is num) {
               userPoints[userId] = (userPoints[userId] ?? 0) + points.toInt();
             }
           }
         }
         
         if (!userPoints.containsKey(_currentUser!.id)) {
           return 0; // Not ranked this week
         }
         
         final sortedEntries = userPoints.entries.toList()
           ..sort((a, b) => b.value.compareTo(a.value));
           
         final index = sortedEntries.indexWhere((e) => e.key == _currentUser!.id);
         return index >= 0 ? index + 1 : 0;
      } else {
        // All-time rank
        final snapshot = await _firestore
            .collection('users')
            .orderBy('totalPoints', descending: true)
            .get();

        for (int i = 0; i < snapshot.docs.length; i++) {
          if (snapshot.docs[i].id == _currentUser!.id) {
            return i + 1;
          }
        }
      }
      return 0;
    } catch (e) {
      AppLogger.error('Failed to get user rank: $e');
      return 0;
    }
  }

  // ===========================================================================
  // NOTIFICATIONS METHODS
  // ===========================================================================

  /// Get user notifications
  Stream<QuerySnapshot> getNotificationsStream() {
    if (_currentUser == null) {
      return const Stream.empty();
    }
    
    return _firestore
        .collection('users')
        .doc(_currentUser!.id)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    if (_currentUser == null) return 0;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get unread notifications count as a stream for live updates
  Stream<int> getUnreadNotificationsCountStream() {
    if (_currentUser == null) return Stream.value(0);
    
    return _firestore
        .collection('users')
        .doc(_currentUser!.id)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_currentUser == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      AppLogger.error('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (_currentUser == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read: $e');
    }
  }

  /// Add a notification for the user
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    if (_currentUser == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Failed to add notification: $e');
    }
  }

  // ===========================================================================
  // COUPONS METHODS
  // ===========================================================================

  /// Get user's coupons
  Stream<QuerySnapshot> getCouponsStream() {
    if (_currentUser == null) return const Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(_currentUser!.id)
        .collection('coupons')
        .orderBy('redeemedAt', descending: true)
        .snapshots();
  }

  /// Redeem an offer and create a coupon (Returns coupon code or error message starting with 'Error: ')
  Future<String?> redeemOffer({
    required String offerId,
    required String offerTitle,
    required String partner,
    required int pointsRequired,
  }) async {
    if (_currentUser == null) return 'Error: You must be logged in to redeem offers.';
    if (_currentUser!.currentPoints < pointsRequired) return 'Error: You do not have enough points. This offer requires $pointsRequired pts.';

    try {
      // Deduct points first
      final success = await spendPoints(pointsRequired, 'Redeemed: $offerTitle');
      if (!success) {
        return 'Error: Failed to deduct points. Please try again.';
      }

      // Generate coupon code
      final couponCode = 'RW${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      // Create coupon
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('coupons')
          .add({
        'offerId': offerId,
        'offerTitle': offerTitle,
        'partner': partner,
        'couponCode': couponCode,
        'pointsSpent': pointsRequired,
        'redeemedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'isUsed': false,
      });

      // Add notification
      await addNotification(
        title: 'Coupon Redeemed!',
        message: 'You redeemed "$offerTitle" from $partner. Code: $couponCode',
        type: 'rewardRedeemed',
      );

      return couponCode;
    } catch (e) {
      AppLogger.error('Failed to redeem offer: $e');
      // If points were deducted but coupon creation failed, we ideally need a rollback mechanism
      // This is a simplified approach
      return 'Error: A network error occurred while redeeming. Please try again later.';
    }
  }

  /// Mark coupon as used
  Future<void> markCouponAsUsed(String couponId) async {
    if (_currentUser == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('coupons')
          .doc(couponId)
          .update({'isUsed': true});
    } catch (e) {
      AppLogger.error('Failed to mark coupon as used: $e');
    }
  }

  // ===========================================================================
  // POINTS HISTORY METHODS
  // ===========================================================================

  /// Get points history stream
  Stream<QuerySnapshot> getPointsHistoryStream() {
    if (_currentUser == null) return const Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(_currentUser!.id)
        .collection('pointsHistory')
        // Removed orderBy temporarily to debug empty list issue
        .limit(50)
        .snapshots();
  }

  /// Add points history entry
  Future<void> _addPointsHistoryEntry({
    required int points,
    required String type, // 'earned' or 'spent'
    required String description,
  }) async {
    if (_currentUser == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('pointsHistory')
          .add({
        'points': points,
        'type': type,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Failed to add points history: $e');
    }
  }

  /// Spend points (with history tracking)
  Future<bool> spendPoints(int points, String description) async {
    if (_currentUser == null) return false;
    if (_currentUser!.currentPoints < points) return false;

    try {
      final newCurrent = _currentUser!.currentPoints - points;
      
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'currentPoints': newCurrent,
      });

      _currentUser = _currentUser!.copyWith(currentPoints: newCurrent);
      notifyListeners();

      await _addPointsHistoryEntry(
        points: points,
        type: 'spent',
        description: description,
      );

      return true;
    } catch (e) {
      AppLogger.error('Failed to spend points: $e');
      return false;
    }
  }

  // ===========================================================================
  // BADGES METHODS
  // ===========================================================================

  // Default badges list used as fallback
  static const List<Map<String, dynamic>> defaultBadges = [
    {
      'id': 'first_bottle',
      'name': 'First Steps',
      'description': 'Recycle your first bottle',
      'icon': '🍼',
      'requirement': 'recycledCount',
      'threshold': 1,
    },
    {
      'id': 'recycler_10',
      'name': 'Getting Started',
      'description': 'Recycle 10 items',
      'icon': '♻️',
      'requirement': 'recycledCount',
      'threshold': 10,
    },
    {
      'id': 'recycler_50',
      'name': 'Eco Warrior',
      'description': 'Recycle 50 items',
      'icon': '🌱',
      'requirement': 'recycledCount',
      'threshold': 50,
    },
    {
      'id': 'recycler_100',
      'name': 'Century Club',
      'description': 'Recycle 100 items from pickups',
      'icon': '🏆',
      'requirement': 'pickupCount',
      'threshold': 100,
    },
    {
      'id': 'points_500',
      'name': 'Points Collector',
      'description': 'Earn 500 total points',
      'icon': '⭐',
      'requirement': 'totalPoints',
      'threshold': 500,
    },
    {
      'id': 'points_1000',
      'name': 'Points Master',
      'description': 'Earn 1000 total points',
      'icon': '🌟',
      'requirement': 'totalPoints',
      'threshold': 1000,
    },
    {
      'id': 'points_5000',
      'name': 'Points Legend',
      'description': 'Earn 5000 total points',
      'icon': '💫',
      'requirement': 'totalPoints',
      'threshold': 5000,
    },
  ];

  /// Get all available badges
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    try {
      final snapshot = await _firestore.collection('badges').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }
      // Return default badges if collection is empty
      return defaultBadges;
    } catch (e) {
      AppLogger.error('Failed to get badges: $e');
      return defaultBadges;
    }
  }

  /// Check and award badges based on user stats
  Future<void> checkAndAwardBadges() async {
    if (_currentUser == null) return;

    final allBadges = await getAllBadges();
    final earnedBadges = List<String>.from(_currentUser!.badges);
    bool updated = false;

    for (final badge in allBadges) {
      final badgeId = badge['id'] as String;
      if (earnedBadges.contains(badgeId)) continue;

      final requirement = badge['requirement'] as String? ?? '';
      final threshold = badge['threshold'] as int? ?? 0;

      bool earned = false;
        if (requirement == 'recycledCount' && _currentUser!.recycledCount >= threshold) {
        earned = true;
      } else if (requirement == 'pickupCount' && _currentUser!.pickupCount >= threshold) {
        earned = true;
      } else if (requirement == 'totalPoints' && _currentUser!.totalPoints >= threshold) {
        earned = true;
      }

      if (earned) {
        earnedBadges.add(badgeId);
        updated = true;
        
        // Add Firestore notification
        await addNotification(
          title: '🏆 Badge Earned!',
          message: 'You earned the "${badge['name']}" badge!',
          type: 'achievement',
        );

        // Send local push notification
        try {
          await NotificationService().showLocalNotification(
            title: '🏆 Badge Earned!',
            body: 'Congratulations! You unlocked the "${badge['name']}" badge.',
            payload: 'badge:$badgeId',
          );
        } catch (e) {
          AppLogger.error('Failed to send badge push notification: $e');
        }
      }
    }

    if (updated) {
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'badges': earnedBadges,
      });
      // Note: No need to copyWith here because the listener _startUserListener
      // will trigger when we update Firestore, which in turn calls notifyListeners.
    }
  }
}

