// =============================================================================
// AUTH SERVICE - Authentication State Management
// =============================================================================
// This service manages user authentication state including:
// - Login/logout functionality
// - User session persistence
// - Token management
// - User profile data
//
// Note: Currently uses mock data. Replace with actual API calls when backend
// is ready.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

/// -----------------------------------------------------------------------------
/// User Model
/// -----------------------------------------------------------------------------
/// Represents the authenticated user's profile data.

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int currentPoints;   // Spendable points for rewards
  final int totalPoints;     // Lifetime points for ranking
  final String rank;         // Bronze, Silver, Gold, Platinum

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.currentPoints = 0,
    this.totalPoints = 0,
    this.rank = 'Bronze',
  });

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    int? currentPoints,
    int? totalPoints,
    String? rank,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentPoints: currentPoints ?? this.currentPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'currentPoints': currentPoints,
        'totalPoints': totalPoints,
        'rank': rank,
      };

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        currentPoints: json['currentPoints'] as int? ?? 0,
        totalPoints: json['totalPoints'] as int? ?? 0,
        rank: json['rank'] as String? ?? 'Bronze',
      );
}

/// -----------------------------------------------------------------------------
/// Auth Service
/// -----------------------------------------------------------------------------
/// ChangeNotifier that manages authentication state throughout the app.

class AuthService extends ChangeNotifier {
  // Secure storage for tokens
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  // Current user state
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The currently authenticated user, or null if not logged in
  User? get currentUser => _currentUser;

  /// Whether authentication is in progress
  bool get isLoading => _isLoading;

  /// Last error message, if any
  String? get error => _error;

  /// Whether the user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize the auth service and restore session if available
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Check for stored token
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null) {
        // TODO: Validate token with backend and fetch user data
        // For now, using mock data
        await _restoreSession();
      }
    } catch (e) {
      AppLogger.error('Failed to initialize auth service', e);
      _error = 'Failed to restore session';
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Restore user session from stored data
  Future<void> _restoreSession() async {
    // TODO: Fetch user data from backend using stored token
    // Mock data for now
    _currentUser = const User(
      id: 'mock-user-123',
      name: 'Demo User',
      email: 'demo@reward.app',
      currentPoints: 250,
      totalPoints: 1500,
      rank: 'Silver',
    );
  }

  // ---------------------------------------------------------------------------
  // Authentication Methods
  // ---------------------------------------------------------------------------

  /// Login with email and password
  /// 
  /// Returns true if login was successful, false otherwise.
  /// Sets [error] if login fails.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // Example:
      // final response = await _apiService.login(email, password);
      // await _secureStorage.write(key: _tokenKey, value: response.token);

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Validate input (basic validation)
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      // Mock successful login
      _currentUser = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        currentPoints: 100,
        totalPoints: 500,
        rank: 'Bronze',
      );

      // Store token (mock token for now)
      await _secureStorage.write(key: _tokenKey, value: 'mock-token-12345');
      await _secureStorage.write(key: _userIdKey, value: _currentUser!.id);

      AppLogger.info('User logged in: ${_currentUser!.email}');
      return true;
    } catch (e) {
      AppLogger.error('Login failed', e);
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user account
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
      // TODO: Replace with actual API call

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Validate input
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('All fields are required');
      }

      // Mock successful registration
      _currentUser = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        currentPoints: 50, // Bonus points for signing up!
        totalPoints: 50,
        rank: 'Bronze',
      );

      // Store token
      await _secureStorage.write(key: _tokenKey, value: 'mock-token-12345');
      await _secureStorage.write(key: _userIdKey, value: _currentUser!.id);

      AppLogger.info('User registered: ${_currentUser!.email}');
      return true;
    } catch (e) {
      AppLogger.error('Registration failed', e);
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      AppLogger.info('Password reset requested for: $email');
      return true;
    } catch (e) {
      AppLogger.error('Password reset request failed', e);
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify OTP code
  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock verification (accept any 6-digit code for now)
      if (otp.length != 6) {
        throw Exception('Invalid OTP code');
      }

      AppLogger.info('OTP verified for: $email');
      return true;
    } catch (e) {
      AppLogger.error('OTP verification failed', e);
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password with new password
  Future<bool> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      AppLogger.info('Password reset for: $email');
      return true;
    } catch (e) {
      AppLogger.error('Password reset failed', e);
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear stored credentials
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userIdKey);

      _currentUser = null;
      _error = null;

      AppLogger.info('User logged out');
    } catch (e) {
      AppLogger.error('Logout failed', e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Points Management
  // ---------------------------------------------------------------------------

  /// Add points to the user's balance (called after recycling)
  void addPoints(int points) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      currentPoints: _currentUser!.currentPoints + points,
      totalPoints: _currentUser!.totalPoints + points,
    );

    // Update rank based on total points
    _updateRank();
    notifyListeners();
  }

  /// Redeem points for a reward
  bool redeemPoints(int points) {
    if (_currentUser == null) return false;
    if (_currentUser!.currentPoints < points) return false;

    _currentUser = _currentUser!.copyWith(
      currentPoints: _currentUser!.currentPoints - points,
    );
    notifyListeners();
    return true;
  }

  /// Update user rank based on total points
  void _updateRank() {
    if (_currentUser == null) return;

    String newRank;
    if (_currentUser!.totalPoints >= 10000) {
      newRank = 'Platinum';
    } else if (_currentUser!.totalPoints >= 5000) {
      newRank = 'Gold';
    } else if (_currentUser!.totalPoints >= 1000) {
      newRank = 'Silver';
    } else {
      newRank = 'Bronze';
    }

    if (newRank != _currentUser!.rank) {
      _currentUser = _currentUser!.copyWith(rank: newRank);
    }
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
