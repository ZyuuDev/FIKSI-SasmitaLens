/// Vendor Rating Model for Leaderboard System
/// Represents a vendor/store with their quality metrics and points
class VendorRating {

  VendorRating({
    required this.id,
    required this.name,
    this.logoUrl,
    this.avatarUrl,
    required this.totalScans,
    required this.averageRating,
    required this.freshnessConsistency,
    required this.totalPoints,
    required this.rank,
    this.category = 'General',
    DateTime? lastActive,
    this.isVerified = true,
    this.topProducts = const [],
  }) : lastActive = lastActive ?? DateTime.now();
  final String id;
  final String name;
  final String? logoUrl;
  final String? avatarUrl;
  final int totalScans;
  final double averageRating;
  final double freshnessConsistency;
  final int totalPoints;
  final int rank;
  final String category;
  final DateTime lastActive;
  final bool isVerified;
  final List<String> topProducts;

  /// Calculate vendor points based on:
  /// - Total Scans * 2
  /// - Average Rating * 10
  /// - Freshness Consistency Bonus
  static int calculatePoints({
    required int totalScans,
    required double averageRating,
    required double freshnessConsistency,
  }) {
    final scanPoints = totalScans * 2;
    final ratingPoints = (averageRating * 10).round();
    final consistencyBonus = (freshnessConsistency * 5).round();
    
    return scanPoints + ratingPoints + consistencyBonus;
  }

  /// Create a copy with updated points
  VendorRating copyWithCalculatedPoints() {
    final newPoints = calculatePoints(
      totalScans: totalScans,
      averageRating: averageRating,
      freshnessConsistency: freshnessConsistency,
    );
    
    return copyWith(totalPoints: newPoints);
  }

  VendorRating copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? avatarUrl,
    int? totalScans,
    double? averageRating,
    double? freshnessConsistency,
    int? totalPoints,
    int? rank,
    String? category,
    DateTime? lastActive,
    bool? isVerified,
    List<String>? topProducts,
  }) {
    return VendorRating(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalScans: totalScans ?? this.totalScans,
      averageRating: averageRating ?? this.averageRating,
      freshnessConsistency: freshnessConsistency ?? this.freshnessConsistency,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
      category: category ?? this.category,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      topProducts: topProducts ?? this.topProducts,
    );
  }
}

/// Extension methods for VendorRating list operations
extension VendorRatingListExtension on List<VendorRating> {
  /// Sort vendors by total points in descending order
  List<VendorRating> sortedByPoints() {
    final sorted = List<VendorRating>.from(this);
    sorted.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return sorted;
  }

  /// Update ranks based on sorted order
  List<VendorRating> withUpdatedRanks() {
    final sorted = sortedByPoints();
    return sorted.asMap().entries.map((entry) {
      return entry.value.copyWith(rank: entry.key + 1);
    }).toList();
  }

  /// Get top N vendors
  List<VendorRating> top(int n) {
    final sorted = withUpdatedRanks();
    return sorted.take(n).toList();
  }
}

/// Mock vendor data for leaderboard
class MockVendors {
  static List<VendorRating> getVendors() {
    final vendors = [
      VendorRating(
        id: 'vnd_001',
        name: 'Green Grocer',
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
        totalScans: 450,
        averageRating: 4.8,
        freshnessConsistency: 0.95,
        totalPoints: 0,
        rank: 1,
        category: 'Organic',
        topProducts: ['Apples', 'Mangoes', 'Leafy Greens'],
      ),
      VendorRating(
        id: 'vnd_002',
        name: 'Fresh Farms',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        totalScans: 380,
        averageRating: 4.6,
        freshnessConsistency: 0.92,
        totalPoints: 0,
        rank: 2,
        category: 'Farm Direct',
        topProducts: ['Tomatoes', 'Cucumbers', 'Peppers'],
      ),
      VendorRating(
        id: 'vnd_003',
        name: 'City Market',
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
        totalScans: 320,
        averageRating: 4.4,
        freshnessConsistency: 0.88,
        totalPoints: 0,
        rank: 3,
        category: 'Supermarket',
        topProducts: ['Bananas', 'Oranges', 'Grapes'],
      ),
      VendorRating(
        id: 'vnd_004',
        name: 'Whole Foods',
        avatarUrl: 'https://i.pravatar.cc/150?img=8',
        totalScans: 290,
        averageRating: 4.5,
        freshnessConsistency: 0.90,
        totalPoints: 0,
        rank: 4,
        category: 'Premium',
        topProducts: ['Berries', 'Avocados', 'Exotic Fruits'],
      ),
      VendorRating(
        id: 'vnd_005',
        name: "Trader Joe's",
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        totalScans: 250,
        averageRating: 4.3,
        freshnessConsistency: 0.87,
        totalPoints: 0,
        rank: 5,
        category: 'Discount',
        topProducts: ['Seasonal Fruits', 'Nuts', 'Dried Fruits'],
      ),
    ];

    // Calculate points and update ranks
    return vendors
        .map((v) => v.copyWithCalculatedPoints())
        .toList()
        .withUpdatedRanks();
  }
}
