
class GlobalStats {
  final int totalBottles;
  final int totalCans;
  final double totalWeightKg;

  GlobalStats({
    required this.totalBottles,
    required this.totalCans,
    required this.totalWeightKg,
  });

  factory GlobalStats.fromMap(Map<String, dynamic> map) {
    return GlobalStats(
      totalBottles: map['totalBottles'] ?? 0,
      totalCans: map['totalCans'] ?? 0,
      totalWeightKg: (map['totalWeightKg'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBottles': totalBottles,
      'totalCans': totalCans,
      'totalWeightKg': totalWeightKg,
    };
  }
}
