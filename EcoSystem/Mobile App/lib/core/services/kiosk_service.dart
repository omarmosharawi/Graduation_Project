// =============================================================================
// KIOSK SERVICE - Manage RVM Kiosks from Firestore
// =============================================================================
// Handles kiosk data for the map and hardware integration.
// Prepares for ESP32 API communication.
// =============================================================================

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Kiosk status enum
enum KioskStatus {
  available,
  maintenance,
  offline,
  full,
  outOfService,
}

/// Kiosk model for RVM machines
class Kiosk {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String status; // 'available', 'maintenance', 'offline', 'full', 'out_of_service'
  final String openingHours;
  final int plasticCount; // Total plastic bottles recycled
  final int metalCount; // Total metal cans recycled
  final int currentCapacity; // Current items in bin
  final int maxCapacity; // Maximum bin capacity
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
    this.currentCapacity = 0,
    this.maxCapacity = 100,
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
      currentCapacity: data['currentCapacity'] ?? 0,
      maxCapacity: data['maxCapacity'] ?? 100,
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
      'currentCapacity': currentCapacity,
      'maxCapacity': maxCapacity,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  bool get isOperational => status == 'available';
  bool get isFull => status == 'full' || (maxCapacity > 0 && currentCapacity >= maxCapacity);
  double get capacityPercent => maxCapacity > 0 ? (currentCapacity / maxCapacity).clamp(0.0, 1.0) : 0.0;
  
  String get statusDisplay {
    switch (status) {
      case 'available':
        return 'Available';
      case 'maintenance':
        return 'Maintenance';
      case 'offline':
        return 'Offline';
      case 'full':
        return 'Full';
      case 'out_of_service':
        return 'Out of Service';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'available':
        return const Color(0xFF4CAF50); // Green
      case 'full':
        return const Color(0xFFFFC107); // Yellow/Amber
      case 'maintenance':
        return const Color(0xFFFF9800); // Orange
      case 'offline':
      case 'out_of_service':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}

/// Kiosk Service for Firestore CRUD operations
class KioskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all kiosks stream (real-time, filtered for users)
  Stream<List<Kiosk>> getKiosksStream({bool includeInactive = false}) {
    return _firestore
        .collection('kiosks')
        .snapshots()
        .map((snapshot) {
          final realKiosks = snapshot.docs.map((doc) => Kiosk.fromFirestore(doc)).toList();
          
          // Mock data for all cases
          final mockKiosks = [
            Kiosk(
              id: 'mock_full',
              name: 'Mock RVM - Full',
              address: '90th Street, New Cairo',
              latitude: 30.0163, 
              longitude: 31.4320,
              status: 'full',
              openingHours: '24/7',
              plasticCount: 80,
              metalCount: 20,
              currentCapacity: 100,
              maxCapacity: 100,
            ),
            Kiosk(
              id: 'mock_maintenance',
              name: 'Mock RVM - Maintenance',
              address: 'Waterway, New Cairo',
              latitude: 30.0400,
              longitude: 31.4500,
              status: 'maintenance',
              openingHours: '9:00 AM - 10:00 PM',
              plasticCount: 45,
              metalCount: 15,
              currentCapacity: 60,
              maxCapacity: 100,
            ),
            Kiosk(
              id: 'mock_offline',
              name: 'Mock RVM - Offline',
              address: 'Point 90 Mall',
              latitude: 30.0240,
              longitude: 31.4800,
              status: 'offline',
              openingHours: '10:00 AM - 12:00 AM',
              plasticCount: 10,
              metalCount: 5,
              currentCapacity: 15,
              maxCapacity: 100,
            ),
            Kiosk(
              id: 'mock_out_of_service',
              name: 'Mock RVM - Out of Service',
              address: 'Concord Plaza',
              latitude: 30.0282,
              longitude: 31.4672,
              status: 'out_of_service',
              openingHours: '24/7',
              plasticCount: 20,
              metalCount: 10,
              currentCapacity: 30,
              maxCapacity: 100,
            ),
          ];

          // Combine the REAL kiosks from your database with the mock kiosks.
          // IF a mock kiosk ID exists in Firestore, we use the real one (reactive).
          // Otherwise, we show the static mock for demo purposes.
          final Map<String, Kiosk> combined = {};
          
          // Add mocks first (fallbacks)
          for (final m in mockKiosks) {
            combined[m.id] = m;
          }
          
          // Override with real data from Firestore
          for (final r in realKiosks) {
            combined[r.id] = r;
          }

          final allKiosks = combined.values.toList();
          
          // Force return all kiosks to see mock cases on the map regardless of includeInactive flag
          if (includeInactive) return allKiosks;
          // Normally filters for regular users, but we want to show all cases for demonstration:
          return allKiosks; 
        });
  }

  /// Disable all kiosks except the primary working one
  Future<void> disableAllOthers(String workingKioskId) async {
    try {
      final snapshot = await _firestore.collection('kiosks').get();
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        if (doc.id != workingKioskId) {
          batch.update(doc.reference, {
            'status': 'offline',
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Ensure working one is available
          batch.update(doc.reference, {
            'status': 'available',
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
      AppLogger.info('Disabled all kiosks except: $workingKioskId');
    } catch (e) {
      AppLogger.error('Failed to disable kiosks: $e');
      rethrow;
    }
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
      
      // Calculate points
      final points = (plasticCount * 10) + (metalCount * 10);
      final totalItems = plasticCount + metalCount;

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
        'currentCapacity': FieldValue.increment(totalItems),
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
  Future<void> createKiosk(Kiosk kiosk) async {
    try {
      // Use the provided ID as the document ID for consistency with hardware
      await _firestore.collection('kiosks').doc(kiosk.id).set(kiosk.toFirestore());
    } catch (e) {
      AppLogger.error('Failed to create kiosk: $e');
      rethrow;
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

  /// Reset kiosk capacity (admin)
  Future<bool> emptyKiosk(String kioskId) async {
    try {
      final docRef = _firestore.collection('kiosks').doc(kioskId);
      final doc = await docRef.get();
      
      final Map<String, dynamic> updates = {
        'currentCapacity': 0,
        'plasticCount': 0, // Reset these too for a full empty
        'metalCount': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // If it was full, make it available again
        if (data['status'] == 'full') {
          updates['status'] = 'available';
        }
        await docRef.update(updates);
      } else {
        // If it was a mock machine NOT in Firestore, register it now
        // so that it becomes reactive.
        await docRef.set({
          'name': kioskId.replaceAll('_', ' ').toUpperCase(),
          'address': 'Mock Machine',
          'latitude': 30.0,
          'longitude': 31.0,
          'status': 'available',
          'maxCapacity': 100,
          ...updates,
        });
      }

      AppLogger.info('Kiosk $kioskId emptied and reset.');
      return true;
    } catch (e) {
      AppLogger.error('Failed to empty kiosk: $e');
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
      Kiosk(
        id: '',
        name: 'Cairo Festival City Kiosk',
        address: 'Cairo Festival City Mall, New Cairo',
        latitude: 30.0282,
        longitude: 31.4072,
        status: 'available',
        openingHours: '10:00 AM - 11:00 PM',
      ),
    ];

    for (final kiosk in kiosks) {
      await createKiosk(kiosk);
    }
    AppLogger.info('Seeded ${kiosks.length} kiosks');
  }

  /// Get kiosks that need admin attention (non-available status)
  Stream<List<Kiosk>> getAlertKiosksStream() {
    return _firestore
        .collection('kiosks')
        .where('status', whereNotIn: ['available'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Kiosk.fromFirestore(doc)).toList());
  }

  /// Notify all admin users when a kiosk status changes to a problem state
  Future<void> notifyAdminsOnStatusChange(String kioskId, String kioskName, String newStatus) async {
    if (newStatus == 'available') return; // Only notify for problem states

    try {
      // Find all admin users
      final adminSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final adminDoc in adminSnapshot.docs) {
        final notifRef = adminDoc.reference.collection('notifications').doc();
        batch.set(notifRef, {
          'type': 'kiosk_alert',
          'title': 'Kiosk Alert: $kioskName',
          'message': 'Kiosk "$kioskName" is now ${_statusLabel(newStatus)}.',
          'kioskId': kioskId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      await batch.commit();
      AppLogger.info('Admin notification sent for kiosk: $kioskName ($newStatus)');
    } catch (e) {
      AppLogger.error('Failed to notify admins: $e');
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'offline': return 'Offline';
      case 'full': return 'Full';
      case 'maintenance': return 'Under Maintenance';
      case 'out_of_service': return 'Out of Service';
      default: return status;
    }
  }
}
