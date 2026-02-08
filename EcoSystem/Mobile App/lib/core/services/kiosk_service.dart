// =============================================================================
// KIOSK SERVICE - Manage RVM Kiosks from Firestore
// =============================================================================
// Handles kiosk data for the map and hardware integration.
// Prepares for ESP32 API communication.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Kiosk status enum
enum KioskStatus {
  available,
  maintenance,
  offline,
}

/// Kiosk model for RVM machines
class Kiosk {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String status; // 'available', 'maintenance', 'offline'
  final String openingHours;
  final int plasticCount; // Total plastic bottles recycled
  final int metalCount; // Total metal cans recycled
  final DateTime? lastUpdated;

  Kiosk({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.status = 'available',
    this.openingHours = '24/7',
    this.plasticCount = 0,
    this.metalCount = 0,
    this.lastUpdated,
  });

  factory Kiosk.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Kiosk(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'available',
      openingHours: data['openingHours'] ?? '24/7',
      plasticCount: data['plasticCount'] ?? 0,
      metalCount: data['metalCount'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'openingHours': openingHours,
      'plasticCount': plasticCount,
      'metalCount': metalCount,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  bool get isOperational => status == 'available';
  
  String get statusDisplay {
    switch (status) {
      case 'available':
        return 'Available';
      case 'maintenance':
        return 'Under Maintenance';
      case 'offline':
        return 'Offline';
      default:
        return 'Unknown';
    }
  }
}

/// Kiosk Service for Firestore CRUD operations
class KioskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all kiosks stream (real-time)
  Stream<List<Kiosk>> getKiosksStream() {
    return _firestore
        .collection('kiosks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Kiosk.fromFirestore(doc)).toList());
  }

  /// Get single kiosk
  Future<Kiosk?> getKiosk(String kioskId) async {
    try {
      final doc = await _firestore.collection('kiosks').doc(kioskId).get();
      if (doc.exists) {
        return Kiosk.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get kiosk: $e');
      return null;
    }
  }

  /// Update kiosk status (called by API when ESP32 sends status)
  Future<bool> updateKioskStatus(String kioskId, String status) async {
    try {
      await _firestore.collection('kiosks').doc(kioskId).update({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Failed to update kiosk status: $e');
      return false;
    }
  }

  /// Record recycling transaction (called by API when ESP32 sends data)
  Future<bool> recordTransaction({
    required String kioskId,
    required String userId,
    required int plasticCount,
    required int metalCount,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Calculate points (10 points per item)
      final totalItems = plasticCount + metalCount;
      final points = totalItems * 10;

      // 1. Create transaction record
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'kioskId': kioskId,
        'userId': userId,
        'plasticCount': plasticCount,
        'metalCount': metalCount,
        'points': points,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update user points
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'currentPoints': FieldValue.increment(points),
        'totalPoints': FieldValue.increment(points),
        'recycledCount': FieldValue.increment(totalItems),
      });

      // 3. Update kiosk counts
      final kioskRef = _firestore.collection('kiosks').doc(kioskId);
      batch.update(kioskRef, {
        'plasticCount': FieldValue.increment(plasticCount),
        'metalCount': FieldValue.increment(metalCount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 4. Add notification for user
      final notificationRef = userRef.collection('notifications').doc();
      batch.set(notificationRef, {
        'type': 'points_earned',
        'title': 'Points Earned!',
        'message': 'You earned $points points for recycling $totalItems items.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await batch.commit();
      AppLogger.info('Transaction recorded: $totalItems items, $points points');
      return true;
    } catch (e) {
      AppLogger.error('Failed to record transaction: $e');
      return false;
    }
  }

  // ===========================================================================
  // ADMIN METHODS
  // ===========================================================================

  /// Create new kiosk (admin)
  Future<String?> createKiosk(Kiosk kiosk) async {
    try {
      final doc = await _firestore.collection('kiosks').add(kiosk.toFirestore());
      return doc.id;
    } catch (e) {
      AppLogger.error('Failed to create kiosk: $e');
      return null;
    }
  }

  /// Update kiosk (admin)
  Future<bool> updateKiosk(String kioskId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('kiosks').doc(kioskId).update(updates);
      return true;
    } catch (e) {
      AppLogger.error('Failed to update kiosk: $e');
      return false;
    }
  }

  /// Delete kiosk (admin)
  Future<bool> deleteKiosk(String kioskId) async {
    try {
      await _firestore.collection('kiosks').doc(kioskId).delete();
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete kiosk: $e');
      return false;
    }
  }

  /// Seed initial kiosks (for testing)
  Future<void> seedKiosks() async {
    final kiosks = [
      Kiosk(
        id: '',
        name: 'CIC College Kiosk',
        address: 'CIC College, 5th Settlement, New Cairo',
        latitude: 30.0347,
        longitude: 31.4295,
        status: 'available',
        openingHours: '8:00 AM - 8:00 PM',
      ),
      Kiosk(
        id: '',
        name: 'Mall of Arabia Kiosk',
        address: 'Mall of Arabia, 6th October City',
        latitude: 30.0131,
        longitude: 31.0091,
        status: 'available',
        openingHours: '10:00 AM - 10:00 PM',
      ),
      Kiosk(
        id: '',
        name: 'Smart Village Kiosk',
        address: 'Smart Village, Km 28 Cairo-Alex Road',
        latitude: 30.0711,
        longitude: 31.0167,
        status: 'maintenance',
        openingHours: '9:00 AM - 6:00 PM',
      ),
    ];

    for (final kiosk in kiosks) {
      await createKiosk(kiosk);
    }
    AppLogger.info('Seeded ${kiosks.length} kiosks');
  }
}
