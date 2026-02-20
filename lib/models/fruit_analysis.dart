/// Data Model for Fruit Analysis Results
/// Contains comprehensive data about scanned fruit quality
class FruitAnalysis {

  FruitAnalysis({
    required this.id,
    required this.type,
    required this.brix, required this.waterContent, required this.freshness, required this.hasResidue, required this.bestBefore, required this.daysUntilExpiry, required this.qualityScore, this.scientificName = '',
    this.variety = '',
    this.residueStatus = 'Safe',
    this.grade = 'A',
    this.origin = '',
    this.storageTips = const [],
    this.aiRecipes = const [],
    DateTime? scannedAt,
    this.scannedBy,
    this.location,
  }) : scannedAt = scannedAt ?? DateTime.now();

  /// Factory constructor for mock data
  factory FruitAnalysis.mock() {
    return FruitAnalysis(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      type: 'Apple',
      scientificName: 'Malus Domestica',
      variety: 'Red Delicious',
      brix: 14.2,
      waterContent: 88,
      freshness: 95,
      hasResidue: false,
      bestBefore: '5 Days',
      daysUntilExpiry: 5,
      grade: 'Premium',
      origin: 'Washington State, USA',
      qualityScore: 98,
      storageTips: [
        'Store at 0-4°C for optimal freshness',
        'Keep away from ethylene-producing fruits',
        'Wash before consumption',
      ],
      aiRecipes: [
        AIRecipe(
          name: 'Fresh Apple Salad',
          description: 'A refreshing salad with mixed greens and apple slices',
          difficulty: 'Easy',
          prepTime: '15 mins',
        ),
        AIRecipe(
          name: 'Baked Apple Chips',
          description: 'Crispy homemade apple chips with cinnamon',
          difficulty: 'Medium',
          prepTime: '45 mins',
        ),
      ],
      scannedBy: 'Alex Chen',
      location: 'Whole Foods, Downtown',
    );
  }

  /// Factory constructor for mango mock data
  factory FruitAnalysis.mockMango() {
    return FruitAnalysis(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      type: 'Mango',
      scientificName: 'Mangifera Indica',
      variety: 'Alphonso Gold',
      brix: 18,
      waterContent: 83,
      freshness: 92,
      hasResidue: false,
      residueStatus: 'Clean',
      bestBefore: '7 Days',
      daysUntilExpiry: 7,
      origin: 'Maharashtra, India',
      qualityScore: 96,
      storageTips: [
        'Ripen at room temperature',
        'Refrigerate once ripe',
        'Consume within 3-4 days of ripening',
      ],
      aiRecipes: [
        AIRecipe(
          name: 'Mango Lassi',
          description: 'Traditional Indian yogurt drink with fresh mango',
          difficulty: 'Easy',
          prepTime: '10 mins',
        ),
        AIRecipe(
          name: 'Mango Sticky Rice',
          description: 'Thai dessert with coconut milk',
          difficulty: 'Medium',
          prepTime: '30 mins',
        ),
      ],
      scannedBy: 'Sarah J.',
      location: 'Fresh Farms Market',
    );
  }
  final String id;
  final String type;
  final String scientificName;
  final String variety;
  final double brix;
  final double waterContent;
  final double freshness;
  final bool hasResidue;
  final String residueStatus;
  final String bestBefore;
  final int daysUntilExpiry;
  final String grade;
  final String origin;
  final double qualityScore;
  final List<String> storageTips;
  final List<AIRecipe> aiRecipes;
  final DateTime scannedAt;
  final String? scannedBy;
  final String? location;

  FruitAnalysis copyWith({
    String? id,
    String? type,
    String? scientificName,
    String? variety,
    double? brix,
    double? waterContent,
    double? freshness,
    bool? hasResidue,
    String? residueStatus,
    String? bestBefore,
    int? daysUntilExpiry,
    String? grade,
    String? origin,
    double? qualityScore,
    List<String>? storageTips,
    List<AIRecipe>? aiRecipes,
    DateTime? scannedAt,
    String? scannedBy,
    String? location,
  }) {
    return FruitAnalysis(
      id: id ?? this.id,
      type: type ?? this.type,
      scientificName: scientificName ?? this.scientificName,
      variety: variety ?? this.variety,
      brix: brix ?? this.brix,
      waterContent: waterContent ?? this.waterContent,
      freshness: freshness ?? this.freshness,
      hasResidue: hasResidue ?? this.hasResidue,
      residueStatus: residueStatus ?? this.residueStatus,
      bestBefore: bestBefore ?? this.bestBefore,
      daysUntilExpiry: daysUntilExpiry ?? this.daysUntilExpiry,
      grade: grade ?? this.grade,
      origin: origin ?? this.origin,
      qualityScore: qualityScore ?? this.qualityScore,
      storageTips: storageTips ?? this.storageTips,
      aiRecipes: aiRecipes ?? this.aiRecipes,
      scannedAt: scannedAt ?? this.scannedAt,
      scannedBy: scannedBy ?? this.scannedBy,
      location: location ?? this.location,
    );
  }
}

/// AI Recipe Model
class AIRecipe {

  AIRecipe({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.prepTime,
  });
  final String name;
  final String description;
  final String difficulty;
  final String prepTime;
}

/// User Rating Model for Social Features
class UserRating {

  UserRating({
    required this.userId,
    required this.userName,
    required this.rating, this.userAvatar,
    this.comment,
    this.location,
    DateTime? ratedAt,
  }) : ratedAt = ratedAt ?? DateTime.now();
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating; // 1-5 stars
  final String? comment;
  final String? location;
  final DateTime ratedAt;
}
