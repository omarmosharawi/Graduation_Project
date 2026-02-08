import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_card_model.dart';
import '../models/global_stats_model.dart';

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _cardsCollection => _firestore.collection('home_cards');
  DocumentReference get _globalStatsDoc => _firestore.collection('statistics').doc('global');

  // Stream of active home cards
  Stream<List<HomeCard>> getHomeCardsStream() {
    return _cardsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HomeCard.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Stream of global stats
  Stream<GlobalStats> getGlobalStatsStream() {
    return _globalStatsDoc.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return GlobalStats(totalBottles: 0, totalCans: 0, totalWeightKg: 0);
      }
      return GlobalStats.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // Admin: Add a new card
  Future<void> addHomeCard(HomeCard card) async {
    await _cardsCollection.add(card.toMap());
  }

  // Admin: Update a card
  Future<void> updateHomeCard(HomeCard card) async {
    await _cardsCollection.doc(card.id).update(card.toMap());
  }

  // Admin: Delete a card
  Future<void> deleteHomeCard(String id) async {
    await _cardsCollection.doc(id).delete();
  }

  // Admin/System: Update global stats
  Future<void> updateGlobalStats(GlobalStats stats) async {
    await _globalStatsDoc.set(stats.toMap(), SetOptions(merge: true));
  }
}
