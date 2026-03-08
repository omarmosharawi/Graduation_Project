import 'package:cloud_firestore/cloud_firestore.dart';

enum PickupStatus {
  pending,
  confirmed,
  onWay,
  completed,
  cancelled,
}

class PickupItem {
  final String materialType;
  final int quantity;

  PickupItem({required this.materialType, required this.quantity});

  factory PickupItem.fromMap(Map<String, dynamic> map) {
    return PickupItem(
      materialType: map['materialType'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialType': materialType,
      'quantity': quantity,
    };
  }
}

class PickupRequest {
  final String id;
  final String userId;
  final String userName;
  final String address;
  final GeoPoint? location;
  final DateTime scheduledTime;
  final PickupStatus status;
  final String? eta;
  final DateTime createdAt;
  final List<PickupItem> items;

  PickupRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.address,
    this.location,
    required this.scheduledTime,
    this.status = PickupStatus.pending,
    this.eta,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory PickupRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PickupRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] as GeoPoint?,
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      status: PickupStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => PickupStatus.pending,
      ),
      eta: data['eta'],
      items: (data['items'] as List? ?? [])
          .map((i) => PickupItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'address': address,
      'location': location,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'status': status.toString().split('.').last,
      'eta': eta,
      'items': items.map((i) => i.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PickupRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? address,
    GeoPoint? location,
    DateTime? scheduledTime,
    PickupStatus? status,
    String? eta,
    DateTime? createdAt,
    List<PickupItem>? items,
  }) {
    return PickupRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      address: address ?? this.address,
      location: location ?? this.location,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      eta: eta ?? this.eta,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
