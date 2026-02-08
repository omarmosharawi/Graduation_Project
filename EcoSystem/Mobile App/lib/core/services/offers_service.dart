// =============================================================================
// OFFERS SERVICE - Manage Offers from Firestore
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Offer model
class Offer {
  final String id;
  final String title;
  final String description;
  final String partner;
  final String category;
  final int pointsRequired;
  final String? imageUrl;
  final bool isActive;
  final DateTime? expiresAt;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.partner,
    required this.category,
    required this.pointsRequired,
    this.imageUrl,
    this.isActive = true,
    this.expiresAt,
  });

  factory Offer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Offer(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      partner: data['partner'] ?? '',
      category: data['category'] ?? 'General',
      pointsRequired: data['pointsRequired'] ?? 0,
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'partner': partner,
      'category': category,
      'pointsRequired': pointsRequired,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }
}

/// Offers Service for CRUD operations
class OffersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active offers stream
  Stream<List<Offer>> getOffersStream() {
    return _firestore
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .orderBy('pointsRequired')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Offer.fromFirestore(doc)).toList());
  }

  /// Get offers by category
  Stream<List<Offer>> getOffersByCategory(String category) {
    return _firestore
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Offer.fromFirestore(doc)).toList());
  }

  /// Get single offer
  Future<Offer?> getOffer(String offerId) async {
    try {
      final doc = await _firestore.collection('offers').doc(offerId).get();
      if (doc.exists) {
        return Offer.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get offer: $e');
      return null;
    }
  }

  // ===========================================================================
  // ADMIN METHODS
  // ===========================================================================

  /// Create new offer (admin only)
  Future<String?> createOffer(Offer offer) async {
    try {
      final doc = await _firestore.collection('offers').add(offer.toFirestore());
      return doc.id;
    } catch (e) {
      AppLogger.error('Failed to create offer: $e');
      return null;
    }
  }

  /// Update offer (admin only)
  Future<bool> updateOffer(String offerId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('offers').doc(offerId).update(updates);
      return true;
    } catch (e) {
      AppLogger.error('Failed to update offer: $e');
      return false;
    }
  }

  /// Delete offer (admin only)
  Future<bool> deleteOffer(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).delete();
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete offer: $e');
      return false;
    }
  }

  /// Get all offers for admin (including inactive)
  Stream<List<Offer>> getAllOffersForAdmin() {
    return _firestore
        .collection('offers')
        .orderBy('pointsRequired')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Offer.fromFirestore(doc)).toList());
  }

  /// Get offer categories
  List<String> getCategories() {
    return [
      'Groceries',
      'Beauty',
      'Restaurants',
      'Entertainment',
      'Shopping',
      'Health',
    ];
  }
}
