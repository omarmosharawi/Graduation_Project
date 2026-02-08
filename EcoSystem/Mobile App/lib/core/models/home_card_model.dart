
class HomeCard {
  final String id;
  final String type; // 'analytics' or 'promo'
  final String title;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int priority;

  HomeCard({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.priority,
  });

  factory HomeCard.fromMap(Map<String, dynamic> map, String id) {
    return HomeCard(
      id: id,
      type: map['type'] ?? 'promo',
      title: map['title'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      priority: map['priority'] ?? 0,
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
    };
  }
}
