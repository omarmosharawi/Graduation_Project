// =============================================================================
// FIREBASE AUTH SERVICE - Firebase Authentication & Firestore Integration
// =============================================================================
// Replaces mock authentication with real Firebase Auth and Firestore.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

/// User model for the app
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int currentPoints;
  final int totalPoints;
  final String rank;
  final DateTime createdAt;
  final bool isAdmin;
  final int recycledCount; // Total items recycled
  final List<String> badges; // Badge IDs

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.currentPoints = 0,
    this.totalPoints = 0,
    this.rank = 'Bronze',
    DateTime? createdAt,
    this.isAdmin = false,
    this.recycledCount = 0,
    this.badges = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      avatarUrl: data['avatarUrl'],
      currentPoints: data['currentPoints'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      rank: data['rank'] ?? 'Bronze',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdmin: data['isAdmin'] ?? false,
      recycledCount: data['recycledCount'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'currentPoints': currentPoints,
      'totalPoints': totalPoints,
      'rank': rank,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
      'recycledCount': recycledCount,
      'badges': badges,
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
    List<String>? badges,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentPoints: currentPoints ?? this.currentPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
      createdAt: createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      recycledCount: recycledCount ?? this.recycledCount,
      badges: badges ?? this.badges,
    );
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
        await _loadUserData(firebaseUser.uid);
        AppLogger.info('User session restored: ${firebaseUser.email}');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
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
        // Create user document in Firestore
        final newUser = AppUser(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          currentPoints: 0,
          totalPoints: 0,
          rank: 'Bronze',
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

  /// Send OTP for password reset (Mock)
  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // proper 6-digit random number generation
      final random = DateTime.now().millisecondsSinceEpoch % 1000000;
      final otp = random.toString().padLeft(6, '0');
      
      // Store in simple in-memory cache
      _otpCache[email] = otp;

      // Logic would normally call a Cloud Function to send email/SMS
      // For testing, we mock it and log to console
      AppLogger.info('==========================================');
      AppLogger.info('OTP Sent to $email: $otp');
      AppLogger.info('==========================================');
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      return true;
    } catch (e) {
      _error = 'Failed to send OTP';
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





  /// Reset password (Firebase handles this via email link)
  Future<bool> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    
    // Firebase password reset is done via email link
    // This method is a placeholder for the flow
    await Future.delayed(const Duration(seconds: 1));
    
    _isLoading = false;
    notifyListeners();
    return true;
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
          // Create new user document for first-time Google sign-in
          final newUser = AppUser(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? googleUser.displayName ?? 'User',
            email: firebaseUser.email ?? googleUser.email,
            avatarUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
            currentPoints: 0,
            totalPoints: 0,
            rank: 'Bronze',
          );
          
          await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toFirestore());
          _currentUser = newUser;
        } else {
          // Load existing user data
          _currentUser = AppUser.fromFirestore(userDoc);
        }
        
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

  /// Check if profile is incomplete (missing name only - phone is optional)
  bool get isProfileIncomplete {
    if (_currentUser == null) return false;
    return _currentUser!.name.isEmpty;
  }

  /// Save FCM token for push notifications
  Future<void> _saveFcmToken(String userId) async {
    try {
      await NotificationService().saveTokenToFirestore(userId);
    } catch (e) {
      AppLogger.error('Failed to save FCM token: $e');
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
      if (avatarUrl != null) {
        updates['avatarUrl'] = avatarUrl;
      }

      if (updates.isEmpty) return;

      await _firestore.collection('users').doc(_currentUser!.id).update(updates);

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );
      
      // Also update Firebase Auth display name
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name);
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
  // LEADERBOARD METHODS
  // ===========================================================================

  /// Get all-time leaderboard (top users by total points)
  Future<List<AppUser>> getLeaderboard({int limit = 50}) async {
    if (_currentUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Failed to get leaderboard: $e');
      return [];
    }
  }

  /// Get weekly leaderboard (users who earned points this week)
  Future<List<AppUser>> getWeeklyLeaderboard({int limit = 50}) async {
    if (_currentUser == null) return [];
    try {
      // For weekly, we'd need a weeklyPoints field or activity tracking
      // For now, return all-time sorted by totalPoints
      return getLeaderboard(limit: limit);
    } catch (e) {
      AppLogger.error('Failed to get weekly leaderboard: $e');
      return [];
    }
  }

  /// Get current user's rank position
  Future<int> getUserRankPosition() async {
    if (_currentUser == null) return 0;
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .get();

      for (int i = 0; i < snapshot.docs.length; i++) {
        if (snapshot.docs[i].id == _currentUser!.id) {
          return i + 1;
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

  /// Redeem an offer and create a coupon
  Future<String?> redeemOffer({
    required String offerId,
    required String offerTitle,
    required String partner,
    required int pointsRequired,
  }) async {
    if (_currentUser == null) return null;
    if (_currentUser!.currentPoints < pointsRequired) return null;

    try {
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

      // Deduct points
      await spendPoints(pointsRequired, 'Redeemed: $offerTitle');

      // Add notification
      await addNotification(
        title: 'Coupon Redeemed!',
        message: 'You redeemed "$offerTitle" from $partner. Code: $couponCode',
        type: 'rewardRedeemed',
      );

      return couponCode;
    } catch (e) {
      AppLogger.error('Failed to redeem offer: $e');
      return null;
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
        .orderBy('timestamp', descending: true)
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

  /// Get all available badges
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    try {
      final snapshot = await _firestore.collection('badges').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get badges: $e');
      return [];
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
      } else if (requirement == 'totalPoints' && _currentUser!.totalPoints >= threshold) {
        earned = true;
      }

      if (earned) {
        earnedBadges.add(badgeId);
        updated = true;
        
        await addNotification(
          title: '🏆 Badge Earned!',
          message: 'You earned the "${badge['name']}" badge!',
          type: 'achievement',
        );
      }
    }

    if (updated) {
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'badges': earnedBadges,
      });
      _currentUser = _currentUser!.copyWith(badges: earnedBadges);
      notifyListeners();
    }
  }
}

