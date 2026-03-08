
class HomeCard {
  final String id;
  final String type; // 'analytics' or 'promo'
  final String? title;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int priority;
  final String? actionType; // 'none', 'offer', 'url'
  final String? actionValue; // Offer ID or URL string

  HomeCard({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.priority,
    this.actionType,
    this.actionValue,
  });

  factory HomeCard.fromMap(Map<String, dynamic> map, String id) {
    return HomeCard(
      id: id,
      type: map['type'] ?? 'promo',
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      priority: map['priority'] ?? 0,
      actionType: map['actionType'],
      actionValue: map['actionValue'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'priority': priority,
      'actionType': actionType,
      'actionValue': actionValue,
    };
  }
}
