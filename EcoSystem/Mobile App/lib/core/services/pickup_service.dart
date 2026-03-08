import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pickup_request_model.dart';
import '../utils/logger.dart';

class PickupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'pickup_requests';

  /// Create a new pickup request
  Future<String?> createRequest(PickupRequest request) async {
    try {
      final docRef = await _firestore.collection(_collection).add(request.toFirestore());
      AppLogger.info('Pickup request created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create pickup request: $e');
      return null;
    }
  }

  /// Get stream of requests for a specific user
  Stream<List<PickupRequest>> getRequestsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PickupRequest.fromFirestore(doc)).toList();
    });
  }

  /// Get stream of all requests (for Admin)
  Stream<List<PickupRequest>> getAllRequestsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PickupRequest.fromFirestore(doc)).toList();
    });
  }

  /// Update request status and optionally set ETA
  Future<bool> updateRequestStatus(String requestId, PickupStatus status, {String? eta}) async {
    try {
      final Map<String, dynamic> updates = {
        'status': status.toString().split('.').last,
      };
      if (eta != null) updates['eta'] = eta;

      if (status == PickupStatus.completed) {
        // Fetch request details to get items and userId
        final doc = await _firestore.collection(_collection).doc(requestId).get();
        if (doc.exists) {
          final request = PickupRequest.fromFirestore(doc);
          
          final batch = _firestore.batch();
          
          // Calculate points (10 points per item)
          int pointsToAdd = 0;
          int plasticCount = 0;
          int metalCount = 0;
          int totalItems = 0;

          for (final item in request.items) {
            pointsToAdd += item.quantity * 10;
            totalItems += item.quantity;
            if (item.materialType == 'Plastic') {
              plasticCount += item.quantity;
            } else if (item.materialType == 'Metal') {
              metalCount += item.quantity;
            }
          }

          // 1. Update user points and counts
          final userRef = _firestore.collection('users').doc(request.userId);
          batch.update(userRef, {
            'currentPoints': FieldValue.increment(pointsToAdd),
            'totalPoints': FieldValue.increment(pointsToAdd),
            'recycledCount': FieldValue.increment(totalItems),
            'pickupCount': FieldValue.increment(totalItems),
            'totalPlastic': FieldValue.increment(plasticCount),
            'totalMetal': FieldValue.increment(metalCount),
          });

          // 2. Create transaction record
          final transactionRef = _firestore.collection('transactions').doc();
          batch.set(transactionRef, {
            'type': 'pickup',
            'requestId': requestId,
            'userId': request.userId,
            'points': pointsToAdd,
            'plasticCount': plasticCount,
            'metalCount': metalCount,
            'totalItems': totalItems,
            'timestamp': FieldValue.serverTimestamp(),
          });

          // 3. Add notification for user
          final notificationRef = userRef.collection('notifications').doc();
          batch.set(notificationRef, {
            'type': 'pickup_completed',
            'title': 'Pickup Completed!',
            'message': 'Your pickup was completed. You earned $pointsToAdd points for recycling $totalItems items.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

          await batch.commit();
          AppLogger.info('Pickup $requestId completed, points awarded: $pointsToAdd');
        }
      }

      await _firestore.collection(_collection).doc(requestId).update(updates);
      AppLogger.info('Pickup request $requestId updated to $status');
      return true;
    } catch (e) {
      AppLogger.error('Failed to update pickup request: $e');
      return false;
    }
  }

  /// Cancel a pickup request
  Future<bool> cancelRequest(String requestId) async {
    return updateRequestStatus(requestId, PickupStatus.cancelled);
  }
}
