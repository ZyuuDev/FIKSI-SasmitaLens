import 'package:intl/intl.dart';

/// Scan Feed Model for Social Features
/// Represents a single scan entry in the real-time feed
class ScanFeed {
  ScanFeed({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.productName,
    required this.productGrade,
    required this.rating,
    required this.timestamp,
    this.userAvatar,
    this.productImage,
    this.qualityScore,
    this.size,
    this.likes = 0,
    this.comments = 0,
    this.location,
    this.isVerified = false,
    this.isFlagged = false,
    this.flagReason,
  });

  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String action; // 'scanned', 'flagged', 'verified'
  final String productName;
  final String productGrade;
  final String? productImage;
  final double? qualityScore;
  final String? size;
  final int rating;
  final int likes;
  final int comments;
  final String? location;
  final DateTime timestamp;
  final bool isVerified;
  final bool isFlagged;
  final String? flagReason;

  /// Get formatted timestamp like "5m ago", "2h ago", "1d ago" (Indonesian)
  String get formattedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM').format(timestamp);
    }
  }

  /// Get full formatted date
  String get formattedDate {
    return DateFormat('dd MMM yyyy • HH:mm').format(timestamp);
  }

  /// Get action text with proper formatting (Indonesian)
  String get actionText {
    switch (action) {
      case 'scanned':
        return 'memindai';
      case 'flagged':
        return 'melaporkan';
      case 'verified':
        return 'memverifikasi';
      default:
        return action;
    }
  }

  /// Get grade color based on product grade
  String get gradeColor {
    switch (productGrade.toUpperCase()) {
      case 'A':
      case 'A+':
      case 'PREMIUM':
        return '#00E676';
      case 'B':
      case 'B+':
      case 'STANDARD':
        return '#FFC107';
      case 'C':
      case 'LOW':
        return '#FF5722';
      default:
        return '#00E676';
    }
  }

  ScanFeed copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? action,
    String? productName,
    String? productGrade,
    String? productImage,
    double? qualityScore,
    String? size,
    int? rating,
    int? likes,
    int? comments,
    String? location,
    DateTime? timestamp,
    bool? isVerified,
    bool? isFlagged,
    String? flagReason,
  }) {
    return ScanFeed(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      action: action ?? this.action,
      productName: productName ?? this.productName,
      productGrade: productGrade ?? this.productGrade,
      productImage: productImage ?? this.productImage,
      qualityScore: qualityScore ?? this.qualityScore,
      size: size ?? this.size,
      rating: rating ?? this.rating,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      isVerified: isVerified ?? this.isVerified,
      isFlagged: isFlagged ?? this.isFlagged,
      flagReason: flagReason ?? this.flagReason,
    );
  }
}

/// Mock scan feed data (Konteks Indonesia / Bantul)
class MockScanFeed {
  static List<ScanFeed> getFeeds() {
    final now = DateTime.now();
    
    return [
      ScanFeed(
        id: 'feed_001',
        userId: 'usr_001',
        userName: 'Siti Aminah',
        userAvatar: 'https://i.pravatar.cc/150?img=1',
        action: 'scanned',
        productName: 'Mangga Harum Manis Super',
        productGrade: 'A+',
        productImage: 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=400',
        qualityScore: 98,
        size: 'Besar',
        rating: 5,
        likes: 24,
        comments: 8,
        location: 'Pasar Bantul',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isVerified: true,
      ),
      ScanFeed(
        id: 'feed_002',
        userId: 'usr_002',
        userName: 'Bambang S.',
        userAvatar: 'https://i.pravatar.cc/150?img=2',
        action: 'scanned',
        productName: 'Melon Madu Lunak',
        productGrade: 'B',
        productImage: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400',
        qualityScore: 65,
        rating: 3,
        likes: 5,
        comments: 2,
        location: 'Koperasi Tani Makmur',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ScanFeed(
        id: 'feed_003',
        userId: 'usr_003',
        userName: 'Rian Ardianto',
        userAvatar: 'https://i.pravatar.cc/150?img=4',
        action: 'verified',
        productName: 'Semangka Tanpa Biji',
        productGrade: 'A',
        productImage: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400',
        qualityScore: 92,
        rating: 4,
        likes: 15,
        comments: 3,
        location: 'Toko Buah Berkah',
        timestamp: now.subtract(const Duration(hours: 3)),
        isVerified: true,
      ),
      ScanFeed(
        id: 'feed_004',
        userId: 'usr_004',
        userName: 'Dewi Lestari',
        userAvatar: 'https://i.pravatar.cc/150?img=6',
        action: 'scanned',
        productName: 'Alpukat Mentega Segar',
        productGrade: 'A+',
        productImage: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400',
        qualityScore: 94,
        size: 'Sedang',
        rating: 5,
        likes: 32,
        comments: 6,
        location: 'Koperasi Agro Bantul',
        timestamp: now.subtract(const Duration(hours: 4)),
        isVerified: true,
      ),
      ScanFeed(
        id: 'feed_005',
        userId: 'usr_005',
        userName: 'Joko Prasetyo',
        userAvatar: 'https://i.pravatar.cc/150?img=9',
        action: 'scanned',
        productName: 'Apel Malang Segar',
        productGrade: 'B',
        productImage: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400',
        qualityScore: 75,
        size: 'Kecil',
        rating: 3,
        likes: 8,
        comments: 2,
        location: 'Lapak Sayur Dusun Sanden',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      ScanFeed(
        id: 'feed_006',
        userId: 'usr_006',
        userName: 'Ahmad Fauzi',
        userAvatar: 'https://i.pravatar.cc/150?img=10',
        action: 'verified',
        productName: 'Pisang Raja Organik',
        productGrade: 'A',
        productImage: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400',
        qualityScore: 96,
        rating: 5,
        likes: 45,
        comments: 10,
        location: 'Kelompok Tani Sanden',
        timestamp: now.subtract(const Duration(hours: 6)),
        isVerified: true,
      ),
    ];
  }

  /// Get filtered feeds by category
  static List<ScanFeed> getFeedsByCategory(String category) {
    final allFeeds = getFeeds();
    
    switch (category.toLowerCase()) {
      case 'mangga':
      case 'mangoes':
        return allFeeds.where((f) => 
          f.productName.toLowerCase().contains('mangga') ||
          f.productName.toLowerCase().contains('mango'),
        ).toList();
      case 'melon':
        return allFeeds.where((f) => 
          f.productName.toLowerCase().contains('melon'),
        ).toList();
      case 'verified':
      case 'terverifikasi':
        return allFeeds.where((f) => f.isVerified).toList();
      default:
        return allFeeds;
    }
  }
}
