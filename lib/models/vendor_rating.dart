/// Vendor Rating Model for Leaderboard System
/// Represents a vendor/store with their quality metrics and points
class VendorRating {
  VendorRating({
    required this.id,
    required this.name,
    required this.totalScans,
    required this.averageRating,
    required this.freshnessConsistency,
    required this.totalPoints,
    required this.rank,
    this.logoUrl,
    this.avatarUrl,
    this.category = 'Umum',
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

/// Mock vendor data untuk leaderboard (Konteks Indonesia / SMK N 1 Bantul)
class MockVendors {
  static List<VendorRating> getVendors() {
    final vendors = [
      VendorRating(
        id: 'vnd_001',
        name: 'Koperasi Agro Bantul',
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
        totalScans: 480,
        averageRating: 4.8,
        freshnessConsistency: 0.96,
        totalPoints: 0,
        rank: 1,
        category: 'Mitra Tani',
        topProducts: ['Mangga Harum Manis', 'Melon Sky Rocket', 'Cabai Rawit'],
      ),
      VendorRating(
        id: 'vnd_002',
        name: 'Kelompok Tani Makmur',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        totalScans: 390,
        averageRating: 4.6,
        freshnessConsistency: 0.92,
        totalPoints: 0,
        rank: 2,
        category: 'Petani Lokal',
        topProducts: ['Semangka Tanpa Biji', 'Melon Honey Globe', 'Tomat Kurma'],
      ),
      VendorRating(
        id: 'vnd_003',
        name: 'Lapak Buah Bu Sri',
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
        totalScans: 330,
        averageRating: 4.4,
        freshnessConsistency: 0.88,
        totalPoints: 0,
        rank: 3,
        category: 'Pedagang',
        topProducts: ['Mangga Gadung', 'Jeruk Pacitan', 'Salak Pondoh'],
      ),
      VendorRating(
        id: 'vnd_004',
        name: 'Petani Milenial Sanden',
        avatarUrl: 'https://i.pravatar.cc/150?img=8',
        totalScans: 300,
        averageRating: 4.5,
        freshnessConsistency: 0.90,
        totalPoints: 0,
        rank: 4,
        category: 'Petani Lokal',
        topProducts: ['Bawang Merah', 'Semangka Kuning', 'Melon Kirani'],
      ),
      VendorRating(
        id: 'vnd_005',
        name: 'Toko Buah Berkah Abadi',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        totalScans: 260,
        averageRating: 4.3,
        freshnessConsistency: 0.87,
        totalPoints: 0,
        rank: 5,
        category: 'Pedagang',
        topProducts: ['Mangga Manalagi', 'Apel Malang', 'Pisang Mas'],
      ),
    ];

    // Calculate points and update ranks
    return vendors
        .map((v) => v.copyWithCalculatedPoints())
        .toList()
        .withUpdatedRanks();
  }
}
